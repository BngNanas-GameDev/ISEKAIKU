import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'auth_service.dart';

/// Client Supabase. Hanya boleh dibaca jika [AppConfig.hasSupabase] benar.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(supabaseClientProvider)),
);

/// Perubahan status login (masuk/keluar/refresh token).
final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authServiceProvider).changes,
);

/// Pengguna yang sedang masuk, atau `null`.
final currentUserProvider = Provider<User?>((ref) {
  // Ikut berubah saat status auth berubah.
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser;
});
