package com.example.dayflow

object NativeAlarmIds {
    fun fromTaskId(taskId: String): Int {
        var hash = 0x811C9DC5.toInt()
        taskId.forEach { char ->
            hash = hash xor char.code
            hash *= 16777619
        }

        val positive = hash and 0x7fffffff
        return if (positive == 0) 1 else positive
    }
}
