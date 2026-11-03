import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/licensing.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerAppLicenses();
  runApp(const ProviderScope(child: IsekaikuApp()));
}
