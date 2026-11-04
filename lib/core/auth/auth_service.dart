import 'package:supabase_flutter/supabase_flutter.dart';

/// Pembungkus tipis Supabase Auth.
///
/// Dipakai hanya kalau [AppConfig.hasSupabase] benar. Tanpa konfigurasi,
/// aplikasi tetap berjalan penuh secara lokal.
class AuthService {
  AuthService(this._client);

  /// Harus sama dengan intent-filter AndroidManifest dan Redirect URLs
  /// di dashboard Supabase.
  static const String authRedirect =
      'com.isekaiku.isekaiku://auth-callback';

  final SupabaseClient _client;

  User? get user => _client.auth.currentUser;

  bool get isSignedIn => user != null;

  Stream<AuthState> get changes => _client.auth.onAuthStateChange;

  /// Buka halaman login Google di browser eksternal.
  ///
  /// Hasil sebenarnya muncul lewat [changes]/`authStateProvider` setelah
  /// aplikasi kembali dari deep link.
  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: authRedirect,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Email pengguna, atau `null` bila belum masuk.
  String? get email => user?.email;

  /// Username dari metadata (diisi saat profil dibuat) atau bagian email.
  String? get displayName {
    final current = user;
    if (current == null) return null;
    final meta = current.userMetadata;
    final username = meta?['username'];
    if (username is String && username.trim().isNotEmpty) return username;
    return current.email;
  }
}
