import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/moderation/content_moderation.dart';
import 'package:isekaiku/core/theme/app_theme.dart';
import 'package:isekaiku/features/forum/data/forum_format.dart';
import 'package:isekaiku/features/forum/data/forum_validation.dart';
import 'package:isekaiku/features/forum/data/models/forum_models.dart';
import 'package:isekaiku/features/forum/presentation/forum_page.dart';
import 'package:isekaiku/features/forum/presentation/widgets/forum_widgets.dart';

void main() {
  group('kategori forum', () {
    test('id dikenal dipetakan ke enum', () {
      expect(ForumCategory.fromId('bantuan'), ForumCategory.bantuan);
      expect(ForumCategory.fromId('offtopic'), ForumCategory.offtopic);
    });

    test('id tak dikenal jatuh ke umum', () {
      expect(ForumCategory.fromId('entah'), ForumCategory.umum);
      expect(ForumCategory.fromId(null), ForumCategory.umum);
    });
  });

  group('pemetaan baris', () {
    test('topik lengkap terbaca beserta nama penulis', () {
      final thread = ForumThread.tryFromRow(
        <String, dynamic>{
          'id': 't1',
          'user_id': 'u1',
          'category': 'rekomendasi',
          'title': 'Rekomendasi manga isekai',
          'body': 'Ada yang bagus selain Frieren?',
          'reply_count': 3,
          'created_at': '2026-11-01T10:00:00Z',
          'last_activity_at': '2026-11-02T10:00:00Z',
          'is_pinned': true,
          'is_locked': false,
        },
        authorNames: <String, String>{'u1': 'Budi'},
      );

      expect(thread, isNotNull);
      expect(thread!.category, ForumCategory.rekomendasi);
      expect(thread.authorName, 'Budi');
      expect(thread.replyCount, 3);
      expect(thread.isPinned, isTrue);
      expect(thread.isLocked, isFalse);
    });

    test('nama penulis tak dikenal memakai nama umum', () {
      final thread = ForumThread.tryFromRow(<String, dynamic>{
        'id': 't1',
        'user_id': 'u1',
        'title': 'Halo',
        'body': 'Isi',
      });

      expect(thread!.authorName, 'Pengguna Isekaiku');
      expect(thread.replyCount, 0);
    });

    test('baris tanpa id ditolak', () {
      expect(
        ForumThread.tryFromRow(<String, dynamic>{'user_id': 'u1'}),
        isNull,
      );
    });

    test('balasan lengkap terbaca, baris rusak ditolak', () {
      final post = ForumPost.tryFromRow(
        <String, dynamic>{
          'id': 'p1',
          'thread_id': 't1',
          'user_id': 'u2',
          'body': 'Setuju!',
          'created_at': '2026-11-03T10:00:00Z',
        },
        authorNames: <String, String>{'u2': 'Sari'},
      );

      expect(post, isNotNull);
      expect(post!.authorName, 'Sari');
      expect(post.threadId, 't1');

      expect(ForumPost.tryFromRow(<String, dynamic>{'id': 'p1'}), isNull);
    });
  });

  group('waktu relatif', () {
    final now = DateTime(2026, 11, 4, 12, 0);

    test('kurang dari semenit = baru saja', () {
      expect(
        ForumFormat.relative(
          now.subtract(const Duration(seconds: 5)),
          now: now,
        ),
        'baru saja',
      );
    });

    test('menit, jam, hari', () {
      expect(
        ForumFormat.relative(
          now.subtract(const Duration(minutes: 5)),
          now: now,
        ),
        '5 mnt',
      );
      expect(
        ForumFormat.relative(now.subtract(const Duration(hours: 3)), now: now),
        '3 jam',
      );
      expect(
        ForumFormat.relative(now.subtract(const Duration(days: 2)), now: now),
        '2 hr',
      );
    });

    test('lebih dari sebulan memakai tanggal', () {
      expect(
        ForumFormat.relative(DateTime(2026, 9, 12, 9), now: now),
        '12 Sep',
      );
      expect(
        ForumFormat.relative(DateTime(2025, 12, 25, 9), now: now),
        '25 Des 2025',
      );
    });

    test('waktu di masa depan dianggap baru saja', () {
      expect(
        ForumFormat.relative(now.add(const Duration(minutes: 5)), now: now),
        'baru saja',
      );
    });
  });

  group('inisial avatar', () {
    test('dua kata memakai huruf awal keduanya', () {
      expect(ForumFormat.initials('Budi Santoso'), 'BS');
    });

    test('satu kata memakai satu huruf', () {
      expect(ForumFormat.initials('budi'), 'B');
    });

    test('nama kosong tidak melempar', () {
      expect(ForumFormat.initials('   '), '?');
    });
  });

  group('validasi forum', () {
    test('judul terlalu pendek ditolak', () {
      expect(ForumValidation.titleError('hai'), isNotNull);
    });

    test('judul valid lolos', () {
      expect(ForumValidation.titleError('Rekomendasi manga isekai'), isNull);
    });

    test('judul dengan tautan ditolak', () {
      expect(
        ForumValidation.titleError('Baca di https://contoh.com'),
        ContentModeration.messageLink,
      );
    });

    test('isi kosong ditolak', () {
      expect(ForumValidation.bodyError('   '), 'Isi tidak boleh kosong.');
    });

    test('isi panjang di atas batas komentar tetap boleh (5000)', () {
      final body = 'a' * (ContentModeration.maxLength + 500);
      expect(ForumValidation.bodyError(body), isNull);
    });

    test('isi melebihi 5000 karakter ditolak', () {
      expect(ForumValidation.bodyError('a' * 5001), isNotNull);
    });

    test('promosi judi di isi ditolak', () {
      expect(
        ForumValidation.bodyError('mampir ke slot gacor'),
        ContentModeration.messageGambling,
      );
    });

    test('alasan laporan terlalu pendek ditolak', () {
      expect(ForumValidation.reasonError('ok'), isNotNull);
      expect(ForumValidation.reasonError('spam berulang'), isNull);
    });
  });

  group('moderasi dengan batas khusus', () {
    test('pesan panjang memakai batas yang diberikan', () {
      final result = ContentModeration.check('a' * 1200, maxLength: 5000);
      expect(result.allowed, isTrue);
    });

    test('pesan melewati batas khusus ditolak dengan pesan dinamis', () {
      final result = ContentModeration.check('a' * 5001, maxLength: 5000);
      expect(result.allowed, isFalse);
      expect(result.message, contains('5000'));
    });
  });

  group('tampilan forum', () {
    testWidgets('tanpa Supabase menampilkan status belum aktif', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ForumPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Forum belum aktif'), findsOneWidget);
      expect(find.textContaining('Fitur baca tetap berjalan'), findsOneWidget);
    });

    testWidgets('kartu topik menampilkan kategori dan jumlah balasan', (
      tester,
    ) async {
      final thread = ForumThread(
        id: 't1',
        authorId: 'u1',
        authorName: 'Budi Santoso',
        category: ForumCategory.rekomendasi,
        title: 'Rekomendasi manga isekai',
        body: 'Ada yang bagus selain Frieren?',
        replyCount: 2,
        createdAt: DateTime(2026, 11, 1),
        lastActivityAt: DateTime(2026, 11, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: appDarkTheme(),
          home: Scaffold(
            body: ForumThreadTile(thread: thread, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Rekomendasi'), findsOneWidget);
      expect(find.text('Rekomendasi manga isekai'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });
}
