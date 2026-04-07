import 'dart:convert';

import 'package:dayflow/infrastructure/constants/storage_contants.dart';
import 'package:dayflow/infrastructure/models/tasks/task_model.dart';
import 'package:dayflow/infrastructure/models/weather/weather_model.dart';
import 'package:dayflow/injection.dart';
import 'package:dayflow/core/storage/sb_hive_storage_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

/// Reads task data from Hive and pushes it into native shared storage so the
/// home screen widget can display up-to-date information.
class WidgetDataSync {
  WidgetDataSync._();

  static const String _androidWidgetName = 'TaskWidgetProvider';
  static const String _iosWidgetName = 'TaskWidget';

  static Future<void> sync({WeatherModel? weatherOverride}) async {
    try {
      final storage = getIt<MainHiveStorageService>();

      // ── Read tasks from Hive ─────────────────────────────────────────────
      final String? raw = storage.get(StorageConstants.tasksKey);
      List<TaskModel> allTasks = [];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        allTasks = decoded
            .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // ── Date helpers ─────────────────────────────────────────────────────
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      DateTime dateOnly(DateTime dt) =>
          DateTime(dt.year, dt.month, dt.day);

      // ── Categorise tasks (mirrors tasks_state.dart logic) ─────────────
      final todayTasks = allTasks.where((t) {
        return dateOnly(t.createdAt) == today;
      }).toList();

      final overdueTasks = allTasks.where((t) {
        return !t.isDone && dateOnly(t.createdAt).isBefore(today);
      }).toList();

      // ── Greeting (mirrors greeting_card.dart) ─────────────────────────
      final hour = now.hour;
      final String greeting;
      if (hour < 12) {
        greeting = 'Good morning';
      } else if (hour < 17) {
        greeting = 'Good afternoon';
      } else {
        greeting = 'Good evening';
      }

      // ── Date label ───────────────────────────────────────────────────────
      final dateLabel = DateFormat('EEEE, MMM d').format(now);

      // ── Task counts ──────────────────────────────────────────────────────
      final totalToday = todayTasks.length;
      final completedToday = todayTasks.where((t) => t.isDone).length;

      // ── Next 3 uncompleted today-tasks ───────────────────────────────────
      final nextThree = todayTasks.where((t) => !t.isDone).take(3).toList();

      final nextTasksJson = jsonEncode(nextThree.map((t) {
        String? alarmDisplay;
        if (t.scheduledTime != null) {
          final parts = t.scheduledTime!.split(':');
          if (parts.length == 2) {
            final h = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            if (h != null && m != null) {
              final dt = DateTime(now.year, now.month, now.day, h, m);
              alarmDisplay = DateFormat('h:mm a').format(dt);
            }
          }
        }
        return {'title': t.title, 'alarm': alarmDisplay};
      }).toList());

      // ── Push all data into native shared storage ──────────────────────
      await HomeWidget.saveWidgetData<String>('greeting', greeting);
      await HomeWidget.saveWidgetData<String>('date_label', dateLabel);
      if (weatherOverride != null) {
        final roundedTemp = weatherOverride.temperature.round();
        await HomeWidget.saveWidgetData<String>(
          'weather_temp',
          '$roundedTemp°',
        );
        await HomeWidget.saveWidgetData<int>(
          'weather_temp_value',
          roundedTemp,
        );
        await HomeWidget.saveWidgetData<int>(
          'weather_code',
          weatherOverride.weatherCode,
        );
        await HomeWidget.saveWidgetData<int>(
          'weather_updated_at',
          DateTime.now().millisecondsSinceEpoch,
        );
      }
      await HomeWidget.saveWidgetData<int>('task_count_today', totalToday);
      await HomeWidget.saveWidgetData<int>(
          'tasks_completed_today', completedToday);
      await HomeWidget.saveWidgetData<String>('next_tasks_json', nextTasksJson);
      await HomeWidget.saveWidgetData<int>(
          'overdue_count', overdueTasks.length);

      // ── Tell the OS to redraw the widget ──────────────────────────────
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iosWidgetName,
      );
    } catch (_) {
      // Widget sync is best-effort — never crash the app.
    }
  }
}
