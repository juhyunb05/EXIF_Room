import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'poster_project_image.g.dart';

@HiveType(typeId: 2)
class PosterProjectImage extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  Uint8List imageBytes;

  PosterProjectImage({
    this.id,
    required this.imageBytes,
  });
}
