import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../services/database_service.dart';
import '../services/file_manager_service.dart';
import '../models/poster_project.dart';
import '../models/project_category.dart';

class PosterRepository {
  final DatabaseService _db;

  PosterRepository({DatabaseService? db})
      : _db = db ?? DatabaseService();

  Future<List<PosterProject>> getAllProjects() async {
    return _db.getAllProjects();
  }

  Future<void> saveProject(PosterProject project,
      {Uint8List? originalImageBytes}) async {
    await _db.saveProject(project, originalImageBytes: originalImageBytes);
  }

  Future<void> deleteProject(int id) async {
    await _db.deleteProject(id);
  }

  Future<Uint8List?> getOriginalImageBytes(int id) async {
    return _db.getOriginalImageBytes(id);
  }

  Future<List<ProjectCategory>> getAllCategories() async {
    return _db.getAllCategories();
  }

  Future<void> saveCategory(ProjectCategory category) async {
    await _db.saveCategory(category);
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
  }

  Future<String> copyToInternalStorage(String sourcePath) async {
    return FileManagerService.copyToInternalStorage(sourcePath);
  }

  Future<void> clearAllData() async {
    await _db.clearAllData();

    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final importedDir =
            Directory(p.join(dir.path, 'imported_images'));
        if (await importedDir.exists()) {
          await importedDir.delete(recursive: true);
        }
      } catch (_) {
        // Ignore cleanup errors
      }
    }
  }
}
