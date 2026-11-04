import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_providers.dart';
import '../../core/storage/storage_service.dart';
import 'legal_content.dart';

/// Versi syarat & kebijakan yang terakhir disetujui.
const String legalAcceptedVersionKey = 'legal.acceptedVersion';

class LegalAcceptanceNotifier extends StateNotifier<bool> {
  LegalAcceptanceNotifier(this._storage) : super(_isAccepted(_storage));

  final StorageService _storage;

  static bool _isAccepted(StorageService storage) {
    return storage.getString(legalAcceptedVersionKey) == LegalContent.version;
  }

  void accept() {
    _storage.setString(legalAcceptedVersionKey, LegalContent.version);
    state = true;
  }

  /// Dipakai saat pengujian atau bila pengguna ingin menyetujui ulang.
  void reset() {
    _storage.remove(legalAcceptedVersionKey);
    state = false;
  }
}

/// True bila pengguna sudah menyetujui versi syarat/kebijakan terbaru.
final legalAcceptedProvider =
    StateNotifierProvider<LegalAcceptanceNotifier, bool>((ref) {
      return LegalAcceptanceNotifier(ref.watch(storageServiceProvider));
    });

/// True bila masih harus menampilkan halaman persetujuan.
final needsLegalAcceptanceProvider = Provider<bool>((ref) {
  return !ref.watch(legalAcceptedProvider);
});
