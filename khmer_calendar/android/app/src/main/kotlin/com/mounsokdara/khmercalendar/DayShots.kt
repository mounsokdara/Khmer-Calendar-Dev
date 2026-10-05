package com.mounsokdara.khmercalendar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONArray
import kotlin.math.abs

private const val OTHERS_BLUE = 0xFF1E88E5.toInt()

/** One scheduler for every upcoming shot Flutter listed in notify_items. */
object DayShots {
    const val LIST = "notify_items"
    private const val COUNT_KEY = "notify_items_alarm_n"

    data class Item(
        val d: String,
        val h: Int,
        val m: Int,
        val ch: String,
        val title: String,
        val notes: String,
    )

    fun parse(context: Context): List<Item> {
        val raw = WidgetStore.prefs(context).getString(LIST, "[]") ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            val out = ArrayList<Item>(arr.length())
            for (i in 0 until arr.length()) {
                val o = arr.optJSONObject(i) ?: continue
                val d = o.optString("d")
                if (d.length < 10) continue
                val title = o.optString("title")
                if (title.isEmpty()) continue
                out.add(
                    Item(
                        d = d,
                        h = o.optInt("h", 8),
                        m = o.optInt("m", 0),
                        ch = o.optString("ch", "tasks"),
                        title = title,
                        notes = o.optString("notes"),
                    ),
                )
            }
            out
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun schedule(context: Context) {
        cancelAlarms(context)
        if (!WidgetStore.masterNotifyOn(context)) return
        NotifyKit.ensureChannels(context)
        val now = System.currentTimeMillis()
        val seen = HashSet<String>()
        var n = 0
        val items = parse(context).sortedWith(compareBy({ it.d }, { it.h }, { it.m }))
        for (item in items) {
            val stamp = "${item.d}|${item.h}|${item.m}"
            if (!seen.add(stamp)) continue
            val at = NotifyKit.millisAt(item.d, item.h, item.m) ?: continue
            if (at <= now + 30_000) continue
            NotifyKit.setExact(
                context,
                at,
                NotifyKit.shotPi(context, ShotReceiver::class.java, NotifyKit.SHOT_REQ + n, item.d, item.h, item.m),
            )
            n++
        }
        WidgetStore.prefs(context).edit().putInt(COUNT_KEY, n).apply()
    }

    fun cancelAlarms(context: Context) {
        NotifyKit.cancelIsoAlarms(context, ShotReceiver::class.java, NotifyKit.SHOT_REQ, COUNT_KEY)
    }

    fun showAt(context: Context, iso: String, hour: Int, minute: Int) {
        if (!WidgetStore.masterNotifyOn(context)) return
        val items = parse(context).filter { it.d == iso && it.h == hour && it.m == minute }
        if (items.isEmpty()) return
        val km = WidgetStore.lang(context) != "en"
        val detail = WidgetStore.dayDetail(context, iso)
        for ((ch, group) in items.groupBy { it.ch }) {
            val titles = group.map { it.title }.distinct()
            val title = titles.first()
            val kind =
                when (ch) {
                    "sil" -> if (km) "ថ្ងៃសីល" else "Silas day"
                    "public" -> if (km) "ថ្ងៃឈប់សម្រាកសាធារណៈ" else "Public holiday"
                    "others" -> if (km) "ថ្ងៃបុណ្យផ្សេងទៀត" else "Other holiday"
                    else -> if (km) "កិច្ចការ" else "Task"
                }
            val notes = group.map { it.notes }.filter { it.isNotEmpty() }.distinct()
            val body =
                (titles.drop(1) + kind + detail + notes)
                    .filter { it.isNotEmpty() }
                    .joinToString("\n")
            val channel =
                when (ch) {
                    "sil" -> NotifyKit.CHANNEL_SIL
                    "public" -> NotifyKit.CHANNEL_PUBLIC
                    "others" -> NotifyKit.CHANNEL_RELIGIOUS
                    else -> NotifyKit.CHANNEL_TASKS
                }
            val id =
                when (ch) {
                    "sil" -> NotifyKit.SIL_ID
                    "public" -> NotifyKit.PUBLIC_ID
                    "others" -> NotifyKit.RELIGIOUS_ID
                    else -> 8000 + abs(iso.hashCode() xor title.hashCode()) % 1000
                }
            val color = if (ch == "others") OTHERS_BLUE else null
            NotifyKit.post(context, id, channel, title, body, "day", iso, color = color)
        }
    }
}

class ShotReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!WidgetStore.masterNotifyOn(context)) {
            DayShots.cancelAlarms(context)
            return
        }
        val iso = intent.getStringExtra("date") ?: WidgetStore.todayIso()
        val hour = intent.getIntExtra("hour", 8)
        val minute = intent.getIntExtra("minute", 0)
        DayShots.showAt(context, iso, hour, minute)
        DayShots.schedule(context)
    }
}
