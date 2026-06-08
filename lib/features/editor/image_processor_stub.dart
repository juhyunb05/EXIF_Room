import 'dart:typed_data';

Future<Map<String, Uint8List?>> processExportedImageHelper({
  required Uint8List rawRgba,
  required int width,
  required int height,
}) {
  throw UnsupportedError('Cannot process image without html or io libraries');
}
