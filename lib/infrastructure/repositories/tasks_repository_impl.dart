import 'package:dartz/dartz.dart';
import 'package:dayflow/core/erros/failures.dart';
import 'package:dayflow/infrastructure/datasources/local_datasources/tasks_local_data_source.dart';
import 'package:dayflow/infrastructure/models/tasks/task_model.dart';
import 'package:injectable/injectable.dart';

abstract class ITasksRepository {
  Either<Failure, List<TaskModel>> getTasks();
  Future<Either<Failure, Unit>> saveTasks(List<TaskModel> tasks);
}

@Singleton(as: ITasksRepository)
class TasksRepositoryImpl implements ITasksRepository {
  final ITasksLocalDataSource _localDataSource;

  TasksRepositoryImpl(this._localDataSource);

  @override
  Either<Failure, List<TaskModel>> getTasks() {
    return _localDataSource.getTasks();
  }

  @override
  Future<Either<Failure, Unit>> saveTasks(List<TaskModel> tasks) {
    return _localDataSource.saveTasks(tasks);
  }
}
