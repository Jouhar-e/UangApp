import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:uangapp/app.dart';
import 'package:uangapp/services/ai_service.dart';
import 'package:uangapp/services/google_auth_service.dart';
import 'package:uangapp/services/theme_service.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await dotenv.load(fileName: '.env');

  final themeService = ThemeService();
  await themeService.load();

  final authService = GoogleAuthService();
  unawaited(authService.warmUp());
  unawaited(initializeDateFormatting('id_ID', null));

  runApp(
    UangApp(
      aiService: AiService.create(),
      authService: authService,
      themeService: themeService,
    ),
  );
}
