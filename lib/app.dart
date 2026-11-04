import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/auth_providers.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_providers.dart';
import 'core/theme/app_theme.dart';

class IsekaikuApp extends ConsumerWidget {
  const IsekaikuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Setelah login (atau sesi lama dipulihkan), tarik data dari cloud.
    // Dilewati sepenuhnya kalau backend belum dikonfigurasi.
    if (AppConfig.hasSupabase) {
      ref.listen(authStateProvider, (previous, next) {
        final event = next.valueOrNull?.event;
        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.initialSession) {
          ref.read(syncNotifierProvider.notifier).syncNow();
        }
      });
    }

    return MaterialApp.router(
      title: 'Isekaiku',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: appDarkTheme(),
      darkTheme: appDarkTheme(),
      themeMode: ThemeMode.dark,
      locale: const Locale('id'),
      supportedLocales: const <Locale>[Locale('id'), Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
