package com.example.dayflow

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.ForegroundColorSpan
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import kotlin.math.roundToInt

class TaskWidgetProvider : HomeWidgetProvider() {
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        TaskWidgetWeatherScheduler.ensureBackgroundRefresh(context)
        TaskWidgetWeatherScheduler.maybeScheduleImmediateRefresh(context)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        if (!WidgetWeatherHelper.hasAnyWidgets(context)) {
            TaskWidgetWeatherScheduler.cancelBackgroundRefresh(context)
        }
    }

    override fun onDisabled(context: Context) {
        TaskWidgetWeatherScheduler.cancelBackgroundRefresh(context)
        super.onDisabled(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        TaskWidgetWeatherScheduler.ensureBackgroundRefresh(context)
        TaskWidgetWeatherScheduler.maybeScheduleImmediateRefresh(context)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.task_widget_layout)
            val widgetWidthPx = widgetWidthPx(context, appWidgetManager, appWidgetId)
            val contentWidthPx = widgetWidthPx - dp(context, 28)
            val headerMetaMaxWidthPx = dp(context, 92)
            val titleColumnMaxWidthPx = (contentWidthPx - dp(context, 44) - dp(context, 10) - headerMetaMaxWidthPx - dp(context, 8))
                .coerceAtLeast(dp(context, 72))

            // ── Read data from shared storage ────────────────────────────────
            val greeting = widgetData.getString("greeting", "Good day") ?: "Good day"
            val taskCountToday = widgetData.getInt("task_count_today", 0)
            val tasksCompletedToday = widgetData.getInt("tasks_completed_today", 0)
            val nextTasksJson = widgetData.getString("next_tasks_json", "[]") ?: "[]"
            val calendar = Calendar.getInstance()
            val locale = Locale.getDefault()
            val dayNumber = SimpleDateFormat("d", locale).format(calendar.time)
            val weekday = SimpleDateFormat("EEEE", locale).format(calendar.time)
            val monthDay = SimpleDateFormat("MMM d", locale).format(calendar.time)

            // ── Parse tasks JSON ─────────────────────────────────────────────
            val tasks = mutableListOf<Pair<String, String?>>()
            try {
                val arr = JSONArray(nextTasksJson)
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    val title = obj.optString("title", "")
                    val alarm = if (obj.isNull("alarm")) {
                        null
                    } else {
                        obj.optString("alarm", "")
                            .trim()
                            .takeIf { it.isNotEmpty() && !it.equals("null", ignoreCase = true) }
                    }
                    if (title.isNotEmpty()) tasks.add(Pair(title, alarm))
                }
            } catch (_: Exception) {
                // Malformed JSON — proceed with empty list
            }
            val isEmptyState = tasks.isEmpty()

            // ── Top row ──────────────────────────────────────────────────────
            views.setImageViewBitmap(
                R.id.iv_day_number,
                WidgetTextBitmapFactory.renderSingleLine(
                    context = context,
                    text = dayNumber,
                    fontRes = R.font.urbanist_bold,
                    textSizeSp = 22f,
                    color = Color.parseColor("#FF07140D"),
                    maxWidthPx = dp(context, 26),
                )
            )
            views.setImageViewBitmap(
                R.id.iv_weekday,
                WidgetTextBitmapFactory.renderSingleLine(
                    context = context,
                    text = weekday,
                    fontRes = R.font.urbanist_bold,
                    textSizeSp = 17f,
                    color = Color.parseColor("#FFF8F8F8"),
                    maxWidthPx = titleColumnMaxWidthPx,
                )
            )
            views.setImageViewBitmap(
                R.id.iv_month_day,
                WidgetTextBitmapFactory.renderSingleLine(
                    context = context,
                    text = monthDay,
                    fontRes = R.font.urbanist_medium,
                    textSizeSp = 11f,
                    color = Color.parseColor("#FF8E9490"),
                    maxWidthPx = titleColumnMaxWidthPx,
                )
            )
            val headerMetadata = WidgetWeatherHelper.buildHeaderMetadata(taskCountToday, widgetData)
            views.setImageViewBitmap(
                R.id.iv_header_temp,
                WidgetTextBitmapFactory.renderSingleLine(
                    context = context,
                    text = headerMetadata.primaryText,
                    fontRes = if (headerMetadata.iconText == null) {
                        R.font.urbanist_semibold
                    } else {
                        R.font.urbanist_bold
                    },
                    textSizeSp = headerMetadata.primaryTextSizeSp,
                    color = headerMetadata.primaryColor,
                    maxWidthPx = if (headerMetadata.iconText == null) {
                        headerMetaMaxWidthPx
                    } else {
                        headerMetaMaxWidthPx - dp(context, 18)
                    },
                )
            )
            if (headerMetadata.iconText != null) {
                views.setViewVisibility(R.id.tv_header_icon, View.VISIBLE)
                views.setTextViewText(R.id.tv_header_icon, headerMetadata.iconText)
                views.setTextColor(R.id.tv_header_icon, headerMetadata.iconColor)
                views.setTextViewTextSize(
                    R.id.tv_header_icon,
                    TypedValue.COMPLEX_UNIT_SP,
                    headerMetadata.iconTextSizeSp
                )
            } else {
                views.setViewVisibility(R.id.tv_header_icon, View.GONE)
                views.setTextViewText(R.id.tv_header_icon, "")
            }
            applyBitmapText(
                views = views,
                viewId = R.id.iv_greeting,
                bitmap = WidgetTextBitmapFactory.renderSingleLine(
                    context = context,
                    text = greeting,
                    fontRes = R.font.urbanist_bold,
                    textSizeSp = if (isEmptyState) 19f else 17f,
                    color = Color.parseColor("#FFF8F8F8"),
                    maxWidthPx = contentWidthPx,
                )
            )
            applyBitmapText(
                views = views,
                viewId = R.id.iv_headline,
                bitmap = WidgetTextBitmapFactory.renderSingleLine(
                    context = context,
                    text = buildHeadline(taskCountToday),
                    fontRes = R.font.urbanist_medium,
                    textSizeSp = if (isEmptyState) 13.5f else 12f,
                    color = Color.parseColor("#FFF8F8F8"),
                    maxWidthPx = contentWidthPx,
                )
            )

            // ── Bind primary task card ───────────────────────────────────────
            if (tasks.isNotEmpty()) {
                val (title, alarm) = tasks.first()
                views.setViewVisibility(R.id.card_task, View.VISIBLE)
                views.setViewVisibility(R.id.iv_empty_state, View.GONE)
                applyBitmapText(
                    views = views,
                    viewId = R.id.iv_task_title,
                    bitmap = WidgetTextBitmapFactory.renderSingleLine(
                        context = context,
                        text = title,
                        fontRes = R.font.urbanist_semibold,
                        textSizeSp = 14f,
                        color = Color.parseColor("#FFF8F8F8"),
                        maxWidthPx = (contentWidthPx - dp(context, 16 + 10 + 12 + 12 + 8 + 72))
                            .coerceAtLeast(dp(context, 80)),
                    )
                )
                views.setViewVisibility(R.id.iv_task_circle, View.VISIBLE)
                if (alarm != null) {
                    views.setViewVisibility(R.id.iv_task_alarm, View.VISIBLE)
                    applyBitmapText(
                        views = views,
                        viewId = R.id.iv_task_alarm,
                        bitmap = WidgetTextBitmapFactory.renderSingleLine(
                            context = context,
                            text = alarm,
                            fontRes = R.font.urbanist_semibold,
                            textSizeSp = 11f,
                            color = Color.parseColor("#FF1EE468"),
                            maxWidthPx = dp(context, 72),
                        )
                    )
                } else {
                    views.setViewVisibility(R.id.iv_task_alarm, View.GONE)
                }
            } else {
                views.setViewVisibility(R.id.card_task, View.GONE)
                views.setViewVisibility(R.id.iv_task_circle, View.GONE)
                views.setViewVisibility(R.id.iv_task_alarm, View.GONE)
                views.setViewVisibility(R.id.iv_empty_state, View.VISIBLE)
                val emptyTitle = if (taskCountToday == 0) "No tasks for today" else "All tasks completed"
                applyBitmapText(
                    views = views,
                    viewId = R.id.iv_empty_state,
                    bitmap = WidgetTextBitmapFactory.renderSingleLine(
                        context = context,
                        text = emptyTitle,
                        fontRes = R.font.urbanist_medium,
                        textSizeSp = 14f,
                        color = Color.parseColor("#FF8E9490"),
                        maxWidthPx = contentWidthPx,
                    )
                )
            }

            // ── Bottom summary ────────────────────────────────────────────────
            applyBitmapText(
                views = views,
                viewId = R.id.iv_summary,
                bitmap = WidgetTextBitmapFactory.renderSingleLine(
                    context = context,
                    text = "✓ $tasksCompletedToday of $taskCountToday done",
                    fontRes = R.font.urbanist_medium,
                    textSizeSp = if (isEmptyState) 11f else 10f,
                    color = Color.parseColor("#FF7D827E"),
                    maxWidthPx = contentWidthPx,
                )
            )

            // ── Tap to open app ──────────────────────────────────────────────
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun buildHeadline(taskCountToday: Int): CharSequence {
        val highlighted = if (taskCountToday == 1) "1 task" else "$taskCountToday tasks"
        val full = "You have $highlighted today."
        val start = full.indexOf(highlighted)
        val end = start + highlighted.length
        return SpannableStringBuilder(full).apply {
            if (start >= 0) {
                setSpan(
                    ForegroundColorSpan(Color.parseColor("#1EE468")),
                    start,
                    end,
                    Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
                )
            }
        }
    }

    private fun widgetWidthPx(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ): Int {
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 } ?: 250
        return dp(context, widthDp)
    }

    private fun applyBitmapText(
        views: RemoteViews,
        viewId: Int,
        bitmap: android.graphics.Bitmap,
    ) {
        views.setImageViewBitmap(viewId, bitmap)
    }

    private fun dp(context: Context, value: Int): Int {
        return (value * context.resources.displayMetrics.density).roundToInt()
    }
}
