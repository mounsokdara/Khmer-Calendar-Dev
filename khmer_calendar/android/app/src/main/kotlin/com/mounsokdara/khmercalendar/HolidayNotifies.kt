package com.mounsokdara.khmercalendar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONArray
import org.json.JSONObject

private const val RELIGIOUS_BLUE = 0xFF1E88E5.toInt()

/** Holidays listed by Flutter from holidaysOfYear / observances — not a hardcoded subset. */
private fun listedHolidays(context: Context, listKey: String): List<Pair<String, JSONObject>> {
    val raw = WidgetStore.prefs(context).getString(listKey, "[]") ?: return emptyList()
    return try {
        val arr = JSONArray(raw)
        val out = ArrayList<Pair<String, JSONObject>>(arr.length())
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            val iso = o.optString("d")
            if (iso.length >= 10) out.add(iso to o)
        }
        out
    } catch (_: Exception) {
        emptyList()
    }
}

private fun itemsOn(context: Context, listKey: String, iso: String): List<JSONObject> {
    return listedHolidays(context, listKey).mapNotNull { if (it.first == iso) it.second else null }
}

private fun namesFor(items: List<JSONObject>, km: Boolean): List<String> {
    val out = ArrayList<String>()
    val seen = HashSet<String>()
    for (item in items) {
        val name = if (km) item.optString("km") else item.optString("en")
        if (name.isNotEmpty() && seen.add(name)) out.add(name)
    }
    return out
}

private fun armListed(context: Context, listKey: String, cls: Class<*>, baseReq: Int, extraBases: IntArray = intArrayOf()) {
    val isos = listedHolidays(context, listKey).map { it.first }
    NotifyKit.scheduleIsoAlarms(context, isos, cls, baseReq, 8, "${listKey}_alarm_n", extraBases)
}

private fun cancelListed(context: Context, listKey: String, cls: Class<*>, baseReq: Int, extraBases: IntArray = intArrayOf()) {
    NotifyKit.cancelIsoAlarms(context, cls, baseReq, "${listKey}_alarm_n", extraBases)
}

object PublicHolidayNotify {
    const val LIST = "public_hols"

    fun arm(context: Context, showNow: Boolean) {
        if (!WidgetStore.publicOn(context)) {
            cancel(context)
            return
        }
        schedule(context)
        if (showNow) show(context)
    }

    fun schedule(context: Context) {
        if (!WidgetStore.publicOn(context)) {
            cancel(context)
            return
        }
        NotifyKit.ensureChannels(context)
        armListed(context, LIST, PublicHolidayReceiver::class.java, NotifyKit.PUBLIC_REQ)
    }

    fun cancel(context: Context) {
        cancelListed(context, LIST, PublicHolidayReceiver::class.java, NotifyKit.PUBLIC_REQ)
        NotifyKit.cancelNote(context, NotifyKit.PUBLIC_ID)
    }

    fun show(context: Context, iso: String = WidgetStore.todayIso()) {
        if (!WidgetStore.publicOn(context)) return
        val items = itemsOn(context, LIST, iso)
        if (items.isEmpty()) return
        val km = WidgetStore.lang(context) != "en"
        val names = namesFor(items, km)
        val kind = if (km) "ថ្ងៃឈប់សម្រាកសាធារណៈ" else "Public holiday"
        val title = names.firstOrNull()?.ifEmpty { kind } ?: kind
        val extra = names.drop(1)
        val body =
            (extra + kind + WidgetStore.dayDetail(context, iso))
                .filter { it.isNotEmpty() }
                .joinToString("\n")
        NotifyKit.post(context, NotifyKit.PUBLIC_ID, NotifyKit.CHANNEL_PUBLIC, title, body, "day", iso)
    }
}

class PublicHolidayReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!WidgetStore.publicOn(context)) {
            PublicHolidayNotify.cancel(context)
            return
        }
        PublicHolidayNotify.show(context, intent.getStringExtra("date") ?: WidgetStore.todayIso())
        NotifyKit.sync(context)
    }
}

object ReligiousHolidayNotify {
    const val LIST = "religious_hols"

    fun arm(context: Context, showNow: Boolean) {
        if (!WidgetStore.religiousOn(context)) {
            cancel(context)
            return
        }
        schedule(context)
        if (showNow) show(context)
    }

    fun schedule(context: Context) {
        if (!WidgetStore.religiousOn(context)) {
            cancel(context)
            return
        }
        NotifyKit.ensureChannels(context)
        armListed(
            context,
            LIST,
            ReligiousHolidayReceiver::class.java,
            NotifyKit.RELIGIOUS_REQ,
            intArrayOf(NotifyKit.LEGACY_RELIGIOUS_REQ),
        )
    }

    fun cancel(context: Context) {
        cancelListed(
            context,
            LIST,
            ReligiousHolidayReceiver::class.java,
            NotifyKit.RELIGIOUS_REQ,
            intArrayOf(NotifyKit.LEGACY_RELIGIOUS_REQ),
        )
        NotifyKit.cancelNote(context, NotifyKit.RELIGIOUS_ID)
    }

    fun show(context: Context, iso: String = WidgetStore.todayIso()) {
        if (!WidgetStore.religiousOn(context)) return
        val items = itemsOn(context, LIST, iso)
        if (items.isEmpty()) return
        val km = WidgetStore.lang(context) != "en"
        val names = namesFor(items, km)
        val kind = if (km) "ថ្ងៃបុណ្យផ្សេងទៀត" else "Other holiday"
        val title = names.firstOrNull()?.ifEmpty { kind } ?: kind
        val extra = names.drop(1)
        val body =
            (extra + kind + WidgetStore.dayDetail(context, iso))
                .filter { it.isNotEmpty() }
                .joinToString("\n")
        NotifyKit.post(
            context,
            NotifyKit.RELIGIOUS_ID,
            NotifyKit.CHANNEL_RELIGIOUS,
            title,
            body,
            "day",
            iso,
            color = RELIGIOUS_BLUE,
        )
    }
}

class ReligiousHolidayReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!WidgetStore.religiousOn(context)) {
            ReligiousHolidayNotify.cancel(context)
            return
        }
        ReligiousHolidayNotify.show(context, intent.getStringExtra("date") ?: WidgetStore.todayIso())
        NotifyKit.sync(context)
    }
}
