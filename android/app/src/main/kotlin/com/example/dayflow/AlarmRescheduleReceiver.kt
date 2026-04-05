package com.example.dayflow

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmRescheduleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        NativeAlarmScheduler(context).rescheduleStoredAlarms()
    }
}
