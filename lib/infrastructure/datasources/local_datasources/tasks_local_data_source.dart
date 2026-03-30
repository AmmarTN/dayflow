import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dayflow/core/erros/failures.dart';
import 'package:dayflow/core/storage/sb_hive_storage_service.dart';
import 'package:dayflow/infrastructure/constants/storage_contants.dart';
import 'package:dayflow/infrastructure/models/tasks/task_model.dart';
import 'package:injectable/injectable.dart';

abstract class ITasksLocalDataSource {
  Either<Failure, List<TaskModel>> getTasks();
  Future<Either<Failure, Unit>> saveTasks(List<TaskModel> tasks);
}

@Singleton(as: ITasksLocalDataSource)
class TasksLocalDataSourceImpl implements ITasksLocalDataSource {
  final MainHiveStorageService _storage;

  TasksLocalDataSourceImpl(this._storage);

  @override
  Either<Failure, List<TaskModel>> getTasks() {
    try {
      final String? raw = _storage.get(StorageConstants.tasksKey);
      if (raw == null || raw.isEmpty) {
        return const Right([]);
      }
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final tasks = decoded
          .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(tasks);
    } catch (e) {
      return const Left(Failure.cacheReadFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> saveTasks(List<TaskModel> tasks) async {
    try {
      final encoded = jsonEncode(tasks.map((t) => t.toJson()).toList());
      await _storage.set(StorageConstants.tasksKey, encoded);
      return const Right(unit);
    } catch (e) {
      return const Left(Failure.cacheWriteFailure());
    }
  }
}
