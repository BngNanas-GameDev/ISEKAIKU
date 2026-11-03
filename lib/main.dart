import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/licensing.dart';
import 'core/network/doh/doh_http_overrides.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // DNS-over-HTTPS dipasang lebih dulu supaya semua HttpClient (Dio,
  // cached_network_image) memakai resolver DoH. Ini yang membuat
  // api.mangadex.org tetap bisa dijangkau meski DNS ISP membajaknya.
  // Matikan dengan: flutter run --dart-define=DISABLE_DOH=true
  const bool disableDoh = bool.fromEnvironment('DISABLE_DOH');
  HttpOverrides.global = DohHttpOverrides(enabled: !disableDoh);

  registerAppLicenses();
  runApp(const ProviderScope(child: IsekaikuApp()));
}
