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

  Map<String, dynamic>? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
