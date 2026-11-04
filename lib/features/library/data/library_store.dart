import 'dart:convert';

import '../../../core/storage/storage_service.dart';
import 'models/library_models.dart';

/// Baca/tulis data Pustaka ke penyimpanan lokal.
///
/// Data dipisah per akun (`scope` = id pengguna Supabase, atau `guest` bila
/// belum login), supaya riwayat tidak terbawa saat berganti akun.
///
/// Format: `SharedPreferences` string list, satu elemen = satu JSON objek.
/// Dekode bersifat toleran — entri rusak dilewati, bukan membuat app crash.
class LibraryStore {
  LibraryStore(this._storage, {this.scope = guestScope});

  final StorageService _storage;

  /// Scope untuk pengguna tanpa akun.
  static const String guestScope = 'guest';

  /// Id akun pemilik data (id Supabase atau [guestScope]).
  final String scope;

  static String _keyFor(String scope, String name) => 'library.$name.$scope';

  static String followedKeyFor(String scope) => _keyFor(scope, 'followed');
  static String historyKeyFor(String scope) => _keyFor(scope, 'history');

  String get followedKey => _keyFor(scope, 'followed');
  String get historyKey => _keyFor(scope, 'history');
  String get readChaptersKey => _keyFor(scope, 'readChapters');

  /// Catatan penghapusan agar sinkronisasi tidak menghidupkan data lagi.
  String get deletedFollowedKey => _keyFor(scope, 'deletedFollowed');
  String get deletedHistoryKey => _keyFor(scope, 'deletedHistory');

  // --- migrasi data versi lama (sebelum data dipisah per akun) -----------
  static const String legacyFollowedKey = 'library.followed';
  static const String legacyHistoryKey = 'library.history';
  static const String legacyReadChaptersKey = 'library.readChapters';
  static const String legacyDeletedFollowedKey = 'library.deletedFollowed';
  static const String legacyDeletedHistoryKey = 'library.deletedHistory';
  static const String legacyClaimedKey = 'library.legacyClaimed';

  /// Pindahkan data lama ke [scope] akun, sekali saja.
  ///
  /// Dipanggil saat toko untuk akun pertama kali dibuat. Data lama tidak
  /// pernah dipakai oleh scope lain, jadi tidak bocor antar akun.
  ///
  /// [allowGuest] hanya dipakai saat startup setelah dipastikan tidak ada
  /// sesi login, supaya pengguna tanpa akun tetap melihat riwayat lamanya.
  static void claimLegacy(
    StorageService storage,
    String scope, {
    bool allowGuest = false,
  }) {
    if (scope == guestScope && !allowGuest) return;
    if (storage.getBool(legacyClaimedKey, fallback: false)) return;

    // Tandai lebih dulu (cache SharedPreferences sinkron).
    storage.setBool(legacyClaimedKey, true);

    final target = LibraryStore(storage, scope: scope);
    _copyList(storage, legacyFollowedKey, target.followedKey);
    _copyList(storage, legacyHistoryKey, target.historyKey);
    _copyString(storage, legacyReadChaptersKey, target.readChaptersKey);
    _copyString(storage, legacyDeletedFollowedKey, target.deletedFollowedKey);
    _copyString(storage, legacyDeletedHistoryKey, target.deletedHistoryKey);
  }

  static void _copyList(StorageService storage, String from, String to) {
    final values = storage.getStringList(from);
    if (values.isNotEmpty && storage.getStringList(to).isEmpty) {
      storage.setStringList(to, values);
    }
    storage.remove(from);
  }

  static void _copyString(StorageService storage, String from, String to) {
    final value = storage.getString(from);
    if (value.isNotEmpty && storage.getString(to).isEmpty) {
      storage.setString(to, value);
    }
    storage.remove(from);
  }

  /// Batas riwayat agar tidak tumbuh tanpa henti.
  static const int historyLimit = 100;

  List<FollowedManga> loadFollowed() {
    final result = <FollowedManga>[];
    for (final raw in _storage.getStringList(followedKey)) {
      final parsed = _decode(raw);
      if (parsed == null) continue;
      final item = FollowedManga.tryFromJson(parsed);
      if (item != null) result.add(item);
    }
    result.sort((a, b) => b.followedAt.compareTo(a.followedAt));
    return result;
  }

