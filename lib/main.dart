import 'package:flutter/material.dart';

import 'core/services/database_service.dart';
import 'features/gallery/gallery_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Isar
  await DatabaseService().init();

  runApp(const MyApp());
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
