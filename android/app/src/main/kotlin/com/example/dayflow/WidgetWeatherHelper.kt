package com.example.dayflow

import android.Manifest
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.location.Location
import android.location.LocationManager
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import com.google.android.gms.tasks.Tasks
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.util.Calendar
import java.util.concurrent.TimeUnit
import kotlin.math.roundToInt

data class WidgetHeaderMetadata(
    val primaryText: CharSequence,
    val iconText: CharSequence?,
    val primaryColor: Int,
    val iconColor: Int,
    val primaryTextSizeSp: Float,
    val iconTextSizeSp: Float,
)

data class WidgetWeatherSnapshot(
    val tempValue: Int,
    val weatherCode: Int,
    val updatedAtMillis: Long,
)

data class WidgetLocationSnapshot(
    val latitude: Double,
    val longitude: Double,
    val updatedAtMillis: Long,
)

object WidgetWeatherHelper {
    private const val weatherFreshnessMs = 60 * 60 * 1000L
    private const val weatherTempKey = "weather_temp"
    private const val weatherTempValueKey = "weather_temp_value"
    private const val weatherCodeKey = "weather_code"
    private const val weatherUpdatedAtKey = "weather_updated_at"
    private const val weatherLatKey = "weather_lat"
    private const val weatherLonKey = "weather_lon"
    private const val weatherLocationUpdatedAtKey = "weather_location_updated_at"

    fun widgetData(context: Context): SharedPreferences = HomeWidgetPlugin.getData(context)

    fun hasAnyWidgets(context: Context): Boolean {
        val ids = AppWidgetManager.getInstance(context).getAppWidgetIds(
            ComponentName(context, TaskWidgetProvider::class.java)
        )
        return ids.isNotEmpty()
    }

    fun buildHeaderMetadata(taskCountToday: Int, prefs: SharedPreferences): WidgetHeaderMetadata {
        val snapshot = readWeatherSnapshot(prefs)
        return if (snapshot != null) {
            WidgetHeaderMetadata(
                primaryText = "${snapshot.tempValue}°",
                iconText = weatherEmoji(snapshot.weatherCode),
                primaryColor = if (isWeatherFresh(snapshot)) {
                    Color.parseColor("#FFF8F8F8")
                } else {
                    Color.parseColor("#B8F8F8F8")
                },
                iconColor = if (isWeatherFresh(snapshot)) {
                    Color.parseColor("#FFF8F8F8")
                } else {
                    Color.parseColor("#B8F8F8F8")
                },
                primaryTextSizeSp = 17f,
                iconTextSizeSp = 18f,
            )
        } else {
            WidgetHeaderMetadata(
                primaryText = taskCountLabel(taskCountToday),
                iconText = null,
                primaryColor = Color.parseColor("#FF1EE468"),
                iconColor = Color.parseColor("#FF1EE468"),
                primaryTextSizeSp = 10f,
                iconTextSizeSp = 10f,
            )
        }
    }

    fun taskCountLabel(taskCountToday: Int): String {
        return if (taskCountToday == 1) "1 task today" else "$taskCountToday tasks today"
    }

    fun readWeatherSnapshot(prefs: SharedPreferences): WidgetWeatherSnapshot? {
        if (!prefs.contains(weatherTempValueKey) ||
            !prefs.contains(weatherCodeKey) ||
            !prefs.contains(weatherUpdatedAtKey)
        ) {
            return null
        }

        return WidgetWeatherSnapshot(
            tempValue = prefs.getInt(weatherTempValueKey, 0),
            weatherCode = prefs.getInt(weatherCodeKey, 0),
            updatedAtMillis = prefs.getLong(weatherUpdatedAtKey, 0L),
        )
    }

    fun isWeatherFresh(snapshot: WidgetWeatherSnapshot): Boolean {
        return System.currentTimeMillis() - snapshot.updatedAtMillis <= weatherFreshnessMs
    }

    fun isWeatherMissingOrStale(prefs: SharedPreferences): Boolean {
        val snapshot = readWeatherSnapshot(prefs) ?: return true
        return !isWeatherFresh(snapshot)
    }

    fun fetchAndPersistWeather(context: Context, prefs: SharedPreferences): WidgetWeatherSnapshot? {
        val locationSnapshot = resolveLocationSnapshot(context, prefs) ?: return null
        val latitude = locationSnapshot.latitude.toString()
        val longitude = locationSnapshot.longitude.toString()
        val timezone = URLEncoder.encode(java.util.TimeZone.getDefault().id, Charsets.UTF_8.name())
        val url = URL(
            "https://api.open-meteo.com/v1/forecast" +
                "?latitude=$latitude" +
                "&longitude=$longitude" +
                "&current=temperature_2m,weather_code" +
                "&timezone=$timezone"
        )

        val connection = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 10000
            readTimeout = 10000
            doInput = true
        }