  Future<void> saveFollowed(List<FollowedManga> items) {
    return _storage.setStringList(
      followedKey,
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  List<ReadingHistoryEntry> loadHistory() {
    final result = <ReadingHistoryEntry>[];
    for (final raw in _storage.getStringList(historyKey)) {
      final parsed = _decode(raw);
      if (parsed == null) continue;
      final entry = ReadingHistoryEntry.tryFromJson(parsed);
      if (entry != null) result.add(entry);
    }
    result.sort((a, b) => b.readAt.compareTo(a.readAt));
    return result;
  }

  Future<void> saveHistory(List<ReadingHistoryEntry> items) {
    return _storage.setStringList(
      historyKey,
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  /// Chapter yang sudah pernah dibuka, per manga.
  Map<String, Set<String>> loadReadChapters() {
    final String raw = _storage.getString(readChaptersKey);
    if (raw.isEmpty) return <String, Set<String>>{};
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return <String, Set<String>>{};
      final result = <String, Set<String>>{};
      decoded.forEach((String mangaId, dynamic value) {
        if (value is List) {
          result[mangaId] = value.whereType<String>().toSet();
        }
      });
      return result;
    } on FormatException {
      return <String, Set<String>>{};
    }
  }

  Future<void> saveReadChapters(Map<String, Set<String>> map) {
    final encoded = <String, dynamic>{
      for (final entry in map.entries) entry.key: entry.value.toList(),
    };
    return _storage.setString(readChaptersKey, jsonEncode(encoded));
  }

  /// Hapus seluruh data lokal scope ini (dipakai saat hapus akun).
  Future<void> clearAll() async {
    await _storage.remove(followedKey);
    await _storage.remove(historyKey);
    await _storage.remove(readChaptersKey);
    await _storage.remove(deletedFollowedKey);
    await _storage.remove(deletedHistoryKey);
  }

  // --- tombstone (penghapusan) -------------------------------------------

  /// Waktu penghapusan per manga, untuk [deletedFollowedKey]/[deletedHistoryKey].
  Map<String, DateTime> _loadDeletes(String key) {
    final raw = _storage.getString(key);
    if (raw.isEmpty) return <String, DateTime>{};
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return <String, DateTime>{};
      final result = <String, DateTime>{};
      decoded.forEach((String id, dynamic value) {
        final parsed = DateTime.tryParse(value?.toString() ?? '');
        if (parsed != null) result[id] = parsed;
      });
      return result;
    } on FormatException {
      return <String, DateTime>{};
    }
  }

  Future<void> _saveDeletes(String key, Map<String, DateTime> map) {
    return _storage.setString(
      key,
      jsonEncode(<String, String>{
        for (final entry in map.entries)
          entry.key: entry.value.toUtc().toIso8601String(),
      }),
    );
  }

  Map<String, DateTime> loadDeletedFollowed() =>
      _loadDeletes(deletedFollowedKey);

  Future<void> recordDeletedFollowed(String mangaId) {
    final map = loadDeletedFollowed()..[mangaId] = DateTime.now();
    return _saveDeletes(deletedFollowedKey, map);
  }

  Future<void> clearDeletedFollowed() =>
      _saveDeletes(deletedFollowedKey, <String, DateTime>{});

  /// Hapus sebagian tombstone (yang sudah dipastikan hilang di server).
  Future<void> forgetDeletedFollowed(Iterable<String> mangaIds) {
    final map = loadDeletedFollowed();
    for (final id in mangaIds) {
      map.remove(id);
    }
    return _saveDeletes(deletedFollowedKey, map);
  }

  Map<String, DateTime> loadDeletedHistory() => _loadDeletes(deletedHistoryKey);

  Future<void> recordDeletedHistory(String mangaId) {
    final map = loadDeletedHistory()..[mangaId] = DateTime.now();
    return _saveDeletes(deletedHistoryKey, map);
  }

  Future<void> clearDeletedHistory() =>
      _saveDeletes(deletedHistoryKey, <String, DateTime>{});

  /// Hapus sebagian tombstone riwayat yang sudah dipastikan hilang di server.
  Future<void> forgetDeletedHistory(Iterable<String> mangaIds) {
    final map = loadDeletedHistory();
    for (final id in mangaIds) {
      map.remove(id);
    }
    return _saveDeletes(deletedHistoryKey, map);
  }

  Map<String, dynamic>? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
