import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:dayflow/infrastructure/models/tasks/task_model.dart';
import 'package:dayflow/core/usecases/tasks/get_tasks.dart';
import 'package:dayflow/core/usecases/tasks/save_tasks.dart';
import 'package:dayflow/core/usecases/usecase.dart';

@lazySingleton
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const _notifChannelId = 'task_reminders_v3';
  static const _notifChannelName = 'Task Reminders';
  static const _notifChannelDesc = 'Push notifications for scheduled tasks';
  static const _nativeAlarmChannel = MethodChannel('dayflow/native_alarm');

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings: settings);
  }

  Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // ─── Push notification (no alarm screen) ───
  //
  // Relies solely on zonedSchedule — the OS fires the notification
  // reliably in foreground, background, and killed states.

  Future<void> scheduleNotification(TaskModel task) async {
    if (task.scheduledTime == null) return;

    final scheduledDt = _combineDateAndTime(task.createdAt, task.scheduledTime!);
    if (scheduledDt == null) return;

    final now = tz.TZDateTime.now(tz.local);
    final tzScheduled = tz.TZDateTime.from(scheduledDt, tz.local);
    if (tzScheduled.isBefore(now)) return;

    await requestPermissions();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _notifChannelId,
        _notifChannelName,
        channelDescription: _notifChannelDesc,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    await _plugin.zonedSchedule(
      id: task.id.hashCode,
      title: task.title,
      body: task.subtitle,
      scheduledDate: tzScheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'notif:${task.id}',
    );
  }

  // ─── Alarm ───
  //
  // Android uses the native alarm pipeline exposed over MethodChannel:
  // AlarmManager + BroadcastReceiver + foreground service + full-screen activity.
  // iOS keeps the alarm package flow.

  Future<void> scheduleAlarm(TaskModel task) async {
    if (task.scheduledTime == null) return;

    final scheduledDt = _combineDateAndTime(task.createdAt, task.scheduledTime!);
    if (scheduledDt == null || scheduledDt.isBefore(DateTime.now())) return;

    await requestPermissions();

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _nativeAlarmChannel.invokeMethod<void>('scheduleAlarm', {
        'taskId': task.id,
        'title': task.title,
        'subtitle': task.subtitle,
        'triggerAtMillis': scheduledDt.millisecondsSinceEpoch,
      });
      return;
    }

    final alarmId = _alarmIdFor(task.id);

    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: scheduledDt,
      assetAudioPath: 'assets/alarm_sound.mp3',
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: defaultTargetPlatform == TargetPlatform.iOS,
      androidFullScreenIntent: true,
      androidStopAlarmOnTermination: false,
      volumeSettings: VolumeSettings.fade(fadeDuration: const Duration(seconds: 3), volume: 0.8),
      notificationSettings: NotificationSettings(title: task.title, body: task.subtitle ?? '', stopButton: 'Dismiss'),
      payload: task.id,
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  // ─── Cancel ───

  Future<void> cancelNotification(String taskId) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _nativeAlarmChannel.invokeMethod<void>('cancelAlarm', {'taskId': taskId});
    } else {
      final alarmId = _alarmIdFor(taskId);
      await Alarm.stop(alarmId);
    }
    await _plugin.cancel(id: taskId.hashCode);
  }

  Future<void> cancelAll() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _nativeAlarmChannel.invokeMethod<void>('cancelAllAlarms');
    } else {
      await Alarm.stopAll();
    }
    await _plugin.cancelAll();
  }

  Future<bool> syncPendingAndroidAlarmActions(GetTasks getTasks, SaveTasks saveTasks) async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;

    try {
      final rawSnoozeActions =
          await _nativeAlarmChannel.invokeMethod<List<dynamic>>('getPendingSnoozeActions') ?? const <dynamic>[];
      final rawDoneActions =
          await _nativeAlarmChannel.invokeMethod<List<dynamic>>('getPendingDoneActions') ?? const <dynamic>[];
      if (rawSnoozeActions.isEmpty && rawDoneActions.isEmpty) return false;

      final tasksResult = getTasks(NoParams());
      if (tasksResult.isLeft()) return false;

      var updatedTasks = List<TaskModel>.from(tasksResult.getOrElse(() => []));
      var changed = false;

      for (final rawAction in rawSnoozeActions) {
        if (rawAction is! Map) continue;

        final taskId = rawAction['taskId'] as String?;
        final triggerAtMillis = (rawAction['triggerAtMillis'] as num?)?.toInt();
        if (taskId == null || triggerAtMillis == null) continue;

        final index = updatedTasks.indexWhere((task) => task.id == taskId);
        if (index == -1) continue;

        final triggerAt = DateTime.fromMillisecondsSinceEpoch(triggerAtMillis);
        final dateOnly = DateTime(triggerAt.year, triggerAt.month, triggerAt.day);
        final formattedTime = _formatTime(triggerAt);

        updatedTasks[index] = updatedTasks[index].copyWith(
          createdAt: dateOnly,
          scheduledTime: formattedTime,
          reminderType: 'alarm',
        );
        changed = true;
      }

      for (final rawDoneAction in rawDoneActions) {
        final taskId = rawDoneAction as String?;
        if (taskId == null) continue;

        final index = updatedTasks.indexWhere((task) => task.id == taskId);
        if (index == -1) continue;

        if (!updatedTasks[index].isDone) {
          updatedTasks[index] = updatedTasks[index].copyWith(isDone: true);
          changed = true;
        }
      }

      if (!changed) {
        await _nativeAlarmChannel.invokeMethod<void>('clearPendingSnoozeActions');
        await _nativeAlarmChannel.invokeMethod<void>('clearPendingDoneActions');
        return false;
      }

      final saveResult = await saveTasks(updatedTasks);
      if (saveResult.isLeft()) return false;

      await _nativeAlarmChannel.invokeMethod<void>('clearPendingSnoozeActions');
      await _nativeAlarmChannel.invokeMethod<void>('clearPendingDoneActions');
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Alarm ID helpers ───

  /// Converts a task ID string to a valid alarm package integer ID.
  /// The alarm package requires id != 0, != -1, and within 32-bit int range.
  int _alarmIdFor(String taskId) {
    final hash = taskId.hashCode.abs();
    // Ensure non-zero and within 32-bit positive range
    final id = hash == 0 ? 1 : hash % 2147483647;
    return id == 0 ? 1 : id;
  }

  // ─── Android 14+ full-screen intent permission ───

  static const _permChannel = MethodChannel('dayflow/permissions');

  /// Returns true if the app can use full-screen intents (always true pre-Android 14).
  Future<bool> canUseFullScreenIntent() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final result = await _permChannel.invokeMethod<bool>('canUseFullScreenIntent');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Opens the Android settings page where the user can grant full-screen intent permission.
  Future<void> openFullScreenIntentSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _permChannel.invokeMethod('openFullScreenIntentSettings');
    } catch (_) {}
  }

  // ─── Helpers ───

  DateTime? _combineDateAndTime(DateTime date, String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
