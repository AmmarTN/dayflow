import 'package:dartz/dartz.dart';
import 'package:dayflow/core/erros/failures.dart';
import 'package:dayflow/core/usecases/usecase.dart';
import 'package:dayflow/infrastructure/models/tasks/task_model.dart';
import 'package:dayflow/infrastructure/repositories/tasks_repository_impl.dart';
import 'package:injectable/injectable.dart';

@singleton
class SaveTasks extends Usecase<Unit, List<TaskModel>> {
  final ITasksRepository _repository;

  SaveTasks(this._repository);

  @override
  Future<Either<Failure, Unit>> call(List<TaskModel> params) {
    return _repository.saveTasks(params);
  }
}
