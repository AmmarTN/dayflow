import 'package:dartz/dartz.dart';
import 'package:dayflow/core/erros/failures.dart';
import 'package:dayflow/core/usecases/usecase.dart';
import 'package:dayflow/infrastructure/models/tasks/task_model.dart';
import 'package:dayflow/infrastructure/repositories/tasks_repository_impl.dart';
import 'package:injectable/injectable.dart';

@singleton
class GetTasks extends UnawaitedUsecase<List<TaskModel>, NoParams> {
  final ITasksRepository _repository;

  GetTasks(this._repository);

  @override
  Either<Failure, List<TaskModel>> call(NoParams params) {
    return _repository.getTasks();
  }
}
