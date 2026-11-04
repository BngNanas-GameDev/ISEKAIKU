/// Konfigurasi aplikasi yang berasal dari `--dart-define`.
///
/// Nilai diambil dari berkas `.env` oleh `scripts/flutter-env.ps1`, sehingga
/// tidak ada rahasia yang tertanam di kode sumber.
///
/// Kalau `SUPABASE_URL` / `SUPABASE_ANON_KEY` kosong, fitur akun otomatis
/// dimatikan dan aplikasi tetap berjalan penuh secara lokal.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// `anon` key — aman untuk klien karena dilindungi RLS.
  /// Jangan pernah memakai `service_role` di sini.
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Google OAuth client ID (untuk login Google).
  static const String googleClientId = String.fromEnvironment('ISEKAIKU_CID');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasGoogle =>
      hasSupabase && googleClientId.isNotEmpty;
}
