import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:provider/provider.dart';
import 'core/providers/gallery_provider.dart';
import 'core/services/database_service.dart';
import 'features/gallery/gallery_screen.dart';
import 'theme/app_theme.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    if (kIsWeb) {
      BrowserContextMenu.disableContextMenu();
    }

    // Initialize Database
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GalleryProvider()..loadProjects()),
      ],
      child: ExcludeSemantics(
        child: MaterialApp(
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
        ),
      ),
    );
  }
}
