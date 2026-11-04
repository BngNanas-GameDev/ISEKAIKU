import 'dart:convert';

import '../../../core/storage/storage_service.dart';
import 'models/library_models.dart';

/// Baca/tulis data Pustaka ke penyimpanan lokal.
///
/// Format: `SharedPreferences` string list, satu elemen = satu JSON objek.
/// Dekode bersifat toleran — entri rusak dilewati, bukan membuat app crash.
class LibraryStore {
  LibraryStore(this._storage);

  final StorageService _storage;

  static const String followedKey = 'library.followed';
  static const String historyKey = 'library.history';
  static const String readChaptersKey = 'library.readChapters';

  /// Catatan penghapusan agar sinkronisasi tidak menghidupkan data lagi.
  static const String deletedFollowedKey = 'library.deletedFollowed';
  static const String deletedHistoryKey = 'library.deletedHistory';

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

  Map<String, DateTime> loadDeletedFollowed() => _loadDeletes(deletedFollowedKey);

  Future<void> recordDeletedFollowed(String mangaId) {
    final map = loadDeletedFollowed()..[mangaId] = DateTime.now();
    return _saveDeletes(deletedFollowedKey, map);
  }

  Future<void> clearDeletedFollowed() =>
      _saveDeletes(deletedFollowedKey, <String, DateTime>{});

  Map<String, DateTime> loadDeletedHistory() => _loadDeletes(deletedHistoryKey);

  Future<void> recordDeletedHistory(String mangaId) {
    final map = loadDeletedHistory()..[mangaId] = DateTime.now();
    return _saveDeletes(deletedHistoryKey, map);
  }

  Future<void> clearDeletedHistory() =>
      _saveDeletes(deletedHistoryKey, <String, DateTime>{});

  Map<String, dynamic>? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
