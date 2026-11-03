import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Mendaftarkan lisensi pihak ketiga yang tidak otomatis terdeteksi Flutter.
///
/// Font Asimov dilisensikan Apache 2.0 — wajib ditampilkan di halaman lisensi.
void registerAppLicenses() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/LICENSE-Asimov.txt');
    yield LicenseEntryWithLineBreaks(<String>['Asimov'], license);

    final notice = await rootBundle.loadString('assets/fonts/NOTICE-Asimov.txt');
    yield LicenseEntryWithLineBreaks(<String>['Asimov'], notice);
  });
}
