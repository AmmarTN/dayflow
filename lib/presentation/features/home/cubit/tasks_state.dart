import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dayflow/infrastructure/models/general/cubitStatus.dart';
import 'package:dayflow/infrastructure/models/tasks/task_model.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';

part 'tasks_state.freezed.dart';

enum TemporalState { today, past, future }

extension TemporalStateColors on TemporalState {
  Color get accent {
    switch (this) {
      case TemporalState.today:
        return AppColors.accentGreen;
      case TemporalState.past:
        return AppColors.accentBlue;
      case TemporalState.future:
        return AppColors.accentOrange;
    }
  }

  Color get glow {
    switch (this) {
      case TemporalState.today:
        return AppColors.accentGreenGlow;
      case TemporalState.past:
        return AppColors.accentBlueGlow;
      case TemporalState.future:
        return AppColors.accentOrangeGlow;
    }
  }
}

@freezed
class TasksState with _$TasksState {
  const TasksState._();

  const factory TasksState({
    @Default(CubitStatus()) CubitStatus status,
    @Default([]) List<TaskModel> tasks,
    DateTime? selectedDate,
  }) = _TasksState;

  DateTime get currentDate => selectedDate ?? DateTime.now();

  DateTime get _todayDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  TemporalState get temporalState {
    final sel = DateTime(currentDate.year, currentDate.month, currentDate.day);
    if (sel == _todayDate) return TemporalState.today;
    return sel.isBefore(_todayDate) ? TemporalState.past : TemporalState.future;
  }

  List<TaskModel> get filteredTasks {
    final date = currentDate;
    return tasks.where((t) {
      return t.createdAt.year == date.year &&
          t.createdAt.month == date.month &&
          t.createdAt.day == date.day;
    }).toList();
  }

  List<TaskModel> get overdueTasks {
    if (temporalState != TemporalState.today) return const [];

    final overdue = tasks
        .where(
          (task) =>
              !task.isDone && _dateOnly(task.createdAt).isBefore(_todayDate),
        )
        .toList();

    overdue.sort((a, b) {
      final dateCompare = _dateOnly(
        b.createdAt,
      ).compareTo(_dateOnly(a.createdAt));
      if (dateCompare != 0) return dateCompare;
      return _compareTime(a, b);
    });

    return overdue;
  }

  List<TaskModel> get upcomingTasks {
    if (temporalState != TemporalState.today) return const [];

    final upcoming = tasks
        .where((task) => _dateOnly(task.createdAt).isAfter(_todayDate))
        .toList();

    upcoming.sort((a, b) {
      final dateCompare = _dateOnly(
        a.createdAt,
      ).compareTo(_dateOnly(b.createdAt));
      if (dateCompare != 0) return dateCompare;
      return _compareTime(a, b);
    });

    return upcoming;
  }

  int get completedCount => filteredTasks.where((t) => t.isDone).length;

  int get pendingCount => filteredTasks.where((t) => !t.isDone).length;

  double get completionRatio {
    final filtered = filteredTasks;
    if (filtered.isEmpty) return 0.0;
    return filtered.where((t) => t.isDone).length / filtered.length;
  }

  static DateTime _dateOnly(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);

  static int _compareTime(TaskModel a, TaskModel b) {
    final aMinutes = _minutesOfDay(a.scheduledTime);
    final bMinutes = _minutesOfDay(b.scheduledTime);

    if (aMinutes == null && bMinutes == null) return 0;
    if (aMinutes == null) return 1;
    if (bMinutes == null) return -1;
    return aMinutes.compareTo(bMinutes);
  }

  static int? _minutesOfDay(String? hhMm) {
    if (hhMm == null) return null;
    final parts = hhMm.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return (hour * 60) + minute;
  }
}
