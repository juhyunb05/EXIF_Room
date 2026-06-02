import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/poster_project.dart';

class DatabaseService {
  late Isar isar;

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([PosterProjectSchema], directory: dir.path);
  }

  Future<List<PosterProject>> getAllProjects() async {
    return await isar.posterProjects.where().findAll();
  }

  Future<void> saveProject(PosterProject project) async {
    await isar.writeTxn(() async {
      await isar.posterProjects.put(project);
    });
  }

  Future<void> deleteProject(Id id) async {
    await isar.writeTxn(() async {
      await isar.posterProjects.delete(id);
    });
  }
}
