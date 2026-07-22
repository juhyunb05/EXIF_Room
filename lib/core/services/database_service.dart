import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/exif_data.dart';
import '../models/poster_project.dart';
import '../models/poster_project_image.dart';
import '../models/project_category.dart';

class DatabaseService {
  static const String _boxName = 'posterProjectsBox_v2';
  static const String _categoriesBoxName = 'projectCategoriesBox';

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

    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PosterProjectImageAdapter());
    }

    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ProjectCategoryAdapter());
    }

    box = await Hive.openBox<PosterProject>(_boxName);
    await _getCategoriesBox();
  }

  Future<Box<ProjectCategory>> _getCategoriesBox() async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ProjectCategoryAdapter());
    }
    if (Hive.isBoxOpen(_categoriesBoxName)) {
      return Hive.box<ProjectCategory>(_categoriesBoxName);
    }
    return await Hive.openBox<ProjectCategory>(_categoriesBoxName);
  }

  Future<List<PosterProject>> getAllProjects() async {
    if (!Hive.isBoxOpen(_boxName)) {
      box = await Hive.openBox<PosterProject>(_boxName);
    }
    return box.values.toList();
  }

  Future<List<ProjectCategory>> getAllCategories() async {
    final cBox = await _getCategoriesBox();
    final list = cBox.values.toList();
    list.sort((a, b) => a.number.compareTo(b.number));
    return list;
  }

  Future<void> saveCategory(ProjectCategory category) async {
    final cBox = await _getCategoriesBox();
    if (category.isInBox) {
      await category.save();
    } else {
      final id = await cBox.add(category);
      category.id = id;
      await category.save();
    }
  }

  Future<void> deleteCategory(int id) async {
    final cBox = await _getCategoriesBox();
    await cBox.delete(id);
    if (!Hive.isBoxOpen(_boxName)) {
      box = await Hive.openBox<PosterProject>(_boxName);
    }
    for (final project in box.values) {
      if (project.categoryId == id) {
        project.categoryId = null;
        await project.save();
      }
    }
  }

  Future<void> saveProject(PosterProject project, {Uint8List? originalImageBytes}) async {
    if (!Hive.isBoxOpen(_boxName)) {
      box = await Hive.openBox<PosterProject>(_boxName);
    }
    if (project.isInBox) {
      await project.save();
    } else {
      final id = await box.add(project);
      project.id = id;
      await project.save();
    }

    // 원본 고화질 이미지를 전용 이미지 격리 박스에 분리 저장
    if (originalImageBytes != null && project.id != null) {
      try {
        final imageBox = await Hive.openBox<PosterProjectImage>('posterProjectImagesBox');
        final imageObj = PosterProjectImage(id: project.id, imageBytes: originalImageBytes);
        await imageBox.put(project.id, imageObj);
        await imageBox.close(); // 즉시 닫아 램 메모리를 회수
      } catch (e) {
        debugPrint('Failed to save original image bytes: $e');
      }
    }
  }

  Future<void> deleteProject(int id) async {
    if (!Hive.isBoxOpen(_boxName)) {
      box = await Hive.openBox<PosterProject>(_boxName);
    }
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

    // 이미지 전용 격리 박스에서도 원본 고화질 이미지 데이터 삭제
    try {
      final imageBox = await Hive.openBox<PosterProjectImage>('posterProjectImagesBox');
      await imageBox.delete(id);
      await imageBox.close();
    } catch (e) {
      debugPrint('Failed to delete isolated original image: $e');
    }

    await project.delete();
  }

  Future<void> clearAllData() async {
    if (!Hive.isBoxOpen(_boxName)) {
      box = await Hive.openBox<PosterProject>(_boxName);
    }
    await box.clear();
    final cBox = await _getCategoriesBox();
    await cBox.clear();
    try {
      final imageBox = await Hive.openBox<PosterProjectImage>('posterProjectImagesBox');
      await imageBox.clear();
      await imageBox.close();
    } catch (e) {
      debugPrint('Failed to clear isolated images: $e');
    }
  }

  Future<Uint8List?> getOriginalImageBytes(int id) async {
    try {
      final imageBox = await Hive.openBox<PosterProjectImage>('posterProjectImagesBox');
      final imageObj = imageBox.get(id);
      final bytes = imageObj?.imageBytes;
      await imageBox.close(); // 로드가 끝나면 즉시 닫아 램 메모리를 반환
      return bytes;
    } catch (e) {
      debugPrint('Failed to load isolated original image: $e');
      return null;
    }
  }
}
