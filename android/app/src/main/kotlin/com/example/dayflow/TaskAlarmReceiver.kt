package com.example.dayflow

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class TaskAlarmReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_TRIGGER = "com.example.dayflow.action.TRIGGER_ALARM"
        const val ACTION_MARK_DONE = "com.example.dayflow.action.MARK_DONE_ALARM"
        const val ACTION_DISMISS = "com.example.dayflow.action.DISMISS_ALARM"
        const val ACTION_SNOOZE = "com.example.dayflow.action.SNOOZE_ALARM"
        const val ACTION_CANCEL = "com.example.dayflow.action.CANCEL_ALARM"
        const val EXTRA_TASK_ID = "extra_task_id"

        fun dispatch(context: Context, action: String, taskId: String) {
            TaskAlarmService.instance?.handleAction(action, taskId)
                ?.let { return }

            val serviceIntent = Intent(context, TaskAlarmService::class.java).apply {
                this.action = action
                putExtra(EXTRA_TASK_ID, taskId)
            }

            if (action == ACTION_TRIGGER && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val taskId = intent.getStringExtra(EXTRA_TASK_ID) ?: return
        val action = intent.action ?: ACTION_TRIGGER
        dispatch(context, action, taskId)
    }
}
