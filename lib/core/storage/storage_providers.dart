import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'storage_service.dart';

/// Instance [StorageService] yang sudah diinisialisasi.
///
/// Di-override di `main()` lewat `ProviderScope(overrides: ...)`.
final storageServiceProvider = Provider<StorageService>(
  (ref) => throw UnimplementedError(
    'storageServiceProvider harus di-override di ProviderScope.',
  ),
);

/// State bool yang otomatis tersimpan ke penyimpanan lokal.
///
/// Dipakai untuk setting pembaca supaya tidak kembali ke default setiap
/// aplikasi dibuka ulang.
class PersistentBoolNotifier extends StateNotifier<bool> {
  PersistentBoolNotifier(this._storage, this._key, bool initial)
      : super(initial);

  final StorageService _storage;
  final String _key;

  /// Ganti nilai sekaligus simpan. Dipakai dari UI.
  void set(bool value) {
    if (value == state) return;
    state = value;
    _storage.setBool(_key, value);
  }
}

/// State String yang otomatis tersimpan ke penyimpanan lokal.
class PersistentStringNotifier extends StateNotifier<String> {
  PersistentStringNotifier(this._storage, this._key, String initial)
      : super(initial);

  final StorageService _storage;
  final String _key;

  void set(String value) {
    if (value == state) return;
    state = value;
    _storage.setString(_key, value);
  }
}
