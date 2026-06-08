// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';

Future<Map<String, Uint8List?>> processExportedImageHelper({
  required Uint8List rawRgba,
  required int width,
  required int height,
}) async {
  try {
    // 1. Create a canvas for high-resolution image
    final canvas = html.CanvasElement(width: width, height: height);
    final ctx = canvas.context2D;

    // Create ImageData and fill it with our raw RGBA bytes
    final imageData = ctx.createImageData(width, height);
    final data = imageData.data;
    
    // Canvas ImageData data is a Uint8ClampedList. We copy our rawRgba bytes directly.
    data.setRange(0, rawRgba.length, rawRgba);
    
    // Put ImageData on canvas
    ctx.putImageData(imageData, 0, 0);

    // Get high-res JPEG bytes via DataURL (sync & highly reliable)
    final finalBytes = _canvasToJpgBytes(canvas, 0.95);

    // 2. Create a canvas for thumbnail (500px width)
    final thumbWidth = 500;
    final thumbHeight = (height * (thumbWidth / width)).round();
    final thumbCanvas = html.CanvasElement(width: thumbWidth, height: thumbHeight);
    final thumbCtx = thumbCanvas.context2D;

    // Draw and resize the original canvas to the thumb canvas
    thumbCtx.drawImageScaled(canvas, 0, 0, thumbWidth, thumbHeight);

    // Get thumbnail JPEG bytes via DataURL
    final thumbBytes = _canvasToJpgBytes(thumbCanvas, 0.40);

    return {
      'jpg': finalBytes,
      'thumb': thumbBytes,
    };
  } catch (e, stackTrace) {
    html.window.console.error('Failed to process image on web: $e\n$stackTrace');
    rethrow;
  }
}

Uint8List _canvasToJpgBytes(html.CanvasElement canvas, double quality) {
  final dataUrl = canvas.toDataUrl('image/jpeg', quality);
  final commaIndex = dataUrl.indexOf(',');
  if (commaIndex == -1) {
    throw Exception('Failed to generate data URL from canvas');
  }
  final base64Str = dataUrl.substring(commaIndex + 1);
  return base64Decode(base64Str);
}
