package com.example.dayflow

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

class NativeAlarmScheduler(private val context: Context) {
    private val alarmManager =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    private val notificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private val store = NativeAlarmStore(context)

    fun scheduleAlarm(record: NativeAlarmRecord) {
        cancelPendingIntent(record.taskId)
        store.saveAlarm(record)

        val triggerIntent = Intent(context, TaskAlarmReceiver::class.java).apply {
            action = TaskAlarmReceiver.ACTION_TRIGGER
            putExtra(TaskAlarmReceiver.EXTRA_TASK_ID, record.taskId)
        }
        val triggerPendingIntent = PendingIntent.getBroadcast(
            context,
            record.alarmId,
            triggerIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val showIntent = PendingIntent.getActivity(
            context,
            record.alarmId,
            AlarmActivity.createIntent(context, record),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val alarmInfo = AlarmManager.AlarmClockInfo(record.triggerAtMillis, showIntent)
        alarmManager.setAlarmClock(alarmInfo, triggerPendingIntent)
    }

    fun removeAlarm(taskId: String) {
        cancelPendingIntent(taskId)
        store.removeAlarm(taskId)
        notificationManager.cancel(NativeAlarmIds.fromTaskId(taskId))
    }

    fun removeAllAlarms() {
        store.getAllAlarms().forEach { record ->
            removeAlarm(record.taskId)
        }
    }

    fun rescheduleStoredAlarms() {
        val now = System.currentTimeMillis()
        store.getAllAlarms().forEach { record ->
            if (record.triggerAtMillis <= now) {
                store.removeAlarm(record.taskId)
            } else {
                scheduleAlarm(record)
            }
        }
    }

    private fun cancelPendingIntent(taskId: String) {
        val alarmId = NativeAlarmIds.fromTaskId(taskId)
        val intent = Intent(context, TaskAlarmReceiver::class.java).apply {
            action = TaskAlarmReceiver.ACTION_TRIGGER
            putExtra(TaskAlarmReceiver.EXTRA_TASK_ID, taskId)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }
}
