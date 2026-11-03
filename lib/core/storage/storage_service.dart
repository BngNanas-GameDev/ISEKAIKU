import 'package:shared_preferences/shared_preferences.dart';

/// Pembungkus tipis `SharedPreferences`.
///
/// Semua data lokal aplikasi (setting reader, manga diikuti, riwayat baca)
/// lewat sini supaya mudah diganti backend lain (mis. sqflite) nanti.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  /// Inisialisasi sekali di `main()` sebelum `runApp()`.
  static Future<StorageService> create() async {
    return StorageService(await SharedPreferences.getInstance());
  }

  bool getBool(String key, {bool fallback = false}) =>
      _prefs.getBool(key) ?? fallback;

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  String getString(String key, {String fallback = ''}) =>
      _prefs.getString(key) ?? fallback;

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  List<String> getStringList(String key) =>
      _prefs.getStringList(key) ?? const <String>[];

  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  Future<void> remove(String key) => _prefs.remove(key);
}
