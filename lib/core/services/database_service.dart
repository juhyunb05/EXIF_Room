import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/exif_data.dart';
import '../models/poster_project.dart';
import '../models/poster_project_image.dart';
import '../models/project_category.dart';
import '../utils/logger.dart';

class DatabaseService {
  static const String _boxName = 'posterProjectsBox_v2';
  static const String _categoriesBoxName = 'projectCategoriesBox';
  static const String _imagesBoxName = 'posterProjectImagesBox';

  late Box<PosterProject> _box;
  late Box<ProjectCategory> _categoriesBox;
  late Box<PosterProjectImage> _imagesBox;

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<void> init() async {
    try {
      if (kIsWeb) {
        await Hive.initFlutter();
      } else {
        final dir = await getApplicationDocumentsDirectory();
        await Hive.initFlutter(dir.path);
      }

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

      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox<PosterProject>(_boxName);
      } else {
        _box = Hive.box<PosterProject>(_boxName);
      }

      if (!Hive.isBoxOpen(_categoriesBoxName)) {
        _categoriesBox = await Hive.openBox<ProjectCategory>(_categoriesBoxName);
      } else {
        _categoriesBox = Hive.box<ProjectCategory>(_categoriesBoxName);
      }

      if (!Hive.isBoxOpen(_imagesBoxName)) {
        _imagesBox = await Hive.openBox<PosterProjectImage>(_imagesBoxName);
      } else {
        _imagesBox = Hive.box<PosterProjectImage>(_imagesBoxName);
      }
    } catch (e, st) {
      Logger.e('Failed to initialize DatabaseService', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<PosterProject>> getAllProjects() async {
    try {
      return _box.values.toList();
    } catch (e) {
      Logger.e('Failed to get all projects', error: e);
      return [];
    }
  }

  Future<List<ProjectCategory>> getAllCategories() async {
    try {
      final list = _categoriesBox.values.toList();
      list.sort((a, b) => a.number.compareTo(b.number));
      return list;
    } catch (e) {
      Logger.e('Failed to get all categories', error: e);
      return [];
    }
  }

  Future<void> saveCategory(ProjectCategory category) async {
    try {
      if (category.isInBox) {
        await category.save();
      } else {
        final id = await _categoriesBox.add(category);
        category.id = id;
        await category.save();
      }
    } catch (e) {
      Logger.e('Failed to save category', error: e);
      rethrow;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _categoriesBox.delete(id);
      for (final project in _box.values) {
        final currentIds = project.categoryIdList;
        if (currentIds.contains(id)) {
          final updated = currentIds.where((catId) => catId != id).toList();
          project.setCategoryIds(updated);
          await project.save();
        }
      }
    } catch (e) {
      Logger.e('Failed to delete category', error: e);
    }
  }

  Future<void> saveProject(PosterProject project, {Uint8List? originalImageBytes}) async {
    try {
      if (project.isInBox) {
        await project.save();
      } else {
        final id = await _box.add(project);
        project.id = id;
        await project.save();
      }

      if (originalImageBytes != null && project.id != null) {
        try {
          final imageObj = PosterProjectImage(id: project.id, imageBytes: originalImageBytes);
          await _imagesBox.put(project.id, imageObj);
        } catch (e) {
          Logger.e('Failed to save original image bytes', error: e);
        }
      }
    } catch (e) {
      Logger.e('Failed to save project', error: e);
      rethrow;
    }
  }

  Future<void> deleteProject(int id) async {
    try {
      final project = _box.values.firstWhere((p) => p.id == id);

      if (!kIsWeb) {
        try {
          final originalFile = File(project.originalImagePath);
          if (await originalFile.exists()) {
            await originalFile.delete();
          }
        } catch (e) {
          Logger.e('Failed to delete original image file', error: e);
        }

        if (project.exportedImagePath != null) {
          try {
            final exportedFile = File(project.exportedImagePath!);
            if (await exportedFile.exists()) {
              await exportedFile.delete();
            }
          } catch (e) {
            Logger.e('Failed to delete exported image file', error: e);
          }
        }
      }

      try {
        await _imagesBox.delete(id);
      } catch (e) {
        Logger.e('Failed to delete isolated original image', error: e);
      }

      await project.delete();
    } catch (e) {
      Logger.e('Failed to delete project', error: e);
    }
  }

  Future<void> clearAllData() async {
    try {
      await _box.clear();
      await _categoriesBox.clear();
      await _imagesBox.clear();
    } catch (e) {
      Logger.e('Failed to clear all data', error: e);
      rethrow;
    }
  }

  Future<Uint8List?> getOriginalImageBytes(int id) async {
    try {
      final imageObj = _imagesBox.get(id);
      return imageObj?.imageBytes;
    } catch (e) {
      Logger.e('Failed to load isolated original image', error: e);
      return null;
    }
  }
}
