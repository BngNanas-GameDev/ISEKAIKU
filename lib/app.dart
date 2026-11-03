import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class IsekaikuApp extends StatelessWidget {
  const IsekaikuApp({super.key});

  @override
  Widget build(BuildContext context) {
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
