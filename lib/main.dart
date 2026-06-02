import 'package:flutter/material.dart';

import 'core/services/database_service.dart';
import 'features/gallery/gallery_screen.dart';
import 'theme/app_theme.dart';

import 'dart:io';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Isar
    await DatabaseService().init();

    runApp(const MyApp());
  } catch (e, stackTrace) {
    try {
      File('error_log.txt').writeAsStringSync('Startup Error: $e\n$stackTrace');
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
      home: const GalleryScreen(),
    );
  }
}
