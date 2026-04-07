import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dayflow/core/services/notification_service.dart';
import 'package:dayflow/core/usecases/tasks/get_tasks.dart';
import 'package:dayflow/core/usecases/tasks/save_tasks.dart';
import 'package:dayflow/core/usecases/usecase.dart';
import 'package:dayflow/infrastructure/extensions/failures.dart';
import 'package:dayflow/infrastructure/models/general/cubitStatus.dart';
import 'package:dayflow/infrastructure/models/tasks/task_model.dart';
import 'package:dayflow/services/widget_data_sync.dart';
import 'package:injectable/injectable.dart';
import 'tasks_state.dart';

@injectable
class TasksCubit extends Cubit<TasksState> {
  final GetTasks _getTasks;
  final SaveTasks _saveTasks;
  final NotificationService _notificationService;

  TasksCubit(this._getTasks, this._saveTasks, this._notificationService)
      : super(TasksState(selectedDate: _dateOnly(DateTime.now())));

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  void selectDate(DateTime date) {
    emit(state.copyWith(selectedDate: _dateOnly(date)));
  }

  void loadTasks() {
    emit(state.copyWith(
      status: const CubitStatus(
        statusType: CubitStatusType.loading,
        action: CubitAction.loadTasks,
      ),
    ));

    final result = _getTasks(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: CubitStatus(
          statusType: CubitStatusType.failure,
          action: CubitAction.loadTasks,
          errorMsg: failure.getMessage(),
        ),
      )),
      (tasks) {
        emit(state.copyWith(
          tasks: tasks,
          status: const CubitStatus(
            statusType: CubitStatusType.success,
            action: CubitAction.loadTasks,
          ),
        ));
      },
    );
  }

  Future<void> addTask(
    String title, {
    String? subtitle,
    DateTime? date,
    String? scheduledTime,
    String? reminderType,
  }) async {
    emit(state.copyWith(
      status: const CubitStatus(
        statusType: CubitStatusType.loading,
        action: CubitAction.addTask,
      ),
    ));

    final taskDate = date != null ? _dateOnly(date) : state.currentDate;
    final task = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      subtitle: subtitle,
      createdAt: taskDate,
      scheduledTime: scheduledTime,
      reminderType: reminderType,
    );

    final updatedTasks = [task, ...state.tasks];
    final result = await _saveTasks(updatedTasks);
    result.fold(
      (failure) => emit(state.copyWith(
        status: CubitStatus(
          statusType: CubitStatusType.failure,
          action: CubitAction.addTask,
          errorMsg: failure.getMessage(),
        ),
      )),
      (_) {
        _scheduleForTask(task);
        emit(state.copyWith(
          tasks: updatedTasks,
          status: const CubitStatus(
            statusType: CubitStatusType.success,
            action: CubitAction.addTask,
          ),
        ));
        WidgetDataSync.sync();
      },
    );
  }

  Future<void> toggleTask(String id) async {
    final task = state.tasks.firstWhere((t) => t.id == id);
    final markingDone = !task.isDone;

    if (markingDone && task.scheduledTime != null) {
      await _notificationService.cancelNotification(id);
    }

    emit(state.copyWith(
      status: const CubitStatus(
        statusType: CubitStatusType.loading,
        action: CubitAction.toggleTask,
      ),
    ));

    final updatedTasks = state.tasks.map((t) {
      if (t.id == id) return t.copyWith(isDone: !t.isDone);
      return t;
    }).toList();

    final result = await _saveTasks(updatedTasks);
    result.fold(
      (failure) => emit(state.copyWith(
        status: CubitStatus(
          statusType: CubitStatusType.failure,
          action: CubitAction.toggleTask,
          errorMsg: failure.getMessage(),
        ),
      )),
      (_) {
        emit(state.copyWith(
          tasks: updatedTasks,
          status: const CubitStatus(
            statusType: CubitStatusType.success,
            action: CubitAction.toggleTask,
          ),
        ));
        WidgetDataSync.sync();
      },
    );
  }

  Future<void> deleteTask(String id) async {
    await _notificationService.cancelNotification(id);

    emit(state.copyWith(
      status: const CubitStatus(
        statusType: CubitStatusType.loading,
        action: CubitAction.deleteTask,
      ),
    ));

    final updatedTasks = state.tasks.where((t) => t.id != id).toList();
    final result = await _saveTasks(updatedTasks);
    result.fold(
      (failure) => emit(state.copyWith(
        status: CubitStatus(
          statusType: CubitStatusType.failure,
          action: CubitAction.deleteTask,
          errorMsg: failure.getMessage(),
        ),
      )),
      (_) {
        emit(state.copyWith(
          tasks: updatedTasks,
          status: const CubitStatus(
            statusType: CubitStatusType.success,
            action: CubitAction.deleteTask,
          ),
        ));
        WidgetDataSync.sync();
      },
    );
  }

  Future<void> rescheduleTask(String id, DateTime newTime) async {
    await _notificationService.cancelNotification(id);

    final updatedTasks = state.tasks.map((t) {
      if (t.id == id) {
        final h = newTime.hour.toString().padLeft(2, '0');
        final m = newTime.minute.toString().padLeft(2, '0');
        return t.copyWith(
          createdAt: _dateOnly(newTime),
          scheduledTime: '$h:$m',
        );
      }
      return t;
    }).toList();

    final result = await _saveTasks(updatedTasks);
    result.fold(
      (failure) => null,
      (_) {
        final updated = updatedTasks.firstWhere((t) => t.id == id);
        _scheduleForTask(updated);
        emit(state.copyWith(
          tasks: updatedTasks,
          status: const CubitStatus(
            statusType: CubitStatusType.success,
            action: CubitAction.toggleTask,
          ),
        ));
        WidgetDataSync.sync();
      },
    );
  }

  void _scheduleForTask(TaskModel task) {
    if (task.scheduledTime == null || task.reminderType == null) return;
    if (task.reminderType == 'alarm') {
      _notificationService.scheduleAlarm(task);
    } else {
      _notificationService.scheduleNotification(task);
    }
  }
}
