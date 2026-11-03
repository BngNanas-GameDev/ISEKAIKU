import 'dart:convert';

import 'library_store.dart';
import 'models/library_models.dart';

/// Hasil impor: jumlah data setelah penggabungan.
class ImportSummary {
  const ImportSummary({
    required this.followed,
    required this.history,
    required this.readChapters,
  });

  final int followed;
  final int history;
  final int readChapters;
}

/// Backup Pustaka dalam satu dokumen JSON.
///
/// Impor bersifat **menggabungkan**, bukan menimpa:
/// - manga diikuti: digabung per id, tanggal terbaru menang
/// - riwayat: satu entri per manga, `readAt` terbaru menang
/// - chapter terbaca: gabungan (union)
///
/// Jadi impor berulang aman dan tidak menduplikasi data.
class LibraryBackup {
  const LibraryBackup({
    required this.followed,
    required this.history,
    required this.readChapters,
  });

  static const String appId = 'isekaiku';
  static const int version = 1;

  final List<FollowedManga> followed;
  final List<ReadingHistoryEntry> history;
  final Map<String, Set<String>> readChapters;

  String encode() {
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'app': appId,
      'version': version,
      'exportedAt': DateTime.now().toIso8601String(),
      'followed': followed.map((e) => e.toJson()).toList(),
      'history': history.map((e) => e.toJson()).toList(),
      'readChapters': <String, dynamic>{
        for (final entry in readChapters.entries)
          entry.key: entry.value.toList(),
      },
    });
  }

  /// `null` bila teks bukan backup Isekaiku yang valid.
  static LibraryBackup? decode(String raw) {
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['app'] != appId) return null;

      final followed = <FollowedManga>[];
      for (final item in (decoded['followed'] as List<dynamic>? ?? [])) {
        if (item is Map<String, dynamic>) {
          final parsed = FollowedManga.tryFromJson(item);
          if (parsed != null) followed.add(parsed);
        }
      }

      final history = <ReadingHistoryEntry>[];
      for (final item in (decoded['history'] as List<dynamic>? ?? [])) {
        if (item is Map<String, dynamic>) {
          final parsed = ReadingHistoryEntry.tryFromJson(item);
          if (parsed != null) history.add(parsed);
        }
      }

      final readChapters = <String, Set<String>>{};
      final rawRead = decoded['readChapters'];
      if (rawRead is Map<String, dynamic>) {
        rawRead.forEach((String mangaId, dynamic value) {
          if (value is List) {
            readChapters[mangaId] = value.whereType<String>().toSet();
          }
        });
      }

      return LibraryBackup(
        followed: followed,
        history: history,
        readChapters: readChapters,
      );
    } on FormatException {
      return null;
    }
  }

  static List<FollowedManga> mergeFollowed(
    List<FollowedManga> current,
    List<FollowedManga> incoming,
  ) {
    final map = <String, FollowedManga>{};
    for (final item in <FollowedManga>[...current, ...incoming]) {
      final existing = map[item.id];
      if (existing == null || item.followedAt.isAfter(existing.followedAt)) {
        map[item.id] = item;
      }
    }
    final result = map.values.toList()
      ..sort((a, b) => b.followedAt.compareTo(a.followedAt));
    return result;
  }

  static List<ReadingHistoryEntry> mergeHistory(
    List<ReadingHistoryEntry> current,
    List<ReadingHistoryEntry> incoming,
  ) {
    final map = <String, ReadingHistoryEntry>{};
    for (final item in <ReadingHistoryEntry>[...current, ...incoming]) {
      final existing = map[item.mangaId];
      if (existing == null || item.readAt.isAfter(existing.readAt)) {
        map[item.mangaId] = item;
      }
    }
    final result = map.values.toList()
      ..sort((a, b) => b.readAt.compareTo(a.readAt));
    if (result.length > LibraryStore.historyLimit) {
      return result.sublist(0, LibraryStore.historyLimit);
    }
    return result;
  }

  static Map<String, Set<String>> mergeReadChapters(
    Map<String, Set<String>> current,
    Map<String, Set<String>> incoming,
  ) {
    final result = <String, Set<String>>{
      for (final entry in current.entries)
        entry.key: <String>{...entry.value},
    };
    incoming.forEach((String mangaId, Set<String> chapters) {
      result[mangaId] = <String>{...?result[mangaId], ...chapters};
    });
    return result;
  }
}

/// Layanan ekspor/impor yang menulis langsung ke penyimpanan lokal.
class LibraryBackupService {
  LibraryBackupService(this._store);

  final LibraryStore _store;

  LibraryBackup export() {
    return LibraryBackup(
      followed: _store.loadFollowed(),
      history: _store.loadHistory(),
      readChapters: _store.loadReadChapters(),
    );
  }

  /// Menggabungkan [raw] ke data saat ini.
  ///
  /// Melempar [FormatException] bila teks bukan backup valid.
  Future<ImportSummary> import(String raw) async {
    final parsed = LibraryBackup.decode(raw);
    if (parsed == null) {
      throw const FormatException(
        'Teks bukan backup Isekaiku yang valid.',
      );
    }

    final followed = LibraryBackup.mergeFollowed(
      _store.loadFollowed(),
      parsed.followed,
    );
    final history = LibraryBackup.mergeHistory(
      _store.loadHistory(),
      parsed.history,
    );
    final readChapters = LibraryBackup.mergeReadChapters(
      _store.loadReadChapters(),
      parsed.readChapters,
    );

    await _store.saveFollowed(followed);
    await _store.saveHistory(history);
    await _store.saveReadChapters(readChapters);

    // Penyimpanan lain (mis. key availability) tidak tersentuh.
    return ImportSummary(
      followed: followed.length,
      history: history.length,
      readChapters: readChapters.length,
    );
  }
}
