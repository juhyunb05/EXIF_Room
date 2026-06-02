import 'package:isar/isar.dart';

part 'exif_data.g.dart';

@embedded
class ExifData {
  String? cameraMake;
  String? cameraName;
  String? location;
  DateTime? shotDate;
  String? iso;
  String? aperture;
  String? shutterSpeed;
  String? focalLength;
  String? lensModel;

  ExifData({
    this.cameraMake,
    this.cameraName,
    this.location,
    this.shotDate,
    this.iso,
    this.aperture,
    this.shutterSpeed,
    this.focalLength,
    this.lensModel,
  });
}
