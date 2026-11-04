import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/features/account/data/models/profile_models.dart';
import 'package:isekaiku/features/account/presentation/account_page.dart';

void main() {
  group('profil pengguna', () {
    test('bio dan avatar terbaca', () {
      final profile = UserProfile.tryFromRow(<String, dynamic>{
        'id': 'u1',
        'username': 'budi',
        'bio': 'Suka manga isekai',
        'avatar_url': 'https://cdn.example/a.jpg',
      });

      expect(profile, isNotNull);
      expect(profile!.displayName, 'budi');
      expect(profile.bio, 'Suka manga isekai');
      expect(profile.avatarUrl, 'https://cdn.example/a.jpg');
    });

    test('bio kosong tetap aman', () {
      final profile = UserProfile.tryFromRow(<String, dynamic>{
        'id': 'u1',
        'username': 'budi',
      });

      expect(profile!.bio, '');
      expect(profile.avatarUrl, isNull);
    });

    test('username kosong memakai nama umum', () {
      final profile = UserProfile.tryFromRow(<String, dynamic>{
        'id': 'u1',
        'username': '  ',
      });

      expect(profile!.displayName, 'Pengguna Isekaiku');
    });

    test('baris tanpa id ditolak', () {
      expect(
        UserProfile.tryFromRow(<String, dynamic>{'username': 'budi'}),
        isNull,
      );
    });

    test('statistik kosong bernilai nol', () {
      expect(ProfileStats.empty.followers, 0);
      expect(ProfileStats.empty.following, 0);
    });
  });

  group('tab akun', () {
    testWidgets('tanpa Supabase menampilkan status belum aktif', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AccountPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Akun belum aktif'), findsOneWidget);
      expect(
        find.textContaining('Pustaka lokal tetap berjalan'),
        findsOneWidget,
      );
    });
  });
}
