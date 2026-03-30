import 'package:dartz/dartz.dart';
import 'package:dayflow/core/erros/failures.dart';
import 'package:dayflow/core/storage/sb_hive_storage_service.dart';
import 'package:dayflow/infrastructure/constants/storage_contants.dart';
import 'package:dayflow/presentation/common/cubit/language/language_cubit.dart';
import 'package:injectable/injectable.dart';


abstract class CommonLocalDataSource {
  Either<Failure, LocaleLanguage?> getCachedLanguage();
  Either<Failure, Unit> cacheLanguage(LocaleLanguage localeLanguage);
}

@Singleton(as: CommonLocalDataSource)
class CommonLocalDataSourceImpl implements CommonLocalDataSource {
  final MainHiveStorageService storage;

  CommonLocalDataSourceImpl(this.storage);

  @override
  Either<Failure, LocaleLanguage?> getCachedLanguage() {
    try {
      final String? langCode = storage.get(StorageConstants.localeLanguage);
      if (langCode is String) {
        return Right(langCode == LocaleLanguage.ar.name
            ? LocaleLanguage.ar
            : LocaleLanguage.en);
      }
      return const Right(null);
    } catch (e) {
      return const Left(Failure.cacheReadFailure());
    }
  }

  @override
  Either<Failure, Unit> cacheLanguage(LocaleLanguage localeLanguage) {
    try {
      storage.set(StorageConstants.localeLanguage, localeLanguage.name);
      return const Right(unit);
    } catch (e) {
      return const Left(Failure.cacheWriteFailure());
    }
  }
}
