enum StorageMode {
  localSqlite,
  cloudSync,
}

extension StorageModeX on StorageMode {
  String get persistedValue {
    switch (this) {
      case StorageMode.localSqlite:
        return 'local_sqlite';
      case StorageMode.cloudSync:
        return 'cloud_sync';
    }
  }

  String get label {
    switch (this) {
      case StorageMode.localSqlite:
        return 'On This Device';
      case StorageMode.cloudSync:
        return 'Sync Across Devices';
    }
  }

  String get description {
    switch (this) {
      case StorageMode.localSqlite:
        return 'Store everything locally in SQLite on this phone.';
      case StorageMode.cloudSync:
        return 'Use the Neon-backed API so your planner can sync later.';
    }
  }
}

StorageMode? storageModeFromValue(String? value) {
  switch (value) {
    case 'local_sqlite':
      return StorageMode.localSqlite;
    case 'cloud_sync':
      return StorageMode.cloudSync;
    default:
      return null;
  }
}
