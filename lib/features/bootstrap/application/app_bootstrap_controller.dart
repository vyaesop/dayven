import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_mode.dart';
import '../../../core/storage/storage_mode_store.dart';

final storageModeStoreProvider = Provider<StorageModeStore>((ref) {
  return StorageModeStore();
});

final selectedStorageModeProvider =
    AsyncNotifierProvider<SelectedStorageModeController, StorageMode?>(
  SelectedStorageModeController.new,
);

class SelectedStorageModeController extends AsyncNotifier<StorageMode?> {
  StorageModeStore get _store => ref.read(storageModeStoreProvider);

  @override
  Future<StorageMode?> build() {
    return _store.readMode();
  }

  Future<void> choose(StorageMode mode) async {
    state = const AsyncLoading();
    await _store.writeMode(mode);
    state = AsyncData(mode);
  }

  Future<void> reset() async {
    state = const AsyncLoading();
    await _store.clearMode();
    state = const AsyncData(null);
  }
}
