import 'package:hive/hive.dart';

part 'project_category.g.dart';

@HiveType(typeId: 3)
class ProjectCategory extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int number;

  @HiveField(2)
  String name;

  @HiveField(3)
  DateTime createdAt;

  ProjectCategory({
    required this.id,
    required this.number,
    required this.name,
    required this.createdAt,
  });
}
