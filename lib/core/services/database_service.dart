import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/exif_data.dart';
import '../models/poster_project.dart';

class DatabaseService {
  static const String _boxName = 'posterProjectsBox_v2';
  late Box<PosterProject> box;

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<void> init() async {
    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      final dir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(dir.path);
    }

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PosterProjectAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ExifDataAdapter());
    }

    box = await Hive.openBox<PosterProject>(_boxName);
  }

  Future<List<PosterProject>> getAllProjects() async {
    return box.values.toList();
  }

  Future<void> saveProject(PosterProject project) async {
    if (project.isInBox) {
      await project.save();
    } else {
      final id = await box.add(project);
      project.id = id;
      await project.save();
    }
  }

  Future<void> deleteProject(int id) async {
    final project = box.values.firstWhere((p) => p.id == id);

    // 네이티브 플랫폼인 경우 파일 시스템에서 실제 이미지 파일도 함께 삭제하여 용량 낭비를 막음
    if (!kIsWeb) {
      try {
        final originalFile = File(project.originalImagePath);
        if (await originalFile.exists()) {
          await originalFile.delete();
        }
      } catch (e) {
        debugPrint('Failed to delete original image file: $e');
      }

      if (project.exportedImagePath != null) {
        try {
          final exportedFile = File(project.exportedImagePath!);
          if (await exportedFile.exists()) {
            await exportedFile.delete();
          }
        } catch (e) {
          debugPrint('Failed to delete exported image file: $e');
        }
      }
    }

    await project.delete();
  }
}
