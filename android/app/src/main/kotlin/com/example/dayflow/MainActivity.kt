package com.example.dayflow

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onResume() {
        super.onResume()
        AppVisibilityTracker.isFlutterVisible = true
    }

    override fun onPause() {
        AppVisibilityTracker.isFlutterVisible = false
        super.onPause()
    }

    override fun onDestroy() {
        AppVisibilityTracker.isFlutterVisible = false
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "dayflow/permissions"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "canUseFullScreenIntent" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        result.success(nm.canUseFullScreenIntent())
                    } else {
                        // Pre-Android 14: always allowed
                        result.success(true)
                    }
                }
                "openFullScreenIntentSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        val intent = Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT)
                        intent.data = android.net.Uri.parse("package:$packageName")
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "dayflow/native_alarm"
        ).setMethodCallHandler { call, result ->
            val scheduler = NativeAlarmScheduler(applicationContext)
            val store = NativeAlarmStore(applicationContext)

            when (call.method) {
                "scheduleAlarm" -> {
                    val taskId = call.argument<String>("taskId")
                    val title = call.argument<String>("title")
                    val subtitle = call.argument<String>("subtitle")
                    val triggerAtMillis = call.argument<Number>("triggerAtMillis")?.toLong()

                    if (taskId.isNullOrBlank() || title.isNullOrBlank() || triggerAtMillis == null) {
                        result.error("invalid_args", "Missing task alarm arguments", null)
                        return@setMethodCallHandler
                    }

                    runCatching {
                        scheduler.scheduleAlarm(
                            NativeAlarmRecord(
                                taskId = taskId,
                                title = title,
                                subtitle = subtitle,
                                triggerAtMillis = triggerAtMillis,
                            )
                        )
                    }.onSuccess {
                        result.success(true)
                    }.onFailure { error ->
                        result.error("schedule_failed", error.message, null)
                    }
                }

                "cancelAlarm" -> {
                    val taskId = call.argument<String>("taskId")
                    if (taskId.isNullOrBlank()) {
                        result.error("invalid_args", "Missing taskId", null)
                        return@setMethodCallHandler
                    }

                    scheduler.removeAlarm(taskId)
                    if (TaskAlarmService.activeTaskId == taskId) {
                        TaskAlarmService.dispatchAction(
                            applicationContext,
                            TaskAlarmReceiver.ACTION_CANCEL,
                            taskId
                        )
                    }
                    result.success(true)
                }

                "cancelAllAlarms" -> {
                    val alarms = store.getAllAlarms()
                    scheduler.removeAllAlarms()
                    alarms.forEach { record ->
                        if (TaskAlarmService.activeTaskId == record.taskId) {
                            TaskAlarmService.dispatchAction(
                                applicationContext,
                                TaskAlarmReceiver.ACTION_CANCEL,
                                record.taskId
                            )
                        }
                    }
                    result.success(true)
                }

                "getPendingSnoozeActions" -> {
                    result.success(
                        store.getPendingSnoozes().map { action ->
                            mapOf(
                                "taskId" to action.taskId,
                                "triggerAtMillis" to action.triggerAtMillis,
                            )
                        }
                    )
                }

                "getPendingDoneActions" -> {
                    result.success(store.getPendingDoneActions())
                }

                "clearPendingSnoozeActions" -> {
                    store.clearPendingSnoozes()
                    result.success(true)
                }

                "clearPendingDoneActions" -> {
                    store.clearPendingDoneActions()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }
}
