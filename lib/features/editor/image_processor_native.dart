import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img_lib;

Future<Map<String, Uint8List?>> processExportedImageHelper({
  required Uint8List rawRgba,
  required int width,
  required int height,
}) async {
  return compute(_processExportedImageNative, {
    'rawRgba': rawRgba,
    'width': width,
    'height': height,
  });
}

Map<String, Uint8List?> _processExportedImageNative(Map<String, dynamic> data) {
  try {
    final rawRgba = data['rawRgba'] as Uint8List;
    final width = data['width'] as int;
    final height = data['height'] as int;

    // Create img_lib.Image object from raw pixel data
    final decodedImage = img_lib.Image.fromBytes(
      width: width,
      height: height,
      bytes: rawRgba.buffer,
      order: img_lib.ChannelOrder.rgba,
    );

    // 1. High-resolution JPEG encoding (JPEG quality 95%)
    final finalBytes = Uint8List.fromList(img_lib.encodeJpg(decodedImage, quality: 95));

    // 2. Create thumbnail (width 500px, JPEG quality 40%)
    final resized = img_lib.copyResize(
      decodedImage,
      width: 500,
      interpolation: img_lib.Interpolation.linear,
    );
    final thumbBytes = Uint8List.fromList(img_lib.encodeJpg(resized, quality: 40));

    return {
      'jpg': finalBytes,
      'thumb': thumbBytes,
    };
  } catch (e) {
    debugPrint('Failed to process image in background: $e');
  }
  return {'jpg': null, 'thumb': null};
}