        return try {
            connection.connect()
            if (connection.responseCode != HttpURLConnection.HTTP_OK) {
                null
            } else {
                val body = connection.inputStream.bufferedReader().use { it.readText() }
                val current = JSONObject(body).getJSONObject("current")
                val snapshot = WidgetWeatherSnapshot(
                    tempValue = current.getDouble("temperature_2m").roundToInt(),
                    weatherCode = current.getInt("weather_code"),
                    updatedAtMillis = System.currentTimeMillis(),
                )
                persistWeather(
                    prefs = prefs,
                    snapshot = snapshot,
                    locationSnapshot = locationSnapshot.copy(
                        updatedAtMillis = System.currentTimeMillis()
                    ),
                )
                snapshot
            }
        } catch (_: Exception) {
            null
        } finally {
            connection.disconnect()
        }
    }

    fun requestWidgetUpdate(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, TaskWidgetProvider::class.java)
        )
        if (appWidgetIds.isEmpty()) return

        val updateIntent = Intent(context, TaskWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
        }
        context.sendBroadcast(updateIntent)
    }

    private fun persistWeather(
        prefs: SharedPreferences,
        snapshot: WidgetWeatherSnapshot,
        locationSnapshot: WidgetLocationSnapshot? = null,
    ) {
        val editor = prefs.edit()
            .putString(weatherTempKey, "${snapshot.tempValue}°")
            .putInt(weatherTempValueKey, snapshot.tempValue)
            .putInt(weatherCodeKey, snapshot.weatherCode)
            .putLong(weatherUpdatedAtKey, snapshot.updatedAtMillis)
        if (locationSnapshot != null) {
            editor
                .putString(weatherLatKey, locationSnapshot.latitude.toString())
                .putString(weatherLonKey, locationSnapshot.longitude.toString())
                .putLong(weatherLocationUpdatedAtKey, locationSnapshot.updatedAtMillis)
        }
        editor.apply()
    }

    private fun hasLocationPermission(context: Context): Boolean {
        val coarseGranted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == android.content.pm.PackageManager.PERMISSION_GRANTED
        val fineGranted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == android.content.pm.PackageManager.PERMISSION_GRANTED
        return coarseGranted || fineGranted
    }

    private fun resolveLastKnownLocation(context: Context): Location? {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            ?: return null

        return runCatching {
            locationManager.getProviders(true)
                .asSequence()
                .mapNotNull { provider ->
                    runCatching { locationManager.getLastKnownLocation(provider) }.getOrNull()
                }
                .maxByOrNull { it.time }
        }.getOrNull()
    }

    private fun resolveLocationSnapshot(
        context: Context,
        prefs: SharedPreferences,
    ): WidgetLocationSnapshot? {
        val liveLocation = if (hasLocationPermission(context)) {
            resolveCurrentFusedLocation(context)
                ?: resolveFusedLastLocation(context)
                ?: resolveLastKnownLocation(context)
        } else {
            null
        }

        if (liveLocation != null) {
            return WidgetLocationSnapshot(
                latitude = liveLocation.latitude,
                longitude = liveLocation.longitude,
                updatedAtMillis = System.currentTimeMillis(),
            )
        }

        return readLocationSnapshot(prefs)
    }

    private fun readLocationSnapshot(prefs: SharedPreferences): WidgetLocationSnapshot? {
        val lat = prefs.getString(weatherLatKey, null)?.toDoubleOrNull() ?: return null
        val lon = prefs.getString(weatherLonKey, null)?.toDoubleOrNull() ?: return null
        return WidgetLocationSnapshot(
            latitude = lat,
            longitude = lon,
            updatedAtMillis = prefs.getLong(weatherLocationUpdatedAtKey, 0L),
        )
    }

    private fun resolveCurrentFusedLocation(context: Context): Location? {
        return runCatching {
            val fusedClient = LocationServices.getFusedLocationProviderClient(context)
            val tokenSource = CancellationTokenSource()
            Tasks.await(
                fusedClient.getCurrentLocation(
                    Priority.PRIORITY_BALANCED_POWER_ACCURACY,
                    tokenSource.token,
                ),
                8,
                TimeUnit.SECONDS,
            )
        }.getOrNull()
    }

    private fun resolveFusedLastLocation(context: Context): Location? {
        return runCatching {
            val fusedClient = LocationServices.getFusedLocationProviderClient(context)
            Tasks.await(fusedClient.lastLocation, 5, TimeUnit.SECONDS)
        }.getOrNull()
    }

    private fun weatherEmoji(code: Int): String {
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        val isNight = hour < 6 || hour >= 20

        return when (code) {
            0 -> if (isNight) "🌙" else "☀️"
            1 -> if (isNight) "🌙" else "🌤️"
            2 -> "⛅"
            3 -> "☁️"
            45, 48 -> "🌫️"
            51, 53, 55 -> "🌦️"
            56, 57, 61, 63, 65, 80, 81, 82 -> "🌧️"
            66, 67 -> "🧊"
            71, 73, 75, 77, 85, 86 -> "🌨️"
            95, 96, 99 -> "⛈️"
            else -> "☁️"
        }
    }
}
