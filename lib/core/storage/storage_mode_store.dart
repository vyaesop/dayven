import 'package:shared_preferences/shared_preferences.dart';

import 'storage_mode.dart';

class StorageModeStore {
  static const _storageModeKey = 'storage_mode';

  Future<StorageMode?> readMode() async {
    final preferences = await SharedPreferences.getInstance();
    return storageModeFromValue(preferences.getString(_storageModeKey));
  }

  Future<void> writeMode(StorageMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageModeKey, mode.persistedValue);
  }

  Future<void> clearMode() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageModeKey);
  }
}
