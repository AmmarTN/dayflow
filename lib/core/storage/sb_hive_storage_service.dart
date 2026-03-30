import 'package:dayflow/infrastructure/constants/storage_contants.dart';
import 'package:hive_flutter/hive_flutter.dart';


import 'storage_service.dart';

class MainHiveStorageService implements StorageService {
  /// A Hive Box
  late Box hiveBox;

  /// Opens a Hive box by its name
  Future<void> openBox({required String boxName}) async {
    hiveBox = await Hive.openBox<dynamic>(boxName);
  }

  @override
  Future<void> init() async {
    await openBox(boxName: StorageConstants.dayflowHiveBox);
  }

  @override
  Future<void> remove(String key) async {
    await hiveBox.delete(key);
  }

  @override
  dynamic get(String key) {
    return hiveBox.get(key);
  }

  @override
  dynamic getAll() {
    return hiveBox.values.toList();
  }

  @override
  bool has(String key) {
    return hiveBox.containsKey(key);
  }

  @override
  Future<void> set(String? key, dynamic data) async {
    await hiveBox.put(key, data);
  }

  @override
  Future<void> clear() async {
    await hiveBox.clear();
  }

  @override
  Future<void> close() async {
    await hiveBox.close();
  }
}
