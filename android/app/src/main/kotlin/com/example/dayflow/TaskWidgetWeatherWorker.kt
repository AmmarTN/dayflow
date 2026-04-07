package com.example.dayflow

import android.content.Context
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

class TaskWidgetWeatherWorker(
    appContext: Context,
    workerParams: WorkerParameters,
) : Worker(appContext, workerParams) {

    override fun doWork(): Result {
        if (!WidgetWeatherHelper.hasAnyWidgets(applicationContext)) {
            TaskWidgetWeatherScheduler.cancelBackgroundRefresh(applicationContext)
            return Result.success()
        }

        val prefs = WidgetWeatherHelper.widgetData(applicationContext)
        val hadWeather = WidgetWeatherHelper.readWeatherSnapshot(prefs) != null
        val shouldRefresh = WidgetWeatherHelper.isWeatherMissingOrStale(prefs)

        if (shouldRefresh) {
            WidgetWeatherHelper.fetchAndPersistWeather(applicationContext, prefs)
        }

        if (shouldRefresh || hadWeather) {
            WidgetWeatherHelper.requestWidgetUpdate(applicationContext)
        }

        return Result.success()
    }
}

object TaskWidgetWeatherScheduler {
    private const val periodicWorkName = "dayflow_widget_weather_periodic"
    private const val immediateWorkName = "dayflow_widget_weather_immediate"

    fun ensureBackgroundRefresh(context: Context) {
        if (!WidgetWeatherHelper.hasAnyWidgets(context)) return

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            periodicWorkName,
            ExistingPeriodicWorkPolicy.KEEP,
            PeriodicWorkRequestBuilder<TaskWidgetWeatherWorker>(1, TimeUnit.HOURS)
                .setConstraints(defaultConstraints())
                .build()
        )
    }

    fun maybeScheduleImmediateRefresh(context: Context) {
        if (!WidgetWeatherHelper.hasAnyWidgets(context)) return
        if (!WidgetWeatherHelper.isWeatherMissingOrStale(WidgetWeatherHelper.widgetData(context))) {
            return
        }

        WorkManager.getInstance(context).enqueueUniqueWork(
            immediateWorkName,
            ExistingWorkPolicy.REPLACE,
            OneTimeWorkRequestBuilder<TaskWidgetWeatherWorker>()
                .setConstraints(defaultConstraints())
                .build()
        )
    }

    fun cancelBackgroundRefresh(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(periodicWorkName)
        WorkManager.getInstance(context).cancelUniqueWork(immediateWorkName)
    }

    private fun defaultConstraints(): Constraints {
        return Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()
    }
}
