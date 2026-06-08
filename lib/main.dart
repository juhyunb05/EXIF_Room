import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/services/database_service.dart';
import 'features/gallery/gallery_screen.dart';
import 'theme/app_theme.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Isar
    await DatabaseService().init();

    runApp(const MyApp());
  } catch (e, stackTrace) {
    try {
      if (!kIsWeb) {
        File('error_log.txt').writeAsStringSync('Startup Error: $e\n$stackTrace');
      } else {
        debugPrint('Startup Error: $e\n$stackTrace');
      }
    } catch (_) {}
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Startup Error: $e'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exif Room',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
      locale: const Locale('ko', 'KR'),
      home: const GalleryScreen(),
    );
  }
}
