package com.mounsokdara.khmercalendar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

class WeatherWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) appWidgetManager.updateAppWidget(id, build(context, id))
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        appWidgetManager.updateAppWidget(appWidgetId, build(context, appWidgetId))
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action ?: return
        if (action == ACTION_SHIFT) {
            val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            val dir = intent.getIntExtra(EXTRA_DIR, 0)
            shift(context, widgetId, dir)
            if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                AppWidgetManager.getInstance(context).updateAppWidget(widgetId, build(context, widgetId))
            } else {
                refreshAll(context)
            }
            return
        }
        if (action == Intent.ACTION_DATE_CHANGED ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_TIME_CHANGED ||
            action == Intent.ACTION_BOOT_COMPLETED ||
            action == AppWidgetManager.ACTION_APPWIDGET_UPDATE
        ) {
            refreshAll(context)
        }
    }

    companion object {
        const val ACTION_SHIFT = "com.mounsokdara.khmercalendar.WEATHER_SHIFT"
        const val EXTRA_DIR = "dir"

        fun refreshAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, WeatherWidgetProvider::class.java))
            for (id in ids) mgr.updateAppWidget(id, build(context, id))
        }

        private fun list(context: Context): JSONArray {
            val raw = WidgetStore.prefs(context).getString("wx_list", null) ?: return JSONArray()
            return try {
                JSONArray(raw)
            } catch (_: Exception) {
                JSONArray()
            }
        }

        private fun shownIndex(context: Context, widgetId: Int, size: Int): Int {
            if (size <= 0) return 0
            val p = WidgetStore.prefs(context)
            val i = p.getInt("wx_i_$widgetId", p.getInt("wx_index", 0))
            return ((i % size) + size) % size
        }

        private fun shift(context: Context, widgetId: Int, dir: Int) {
            if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return
            val n = list(context).length()
            if (n <= 0) return
            val next = shownIndex(context, widgetId, n) + dir
            WidgetStore.prefs(context).edit().putInt("wx_i_$widgetId", ((next % n) + n) % n).apply()
        }

        private fun shiftPi(context: Context, widgetId: Int, dir: Int, req: Int): PendingIntent {
            val intent =
                Intent(context, WeatherWidgetProvider::class.java)
                    .setAction(ACTION_SHIFT)
                    .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                    .putExtra(EXTRA_DIR, dir)
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            return PendingIntent.getBroadcast(context, req + widgetId * 10, intent, flags)
        }

        private fun bmp(path: String?, max: Int): Bitmap? {
            if (path.isNullOrEmpty()) return null
            return try {
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(path, bounds)
                if (bounds.outWidth <= 0) return null
                var sample = 1
                while (bounds.outWidth / sample > max) sample *= 2
                val out = BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
                if (out != null && out.byteCount > 350_000) {
                    out.recycle()
                    null
                } else {
                    out
                }
            } catch (_: Exception) {
                null
            }
        }

        private fun iconRes(code: Int): Int {
            return when {
                code <= 1 -> R.drawable.ic_wx_clear
                code <= 3 -> R.drawable.ic_wx_cloudy
                code <= 48 -> R.drawable.ic_wx_fog
                code <= 86 -> R.drawable.ic_wx_rain
                else -> R.drawable.ic_wx_storm
            }
        }

        private fun size(context: Context, widgetId: Int): Pair<Int, Int> {
            val opts = AppWidgetManager.getInstance(context).getAppWidgetOptions(widgetId)
            val h = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
            val w = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            return w to h
        }

        private fun showHour(context: Context, widgetId: Int): Boolean {
            val (w, h) = size(context, widgetId)
            return h >= 150 || w >= 200
        }

        private fun showWeek(context: Context, widgetId: Int): Boolean {
            val (w, h) = size(context, widgetId)
            return h >= 220 || (w >= 250 && h >= 180)
        }

        private fun weekdayShort(date: String, lang: String): String {
            val p = date.split("-")
            if (p.size < 3) return date
            return try {
                val cal = Calendar.getInstance()
                cal.set(p[0].toInt(), p[1].toInt() - 1, p[2].toInt())
                val i = (cal.get(Calendar.DAY_OF_WEEK) - 1).coerceIn(0, 6)
                if (lang == "en") WidgetStore.WEEK_SHORT_EN[i] else WidgetStore.WEEK_SHORT_KM[i]
            } catch (_: Exception) {
                date
            }
        }

        private fun fillHour(context: Context, views: RemoteViews, item: JSONObject, show: Boolean) {
            views.setViewVisibility(R.id.wx_hour, if (show) View.VISIBLE else View.GONE)
            if (!show) return
            val hours = item.optString("hourly").split(";").filter { it.isNotEmpty() }
            val pkg = context.packageName
            for (i in 0 until 6) {
                val col = context.resources.getIdentifier("wx_hr$i", "id", pkg)
                val time = context.resources.getIdentifier("wx_ht$i", "id", pkg)
                val icon = context.resources.getIdentifier("wx_hi$i", "id", pkg)
                val temp = context.resources.getIdentifier("wx_hv$i", "id", pkg)
                if (i >= hours.size) {
                    views.setViewVisibility(col, View.GONE)
                    continue
                }
                val bits = hours[i].split("|")
                val hh = bits.getOrNull(0) ?: ""
                val t = bits.getOrNull(1) ?: ""
                val code = bits.getOrNull(2)?.toIntOrNull() ?: 2
                views.setViewVisibility(col, View.VISIBLE)
                views.setTextViewText(time, if (hh.isEmpty()) "" else "$hh:00")
                views.setImageViewResource(icon, iconRes(code))
                views.setTextViewText(temp, if (t.isEmpty()) "" else "$t°")
            }
        }

        private fun fillClouds(views: RemoteViews, cover: Int) {
            val show1 = cover >= 18
            val show2 = cover >= 45
            val show3 = cover >= 75
            views.setViewVisibility(R.id.wx_cloud1, if (show1) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.wx_cloud2, if (show2) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.wx_cloud3, if (show3) View.VISIBLE else View.GONE)
            if (show1) views.setInt(R.id.wx_cloud1, "setImageAlpha", (90 + cover).coerceAtMost(200))
            if (show2) views.setInt(R.id.wx_cloud2, "setImageAlpha", (80 + cover / 2).coerceAtMost(180))
            if (show3) views.setInt(R.id.wx_cloud3, "setImageAlpha", 160)
        }

        private fun fillWeek(context: Context, views: RemoteViews, item: JSONObject, lang: String, show: Boolean) {
            views.setViewVisibility(R.id.wx_week, if (show) View.VISIBLE else View.GONE)
            if (!show) return
            val days = item.optString("daily").split(";").filter { it.isNotEmpty() }
            val pkg = context.packageName
            for (i in 0 until 7) {
                val col = context.resources.getIdentifier("wx_w$i", "id", pkg)
                val day = context.resources.getIdentifier("wx_d$i", "id", pkg)
                val icon = context.resources.getIdentifier("wx_di$i", "id", pkg)
                val hi = context.resources.getIdentifier("wx_dh$i", "id", pkg)
                val lo = context.resources.getIdentifier("wx_dl$i", "id", pkg)
                if (i >= days.size) {
                    views.setViewVisibility(col, View.GONE)
                    continue
                }
                val bits = days[i].split("|")
                val iso = bits.getOrNull(0) ?: ""
                val high = bits.getOrNull(1) ?: ""
                val low = bits.getOrNull(2) ?: ""
                val code = bits.getOrNull(3)?.toIntOrNull() ?: 2
                views.setViewVisibility(col, View.VISIBLE)
                views.setTextViewText(day, weekdayShort(iso, lang))
                views.setImageViewResource(icon, iconRes(code))
                views.setTextViewText(hi, if (high.isEmpty()) "" else "$high°")
                views.setTextViewText(lo, if (low.isEmpty()) "" else "$low°")
            }
        }

        private fun applyLegacy(context: Context, views: RemoteViews, lang: String): Boolean {
            val p = WidgetStore.prefs(context)
            val temp = p.getString("wx_temp", "") ?: ""
            if (temp.isEmpty()) return false
            val city = if (lang == "en") p.getString("wx_city_en", "") else p.getString("wx_city", "")
            val label = if (lang == "en") p.getString("wx_label_en", "") else p.getString("wx_label", "")
            val high = p.getString("wx_high", "") ?: ""
            val low = p.getString("wx_low", "") ?: ""
            views.setTextViewText(R.id.wx_city, if (city.isNullOrEmpty()) WidgetStore.title(context) else city)
            views.setTextViewText(R.id.wx_temp, "$temp°")
            views.setTextViewText(R.id.wx_label, label ?: "")
            if (high.isEmpty()) {
                views.setViewVisibility(R.id.wx_range, View.GONE)
            } else {
                views.setViewVisibility(R.id.wx_range, View.VISIBLE)
                views.setTextViewText(R.id.wx_range, "H $high°   L $low°")
            }
            views.setImageViewResource(R.id.wx_icon, R.drawable.ic_wx_cloudy)
            views.setViewVisibility(R.id.wx_icon, View.VISIBLE)
            views.setViewVisibility(R.id.wx_count, View.GONE)
            views.setViewVisibility(R.id.wx_prev, View.GONE)
            views.setViewVisibility(R.id.wx_next, View.GONE)
            return true
        }

        private fun build(context: Context, widgetId: Int): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.khmer_weather_widget)
            val lang = WidgetStore.lang(context)
            val cities = list(context)
            val n = cities.length()
            val open = WidgetStore.launch(context, "weather")
            views.setOnClickPendingIntent(R.id.wx_root, open)
            views.setOnClickPendingIntent(R.id.wx_city, open)
            if (n <= 0) {
                if (!applyLegacy(context, views, lang)) {
                    views.setTextViewText(R.id.wx_city, WidgetStore.title(context))
                    views.setTextViewText(R.id.wx_temp, "--")
                    views.setTextViewText(
                        R.id.wx_label,
                        if (lang == "en") "Open the app for weather" else "បើកកម្មវិធីសម្រាប់អាកាសធាតុ",
                    )
                    views.setViewVisibility(R.id.wx_range, View.GONE)
                    views.setImageViewResource(R.id.wx_icon, R.drawable.ic_wx_cloudy)
                }
                views.setViewVisibility(R.id.wx_week, View.GONE)
                views.setViewVisibility(R.id.wx_hour, View.GONE)
                views.setViewVisibility(R.id.wx_cloud1, View.GONE)
                views.setViewVisibility(R.id.wx_cloud2, View.GONE)
                views.setViewVisibility(R.id.wx_cloud3, View.GONE)
                views.setViewVisibility(R.id.wx_count, View.GONE)
                views.setViewVisibility(R.id.wx_prev, View.GONE)
                views.setViewVisibility(R.id.wx_next, View.GONE)
                return views
            }
            val i = shownIndex(context, widgetId, n)
            val item = cities.optJSONObject(i) ?: JSONObject()
            val city = if (lang == "en") item.optString("nameEn") else item.optString("name")
            val temp = item.optString("temp")
            val high = item.optString("high")
            val low = item.optString("low")
            val label = if (lang == "en") item.optString("labelEn") else item.optString("label")
            val code = item.optString("code").toIntOrNull() ?: 2
            views.setTextViewText(R.id.wx_city, city.ifEmpty { WidgetStore.title(context) })
            views.setTextViewText(R.id.wx_temp, if (temp.isEmpty()) "--" else "$temp°")
            views.setTextViewText(R.id.wx_label, label)
            if (high.isEmpty()) {
                views.setViewVisibility(R.id.wx_range, View.GONE)
            } else {
                views.setViewVisibility(R.id.wx_range, View.VISIBLE)
                views.setTextViewText(R.id.wx_range, "H $high°   L $low°")
            }
            views.setTextViewText(R.id.wx_count, "${i + 1}/$n")
            views.setViewVisibility(R.id.wx_count, if (n > 1) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.wx_prev, if (n > 1) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.wx_next, if (n > 1) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.wx_icon, View.VISIBLE)
            val downloaded = bmp(item.optString("icon"), 96)
            if (downloaded != null) {
                try {
                    views.setImageViewBitmap(R.id.wx_icon, downloaded)
                } catch (_: Exception) {
                    views.setImageViewResource(R.id.wx_icon, iconRes(code))
                }
            } else {
                views.setImageViewResource(R.id.wx_icon, iconRes(code))
            }
            try {
                val photo = bmp(item.optString("photo"), 240)
                if (photo != null) views.setImageViewBitmap(R.id.wx_photo, photo)
            } catch (_: Exception) {
            }
            fillHour(context, views, item, showHour(context, widgetId) && item.optString("hourly").isNotEmpty())
            fillWeek(context, views, item, lang, showWeek(context, widgetId) && item.optString("daily").isNotEmpty())
            fillClouds(views, item.optString("clouds").toIntOrNull() ?: 0)
            views.setOnClickPendingIntent(R.id.wx_prev, shiftPi(context, widgetId, -1, 1))
            views.setOnClickPendingIntent(R.id.wx_next, shiftPi(context, widgetId, 1, 2))
            return views
        }
    }
}
