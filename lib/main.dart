import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/licensing.dart';
import 'core/network/doh/doh_http_overrides.dart';
import 'core/storage/storage_providers.dart';
import 'core/storage/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DNS-over-HTTPS dipasang lebih dulu supaya semua HttpClient (Dio,
  // cached_network_image) memakai resolver DoH. Ini yang membuat
  // api.mangadex.org tetap bisa dijangkau meski DNS ISP membajaknya.
  // Matikan dengan: flutter run --dart-define=DISABLE_DOH=true
  const bool disableDoh = bool.fromEnvironment('DISABLE_DOH');
  HttpOverrides.global = DohHttpOverrides(enabled: !disableDoh);

  // Backend opsional. Tanpa SUPABASE_URL/ANON_KEY, aplikasi tetap
  // berjalan penuh secara lokal.
  if (AppConfig.hasSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // Nama baru untuk anon/publishable key pada supabase_flutter 2.16+.
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  registerAppLicenses();

  // Penyimpanan lokal dibuka sekali di sini lalu dibagikan lewat provider.
  final StorageService storage = await StorageService.create();

  runApp(
    ProviderScope(
      overrides: <Override>[
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const IsekaikuApp(),
    ),
  );
}
