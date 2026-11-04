import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/sync/remote_library.dart';
import 'package:isekaiku/features/library/data/models/library_models.dart';

void main() {
  const userId = 'user-1';

  group('followed', () {
    test('row memuat kolom yang dibutuhkan Supabase', () {
      final row = RemoteMapping.followedRow(
        userId,
        FollowedManga(
          id: 'm1',
          title: 'Judul',
          coverUrl: 'https://x/c.jpg',
          author: 'Penulis',
          followedAt: DateTime.utc(2026, 5, 1, 10, 30),
        ),
      );

      expect(row['user_id'], userId);
      expect(row['manga_id'], 'm1');
      expect(row['title'], 'Judul');
      expect(row['cover_url'], 'https://x/c.jpg');
      expect(row['author'], 'Penulis');
      expect(row['followed_at'], '2026-05-01T10:30:00.000Z');
      expect(row['updated_at'], isA<String>());
    });

    test('fromRow mengembalikan model yang setara', () {
      final original = FollowedManga(
        id: 'm1',
        title: 'Judul',
        author: 'Penulis',
        followedAt: DateTime.utc(2026, 5, 1, 10, 30),
      );

      final restored =
          RemoteMapping.followedFromRow(RemoteMapping.followedRow(userId, original));

      expect(restored, isNotNull);
      expect(restored!.id, 'm1');
      expect(restored.title, 'Judul');
      expect(restored.followedAt.toUtc(), original.followedAt);
    });

    test('row tidak lengkap ditolak', () {
      expect(RemoteMapping.followedFromRow(<String, dynamic>{}), isNull);
      expect(
        RemoteMapping.followedFromRow(<String, dynamic>{'manga_id': 'x'}),
        isNull,
      );
    });
  });

  group('progress', () {
    test('row memetakan posisi halaman', () {
      final row = RemoteMapping.progressRow(
        userId,
        ReadingHistoryEntry(
          mangaId: 'm1',
          mangaTitle: 'Judul',
          chapterId: 'c9',
          chapterNumber: '9',
          page: 12,
          totalPages: 40,
          readAt: DateTime.utc(2026, 5, 2, 8),
        ),
      );

      expect(row['chapter_id'], 'c9');
      expect(row['chapter_number'], '9');
      expect(row['page'], 12);
      expect(row['total_pages'], 40);
      expect(row['read_at'], '2026-05-02T08:00:00.000Z');
    });

    test('fromRow mengembalikan posisi dan label', () {
      final restored = RemoteMapping.progressFromRow(<String, dynamic>{
        'manga_id': 'm1',
        'manga_title': 'Judul',
        'chapter_id': 'c9',
        'chapter_number': '9',
        'page': 12,
        'total_pages': 40,
        'read_at': '2026-05-02T08:00:00.000Z',
      });

      expect(restored, isNotNull);
      expect(restored!.page, 12);
      expect(restored.totalPages, 40);
      expect(restored.chapterLabel, 'Chapter 9');
      expect(restored.progress, closeTo(0.3, 1e-9));
      expect(restored.readAt.toUtc(), DateTime.utc(2026, 5, 2, 8));
    });

    test('row tanpa chapter_id ditolak', () {
      expect(
        RemoteMapping.progressFromRow(<String, dynamic>{'manga_id': 'm1'}),
        isNull,
      );
    });
  });

  group('read chapters', () {
    test('row memuat user, manga, dan chapter', () {
      final row = RemoteMapping.readRow(userId, 'm1', 'c1',
          readAt: DateTime.utc(2026, 5, 3));

      expect(row['user_id'], userId);
      expect(row['manga_id'], 'm1');
      expect(row['chapter_id'], 'c1');
      expect(row['read_at'], '2026-05-03T00:00:00.000Z');
    });
  });
}
