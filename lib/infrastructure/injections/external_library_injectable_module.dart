import 'package:dayflow/core/storage/sb_hive_storage_service.dart';
import 'package:dayflow/presentation/features/bottom_nav_layout_manager.dart/widgets/BottomNavLayoutResources/page_stack.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@module
abstract class ExternalLibraryInjectableModule {
  @lazySingleton
  ReorderToFrontPageStack get bottomNavPageStack =>
      ReorderToFrontPageStack(initialPage: 0);

  @preResolve
  @lazySingleton
  Future<MainHiveStorageService> get openBox async {
    await Hive.initFlutter();
    final MainHiveStorageService initializedStorageService = MainHiveStorageService();
    await initializedStorageService.init();
    return initializedStorageService;
  }
}
