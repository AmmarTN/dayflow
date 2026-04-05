package com.example.dayflow

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

data class NativeAlarmRecord(
    val taskId: String,
    val title: String,
    val subtitle: String?,
    val triggerAtMillis: Long,
) {
    val alarmId: Int
        get() = NativeAlarmIds.fromTaskId(taskId)

    fun toJson(): JSONObject = JSONObject()
        .put("taskId", taskId)
        .put("title", title)
        .put("subtitle", subtitle)
        .put("triggerAtMillis", triggerAtMillis)

    companion object {
        fun fromJson(raw: String): NativeAlarmRecord? = runCatching {
            val json = JSONObject(raw)
            NativeAlarmRecord(
                taskId = json.getString("taskId"),
                title = json.getString("title"),
                subtitle = json.optString("subtitle").ifBlank { null },
                triggerAtMillis = json.getLong("triggerAtMillis"),
            )
        }.getOrNull()
    }
}

data class PendingSnoozeAction(
    val taskId: String,
    val triggerAtMillis: Long,
) {
    fun toJson(): JSONObject = JSONObject()
        .put("taskId", taskId)
        .put("triggerAtMillis", triggerAtMillis)

    companion object {
        fun fromJson(json: JSONObject): PendingSnoozeAction? = runCatching {
            PendingSnoozeAction(
                taskId = json.getString("taskId"),
                triggerAtMillis = json.getLong("triggerAtMillis"),
            )
        }.getOrNull()
    }
}

class NativeAlarmStore(context: Context) {
    companion object {
        private const val ALARMS_PREFS = "dayflow_native_alarms"
        private const val ACTIONS_PREFS = "dayflow_native_alarm_actions"
        private const val SNOOZE_ACTIONS_KEY = "pending_snooze_actions"
        private const val DONE_ACTIONS_KEY = "pending_done_actions"
    }

    private val alarmsPrefs =
        context.getSharedPreferences(ALARMS_PREFS, Context.MODE_PRIVATE)
    private val actionsPrefs =
        context.getSharedPreferences(ACTIONS_PREFS, Context.MODE_PRIVATE)

    fun saveAlarm(record: NativeAlarmRecord) {
        alarmsPrefs.edit().putString(record.taskId, record.toJson().toString()).apply()
    }

    fun getAlarm(taskId: String): NativeAlarmRecord? {
        val raw = alarmsPrefs.getString(taskId, null) ?: return null
        return NativeAlarmRecord.fromJson(raw)
    }

    fun getAllAlarms(): List<NativeAlarmRecord> {
        return alarmsPrefs.all.values.mapNotNull { value ->
            (value as? String)?.let(NativeAlarmRecord::fromJson)
        }
    }

    fun removeAlarm(taskId: String) {
        alarmsPrefs.edit().remove(taskId).apply()
    }

    fun enqueueSnooze(taskId: String, triggerAtMillis: Long) {
        val current = actionsPrefs.getString(SNOOZE_ACTIONS_KEY, null)
        val array = if (current.isNullOrBlank()) JSONArray() else JSONArray(current)
        array.put(
            PendingSnoozeAction(
                taskId = taskId,
                triggerAtMillis = triggerAtMillis,
            ).toJson()
        )
        actionsPrefs.edit().putString(SNOOZE_ACTIONS_KEY, array.toString()).apply()
    }

    fun getPendingSnoozes(): List<PendingSnoozeAction> {
        val raw = actionsPrefs.getString(SNOOZE_ACTIONS_KEY, null) ?: return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    val item = array.optJSONObject(index) ?: continue
                    val action = PendingSnoozeAction.fromJson(item) ?: continue
                    add(action)
                }
            }
        }.getOrElse { emptyList() }
    }

    fun clearPendingSnoozes() {
        actionsPrefs.edit().remove(SNOOZE_ACTIONS_KEY).apply()
    }

    fun enqueueMarkDone(taskId: String) {
        val current = actionsPrefs.getString(DONE_ACTIONS_KEY, null)
        val array = if (current.isNullOrBlank()) JSONArray() else JSONArray(current)
        array.put(taskId)
        actionsPrefs.edit().putString(DONE_ACTIONS_KEY, array.toString()).apply()
    }

    fun getPendingDoneActions(): List<String> {
        val raw = actionsPrefs.getString(DONE_ACTIONS_KEY, null) ?: return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    val taskId = array.optString(index).orEmpty()
                    if (taskId.isNotBlank()) {
                        add(taskId)
                    }
                }
            }
        }.getOrElse { emptyList() }
    }

    fun clearPendingDoneActions() {
        actionsPrefs.edit().remove(DONE_ACTIONS_KEY).apply()
    }
}
