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

  TemporalState get temporalState {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel = DateTime(currentDate.year, currentDate.month, currentDate.day);
    if (sel == today) return TemporalState.today;
    return sel.isBefore(today) ? TemporalState.past : TemporalState.future;
  }

  List<TaskModel> get filteredTasks {
    final date = currentDate;
    return tasks.where((t) {
      return t.createdAt.year == date.year &&
          t.createdAt.month == date.month &&
          t.createdAt.day == date.day;
    }).toList();
  }

  int get completedCount => filteredTasks.where((t) => t.isDone).length;

  int get pendingCount => filteredTasks.where((t) => !t.isDone).length;

  double get completionRatio {
    final filtered = filteredTasks;
    if (filtered.isEmpty) return 0.0;
    return filtered.where((t) => t.isDone).length / filtered.length;
  }
}
