package com.mounsokdara.khmercalendar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Reminder on every upcoming សីល day from the Flutter sil_days list. */
object SilNotify {
    private const val COUNT_KEY = "sil_days_alarm_n"

    fun arm(context: Context, showNow: Boolean) {
        if (!WidgetStore.silOn(context)) {
            cancel(context)
            return
        }
        schedule(context)
        if (showNow && WidgetStore.isSilDay(context)) show(context)
    }

    fun schedule(context: Context) {
        if (!WidgetStore.silOn(context)) {
            cancel(context)
            return
        }
        NotifyKit.ensureChannels(context)
        NotifyKit.cancelAlarm(
            context,
            NotifyKit.broadcastPi(context, SilNotifyReceiver::class.java, NotifyKit.SIL_REQ),
        )
        NotifyKit.scheduleIsoAlarms(
            context,
            WidgetStore.silIsoList(context),
            SilNotifyReceiver::class.java,
            NotifyKit.SIL_ALARM_BASE,
            7,
            COUNT_KEY,
        )
    }

    fun cancel(context: Context) {
        NotifyKit.cancelAlarm(
            context,
            NotifyKit.broadcastPi(context, SilNotifyReceiver::class.java, NotifyKit.SIL_REQ),
        )
        NotifyKit.cancelIsoAlarms(context, SilNotifyReceiver::class.java, NotifyKit.SIL_ALARM_BASE, COUNT_KEY)
        NotifyKit.cancelNote(context, NotifyKit.SIL_ID)
    }

    fun show(context: Context, iso: String = WidgetStore.todayIso()) {
        if (!WidgetStore.silOn(context)) return
        if (!WidgetStore.isSilDay(context, iso)) return
        val lang = WidgetStore.lang(context)
        val payload = WidgetStore.dayPayload(context, iso)
        val km = lang != "en"
        val title = if (km) "ថ្ងៃសីល" else "Silas day"
        val moon = payload?.optString("moon").orEmpty()
        val detail = WidgetStore.dayDetail(context, iso)
        val head = if (moon.isNotEmpty()) "$title ($moon)" else title
        val body = listOf(head, detail).filter { it.isNotEmpty() }.joinToString("\n")
        NotifyKit.post(context, NotifyKit.SIL_ID, NotifyKit.CHANNEL_SIL, title, body, "day", iso)
    }
}

class SilNotifyReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!WidgetStore.silOn(context)) {
            SilNotify.cancel(context)
            return
        }
        val iso = intent.getStringExtra("date") ?: WidgetStore.todayIso()
        if (iso == WidgetStore.todayIso()) SilNotify.show(context, iso)
        NotifyKit.sync(context)
    }
}
