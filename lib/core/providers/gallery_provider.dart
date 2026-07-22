import 'package:flutter/foundation.dart';
import '../models/poster_project.dart';
import '../models/project_category.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

class GalleryProvider extends ChangeNotifier {
  List<PosterProject> _projects = [];
  List<ProjectCategory> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = true;

  List<PosterProject> get projects => _projects;
  List<ProjectCategory> get categories => _categories;
  int? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;

  final DatabaseService _dbService = DatabaseService();

  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      final allProjects = await _dbService.getAllProjects();
      allProjects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _projects = allProjects;

      _categories = await _dbService.getAllCategories();
    } catch (e) {
      Logger.e('Failed to load projects/categories', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategoryFilter(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  List<PosterProject> get filteredProjects {
    if (_selectedCategoryId == null) {
      return _projects;
    }
    return _projects.where((p) => p.categoryIdList.contains(_selectedCategoryId)).toList();
  }

  Future<void> deleteProject(int id) async {
    try {
      await _dbService.deleteProject(id);
      await loadProjects();
    } catch (e) {
      Logger.e('Failed to delete project', error: e);
      rethrow;
    }
  }

  Future<ProjectCategory?> createCategory(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return null;

    final usedNumbers = _categories.map((c) => c.number).toSet();
    int nextNumber = 1;
    for (int i = 1; i <= 5; i++) {
      if (!usedNumbers.contains(i)) {
        nextNumber = i;
        break;
      }
    }

    final newCat = ProjectCategory(
      id: 0,
      number: nextNumber,
      name: trimmedName,
      createdAt: DateTime.now(),
    );

    await _dbService.saveCategory(newCat);
    await loadProjects();

    try {
      final savedCat = _categories.firstWhere((c) => c.name == trimmedName);
      _selectedCategoryId = savedCat.id;
      notifyListeners();
      return savedCat;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteCategory(int id) async {
    await _dbService.deleteCategory(id);
    if (_selectedCategoryId == id) {
      _selectedCategoryId = null;
    }
    await loadProjects();
  }

  Future<void> assignProjectToCategories(PosterProject project, List<int> categoryIds) async {
    project.setCategoryIds(categoryIds);
    await _dbService.saveProject(project);
    await loadProjects();
  }

  Future<void> assignProjectToCategory(PosterProject project, int? categoryId) async {
    await assignProjectToCategories(
      project,
      categoryId != null ? [categoryId] : [],
    );
  }
}
