import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dayflow/core/usecases/tasks/get_tasks.dart';
import 'package:dayflow/core/usecases/tasks/save_tasks.dart';
import 'package:dayflow/core/usecases/usecase.dart';
import 'package:dayflow/infrastructure/extensions/failures.dart';
import 'package:dayflow/infrastructure/models/general/cubitStatus.dart';
import 'package:dayflow/infrastructure/models/tasks/task_model.dart';
import 'package:injectable/injectable.dart';
import 'tasks_state.dart';

@injectable
class TasksCubit extends Cubit<TasksState> {
  final GetTasks _getTasks;
  final SaveTasks _saveTasks;

  TasksCubit(this._getTasks, this._saveTasks)
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
      (tasks) => emit(state.copyWith(
        tasks: tasks,
        status: const CubitStatus(
          statusType: CubitStatusType.success,
          action: CubitAction.loadTasks,
        ),
      )),
    );
  }

  Future<void> addTask(String title, {String? subtitle, DateTime? date, String? scheduledTime}) async {
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
      (_) => emit(state.copyWith(
        tasks: updatedTasks,
        status: const CubitStatus(
          statusType: CubitStatusType.success,
          action: CubitAction.addTask,
        ),
      )),
    );
  }

  Future<void> toggleTask(String id) async {
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
      (_) => emit(state.copyWith(
        tasks: updatedTasks,
        status: const CubitStatus(
          statusType: CubitStatusType.success,
          action: CubitAction.toggleTask,
        ),
      )),
    );
  }

  Future<void> deleteTask(String id) async {
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
      (_) => emit(state.copyWith(
        tasks: updatedTasks,
        status: const CubitStatus(
          statusType: CubitStatusType.success,
          action: CubitAction.deleteTask,
        ),
      )),
    );
  }
}
