/// Aturan usia untuk konten dewasa (rating Erotika).
///
/// Ambang 18 tahun dipilih karena:
/// - Indonesia: UU 23/2002 tentang Perlindungan Anak mendefinisikan anak
///   sebagai orang yang belum berusia 18 tahun.
/// - Google Play/IARC: konten seksual grafis mendapat rating **18+**
///   (IARC 18+, PEGI 18, ESRB Adults Only).
library;

abstract class AdultPolicy {
  const AdultPolicy._();

  /// Usia minimum untuk membuka konten Erotika.
  static const int minimumAge = 18;

  /// Usia minimum untuk memakai aplikasi.
  static const int appMinimumAge = 13;

  /// Batas atas tahun lahir yang masih masuk akal.
  static const int maxAgeYears = 120;

  /// Susun tanggal lahir dari input terpisah.
  ///
  /// Mengembalikan `null` bila tanggal tidak nyata (mis. 31 Februari) atau
  /// tahun di luar rentang wajar.
  static DateTime? birthDate(int day, int month, int year, {DateTime? now}) {
    final DateTime current = now ?? DateTime.now();
    if (year < current.year - maxAgeYears || year > current.year) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    final DateTime date = DateTime(year, month, day);
    // DateTime menormalkan tanggal tidak valid; tolak bila berubah.
    if (date.day != day || date.month != month || date.year != year) {
      return null;
    }
    return date;
  }

  /// Usia pada [now] berdasarkan tanggal lahir.
  static int ageOn(DateTime birthDate, {DateTime? now}) {
    final DateTime current = now ?? DateTime.now();
    int age = current.year - birthDate.year;

    final bool hadBirthday =
        current.month > birthDate.month ||
        (current.month == birthDate.month && current.day >= birthDate.day);
    if (!hadBirthday) age -= 1;

    return age;
  }

  /// True bila sudah memenuhi [minimumAge].
  static bool isAdult(DateTime birthDate, {DateTime? now}) {
    return ageOn(birthDate, now: now) >= minimumAge;
  }

  /// True bila memenuhi [appMinimumAge].
  static bool canUseApp(DateTime birthDate, {DateTime? now}) {
    return ageOn(birthDate, now: now) >= appMinimumAge;
  }
}
