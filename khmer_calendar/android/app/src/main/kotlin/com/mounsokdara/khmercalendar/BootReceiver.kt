package com.mounsokdara.khmercalendar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_LOCKED_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED &&
            action != Intent.ACTION_REBOOT &&
            action != "android.intent.action.QUICKBOOT_POWERON" &&
            action != "com.htc.intent.action.QUICKBOOT_POWERON" &&
            action != "android.intent.action.ACTION_BOOT_COMPLETED"
        ) {
            return
        }
        BootWork.run(context)
    }

    companion object {
        const val PREFS = "khmer_perms"
    }
}
