package com.example.dayflow

import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.animation.PropertyValuesHolder
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.text.format.DateFormat
import android.view.animation.AccelerateDecelerateInterpolator
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.activity.addCallback
import androidx.activity.ComponentActivity
import java.util.Date

class AlarmActivity : ComponentActivity() {
    companion object {
        private const val EXTRA_TITLE = "extra_title"
        private const val EXTRA_SUBTITLE = "extra_subtitle"
        private const val EXTRA_TRIGGER_AT = "extra_trigger_at"

        fun createIntent(context: Context, record: NativeAlarmRecord): Intent {
            return Intent(context, AlarmActivity::class.java).apply {
                putExtra(TaskAlarmReceiver.EXTRA_TASK_ID, record.taskId)
                putExtra(EXTRA_TITLE, record.title)
                putExtra(EXTRA_SUBTITLE, record.subtitle)
                putExtra(EXTRA_TRIGGER_AT, record.triggerAtMillis)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
        }
    }

    private var taskId: String? = null
    private var pulseAnimators: List<AnimatorSet> = emptyList()
    private val closeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val actionTaskId = intent.getStringExtra(TaskAlarmReceiver.EXTRA_TASK_ID)
            if (actionTaskId == taskId) {
                finishAlarmScreen()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        configureWindow()
        setContentView(R.layout.activity_alarm)
        onBackPressedDispatcher.addCallback(this) {}
        bindIntent(intent)
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        if (intent == null) return
        setIntent(intent)
        bindIntent(intent)
    }

    override fun onStart() {
        super.onStart()
        val filter = IntentFilter(TaskAlarmService.ACTION_CLOSE_ALARM_ACTIVITY)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(closeReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(closeReceiver, filter)
        }
        startPulseAnimation()
    }

    override fun onStop() {
        stopPulseAnimation()
        runCatching { unregisterReceiver(closeReceiver) }
        super.onStop()
    }

    private fun bindIntent(intent: Intent) {
        val currentTaskId = intent.getStringExtra(TaskAlarmReceiver.EXTRA_TASK_ID)
        if (currentTaskId.isNullOrBlank()) {
            finishAlarmScreen()
            return
        }
        taskId = currentTaskId

        findViewById<TextView>(R.id.alarmTitle).text =
            intent.getStringExtra(EXTRA_TITLE).orEmpty()

        val subtitleView = findViewById<TextView>(R.id.alarmSubtitle)
        val subtitle = intent.getStringExtra(EXTRA_SUBTITLE)
        if (subtitle.isNullOrBlank()) {
            subtitleView.text = ""
            subtitleView.visibility = View.GONE
        } else {
            subtitleView.text = subtitle
            subtitleView.visibility = View.VISIBLE
        }

        val triggerAt = intent.getLongExtra(EXTRA_TRIGGER_AT, System.currentTimeMillis())
        val timeFormat = DateFormat.getTimeFormat(this)
        findViewById<TextView>(R.id.alarmTime).text = timeFormat.format(Date(triggerAt))

        findViewById<Button>(R.id.markDoneButton).setOnClickListener {
            TaskAlarmService.dispatchAction(
                applicationContext,
                TaskAlarmReceiver.ACTION_MARK_DONE,
                currentTaskId,
            )
            finishAlarmScreen()
        }

        findViewById<Button>(R.id.snoozeButton).setOnClickListener {
            TaskAlarmService.dispatchAction(
                applicationContext,
                TaskAlarmReceiver.ACTION_SNOOZE,
                currentTaskId,
            )
            finishAlarmScreen()
        }

        findViewById<TextView>(R.id.dismissButton).setOnClickListener {
            TaskAlarmService.dispatchAction(
                applicationContext,
                TaskAlarmReceiver.ACTION_DISMISS,
                currentTaskId,
            )
            finishAlarmScreen()
        }
    }

    private fun configureWindow() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }

        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
        )
    }

    private fun finishAlarmScreen() {
        finish()
    }

    private fun startPulseAnimation() {
        if (pulseAnimators.isNotEmpty()) return

        val mainRing = findViewById<View>(R.id.pulseRing)
        val outerRing = findViewById<View>(R.id.pulseRingOuter)
        val iconHalo = findViewById<View>(R.id.iconHalo)

        pulseAnimators = listOf(
            createPulseAnimator(
                view = mainRing,
                startScale = 1f,
                endScale = 1.16f,
                startAlpha = 0.75f,
                endAlpha = 0.22f,
                durationMs = 1200L,
                startDelay = 0L,
            ),
            createPulseAnimator(
                view = outerRing,
                startScale = 0.92f,
                endScale = 1.22f,
                startAlpha = 0.38f,
                endAlpha = 0.08f,
                durationMs = 1200L,
                startDelay = 180L,
            ),
            createPulseAnimator(
                view = iconHalo,
                startScale = 1f,
                endScale = 1.06f,
                startAlpha = 1f,
                endAlpha = 0.88f,
                durationMs = 1200L,
                startDelay = 0L,
            ),
        )

        pulseAnimators.forEach(AnimatorSet::start)
    }

    private fun stopPulseAnimation() {
        pulseAnimators.forEach { animator ->
            animator.cancel()
        }
        pulseAnimators = emptyList()
    }

    private fun createPulseAnimator(
        view: View,
        startScale: Float,
        endScale: Float,
        startAlpha: Float,
        endAlpha: Float,
        durationMs: Long,
        startDelay: Long,
    ): AnimatorSet {
        view.scaleX = startScale
        view.scaleY = startScale
        view.alpha = startAlpha

        val scaleX = ObjectAnimator.ofPropertyValuesHolder(
            view,
            PropertyValuesHolder.ofFloat(View.SCALE_X, startScale, endScale),
        )
        val scaleY = ObjectAnimator.ofPropertyValuesHolder(
            view,
            PropertyValuesHolder.ofFloat(View.SCALE_Y, startScale, endScale),
        )
        val alpha = ObjectAnimator.ofPropertyValuesHolder(
            view,
            PropertyValuesHolder.ofFloat(View.ALPHA, startAlpha, endAlpha),
        )

        return AnimatorSet().apply {
            playTogether(scaleX, scaleY, alpha)
            duration = durationMs
            repeatIndefinitely(scaleX, scaleY, alpha)
            this.startDelay = startDelay
            interpolator = AccelerateDecelerateInterpolator()
        }
    }

    private fun AnimatorSet.repeatIndefinitely(vararg animators: ObjectAnimator) {
        animators.forEach { animator ->
            animator.repeatCount = ObjectAnimator.INFINITE
            animator.repeatMode = ObjectAnimator.REVERSE
        }
    }
}
