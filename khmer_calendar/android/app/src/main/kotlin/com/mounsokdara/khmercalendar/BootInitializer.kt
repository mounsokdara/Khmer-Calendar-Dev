package com.mounsokdara.khmercalendar

import android.content.Context
import androidx.startup.Initializer

/**
 * Jetpack App Startup initializer.
 * Runs once when the process starts (app launch, boot receiver, widget)
 * so reminders and home-screen widgets re-arm without opening the UI.
 */
class BootInitializer : Initializer<Unit> {
    override fun create(context: Context) {
        BootWork.run(context)
    }

    override fun dependencies(): List<Class<out Initializer<*>>> = emptyList()
}
