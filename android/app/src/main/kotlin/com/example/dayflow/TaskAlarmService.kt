package com.example.dayflow

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.NotificationCompat

class TaskAlarmService : Service() {
    companion object {
        private const val TAG = "TaskAlarmService"
        private const val CHANNEL_ID = "dayflow_alarm_channel_v1"
        const val ACTION_CLOSE_ALARM_ACTIVITY =
            "com.example.dayflow.action.CLOSE_ALARM_ACTIVITY"
        private const val SNOOZE_DURATION_MS = 10 * 60 * 1000L

        @Volatile
        var instance: TaskAlarmService? = null

        @Volatile
        var activeTaskId: String? = null

        fun dispatchAction(context: Context, action: String, taskId: String) {
            instance?.handleAction(action, taskId)
                ?: TaskAlarmReceiver.dispatch(context, action, taskId)
        }
    }

    private lateinit var scheduler: NativeAlarmScheduler
    private lateinit var store: NativeAlarmStore
    private lateinit var notificationManager: NotificationManager
    private lateinit var audioManager: AudioManager
    private var mediaPlayer: MediaPlayer? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var currentRecord: NativeAlarmRecord? = null
    private var vibrator: Vibrator? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        scheduler = NativeAlarmScheduler(this)
        store = NativeAlarmStore(this)
        notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager =
                getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        ensureChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val taskId = intent?.getStringExtra(TaskAlarmReceiver.EXTRA_TASK_ID)
        if (taskId.isNullOrBlank()) {
            stopSelf()
            return START_NOT_STICKY
        }

        val action = intent.action ?: TaskAlarmReceiver.ACTION_TRIGGER
        handleAction(action, taskId)
        return START_NOT_STICKY
    }

    internal fun handleAction(action: String, taskId: String) {
        when (action) {
            TaskAlarmReceiver.ACTION_MARK_DONE -> handleMarkDone(taskId)
            TaskAlarmReceiver.ACTION_DISMISS,
            TaskAlarmReceiver.ACTION_CANCEL,
            -> handleDismiss(taskId)

            TaskAlarmReceiver.ACTION_SNOOZE -> handleSnooze(taskId)
            else -> handleTrigger(taskId)
        }
    }

    private fun handleTrigger(taskId: String) {
        val record = store.getAlarm(taskId)
        if (record == null) {
            Log.w(TAG, "Ignoring trigger for unknown taskId=$taskId")
            stopSelf()
            return
        }

        if (currentRecord?.taskId != null && currentRecord?.taskId != taskId) {
            stopCurrentAlarm(clearStoredAlarm = false, closeActivity = true)
        }

        currentRecord = record
        activeTaskId = taskId

        startForeground(record.alarmId, buildNotification(record))
        startAudio()
        startVibration()

        if (AppVisibilityTracker.isFlutterVisible) {
            startActivity(
                AlarmActivity.createIntent(this, record).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                },
            )
        }
    }

    private fun handleDismiss(taskId: String) {
        if (currentRecord?.taskId == taskId) {
            stopCurrentAlarm(clearStoredAlarm = true, closeActivity = true)
            return
        }

        scheduler.removeAlarm(taskId)
        broadcastClose(taskId)
    }

    private fun handleMarkDone(taskId: String) {
        store.enqueueMarkDone(taskId)

        if (currentRecord?.taskId == taskId) {
            stopCurrentAlarm(clearStoredAlarm = true, closeActivity = true)
            return
        }

        scheduler.removeAlarm(taskId)
        broadcastClose(taskId)
    }

    private fun handleSnooze(taskId: String) {
        val record = if (currentRecord?.taskId == taskId) {
            currentRecord
        } else {
            store.getAlarm(taskId)
        }

        if (record == null) {
            broadcastClose(taskId)
            return
        }

        val snoozedAt = System.currentTimeMillis() + SNOOZE_DURATION_MS
        scheduler.scheduleAlarm(record.copy(triggerAtMillis = snoozedAt))
        store.enqueueSnooze(taskId, snoozedAt)

        if (currentRecord?.taskId == taskId) {
            stopCurrentAlarm(clearStoredAlarm = false, closeActivity = true)
        } else {
            broadcastClose(taskId)
        }
    }

    private fun stopCurrentAlarm(
        clearStoredAlarm: Boolean,
        closeActivity: Boolean,
    ) {
        val record = currentRecord
        val taskId = record?.taskId ?: activeTaskId

        if (record != null && clearStoredAlarm) {
            scheduler.removeAlarm(record.taskId)
        }

        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
        abandonAudioFocus()
        stopVibration()

        record?.let { notificationManager.cancel(it.alarmId) }
        if (closeActivity && taskId != null) {
            broadcastClose(taskId)
        }

        currentRecord = null
        activeTaskId = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun startAudio() {
        mediaPlayer?.stop()
        mediaPlayer?.release()

        requestAudioFocus()

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val player = MediaPlayer().apply {
            setAudioAttributes(audioAttributes)
            setDataSource(this@TaskAlarmService, Uri.parse("android.resource://$packageName/${R.raw.dayflow_alarm}"))
            isLooping = true
            prepare()
            start()
        }
        mediaPlayer = player
    }

    private fun startVibration() {
        val vibrator = vibrator ?: return
        if (!vibrator.hasVibrator()) return

        val pattern = longArrayOf(0L, 500L, 500L)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(pattern, 0))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(pattern, 0)
        }
    }

    private fun stopVibration() {
        vibrator?.cancel()
    }

    private fun requestAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                .build()
            audioManager.requestAudioFocus(focusRequest)
            audioFocusRequest = focusRequest
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                null,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE,
            )
        }
    }

    private fun abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let(audioManager::abandonAudioFocusRequest)
            audioFocusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(null)
        }
    }

    private fun buildNotification(record: NativeAlarmRecord): Notification {
        val activityPendingIntent = PendingIntent.getActivity(
            this,
            record.alarmId,
            AlarmActivity.createIntent(this, record),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val dismissPendingIntent = PendingIntent.getBroadcast(
            this,
            record.alarmId + 10_000,
            Intent(this, TaskAlarmReceiver::class.java).apply {
                action = TaskAlarmReceiver.ACTION_DISMISS
                putExtra(TaskAlarmReceiver.EXTRA_TASK_ID, record.taskId)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val snoozePendingIntent = PendingIntent.getBroadcast(
            this,
            record.alarmId + 20_000,
            Intent(this, TaskAlarmReceiver::class.java).apply {
                action = TaskAlarmReceiver.ACTION_SNOOZE
                putExtra(TaskAlarmReceiver.EXTRA_TASK_ID, record.taskId)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(record.title)
            .setContentText(record.subtitle ?: "")
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(activityPendingIntent)
            .setFullScreenIntent(activityPendingIntent, true)
            .setSound(null)
            .addAction(0, getString(R.string.alarm_snooze_10_min), snoozePendingIntent)
            .addAction(0, getString(R.string.alarm_dismiss), dismissPendingIntent)
            .build()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.alarm_notification_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.alarm_notification_channel_description)
            lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            setSound(null, null)
            enableVibration(false)
        }
        notificationManager.createNotificationChannel(channel)
    }

    private fun broadcastClose(taskId: String) {
        sendBroadcast(
            Intent(ACTION_CLOSE_ALARM_ACTIVITY).apply {
                putExtra(TaskAlarmReceiver.EXTRA_TASK_ID, taskId)
            },
        )
    }

    override fun onDestroy() {
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
        stopVibration()
        abandonAudioFocus()
        currentRecord = null
        activeTaskId = null
        instance = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
