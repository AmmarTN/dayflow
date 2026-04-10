import 'package:equatable/equatable.dart';

enum CubitStatusType { idle, loading, success, failure }

enum CubitAction {
  none,
  loadTasks,
  addTask,
  updateTask,
  toggleTask,
  deleteTask,
}

class CubitStatus extends Equatable {
  final CubitStatusType statusType;
  final CubitAction? action;
  final String? errorMsg;
  final Map<String, dynamic>? args;
  const CubitStatus({
    this.args,
    this.action = CubitAction.none,
    this.statusType = CubitStatusType.idle,
    this.errorMsg,
  });

  @override
  List<Object?> get props => [statusType, action, errorMsg, args];
}
