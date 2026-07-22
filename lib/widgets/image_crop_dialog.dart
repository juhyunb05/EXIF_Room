import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img_lib;
import '../theme/app_theme.dart';
import 'hover_interaction.dart';

enum CropRatioType {
  custom,
  ratio1x1,
  ratio3x2,
  ratio4x3,
  ratio16x9,
}

class ImageCropDialog extends StatefulWidget {
  final Uint8List imageBytes;

  const ImageCropDialog({
    super.key,
    required this.imageBytes,
  });

  static Future<Uint8List?> show(BuildContext context, Uint8List imageBytes) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => ImageCropDialog(imageBytes: imageBytes),
    );
  }

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  ui.Image? _decodedImage;
  bool _isLoading = true;
  bool _isProcessingCrop = false;

  // Selected preset and orientation
  CropRatioType _selectedPreset = CropRatioType.custom;
  bool _isPortrait = false;

  // Normalized crop rect in [0..1] relative to original image size
  Rect _cropRect = const Rect.fromLTWH(0, 0, 1, 1);

  // Active drag state
  _DragHandleType? _activeHandle;
  Offset? _dragStartOffset;
  Rect? _initialCropRect;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      if (mounted) {
        setState(() {
          _decodedImage = image;
          _isLoading = false;
          // Default portrait state based on image dimensions
          _isPortrait = image.height > image.width;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  double? _getTargetAspectRatio() {
    double? baseRatio;
    switch (_selectedPreset) {
      case CropRatioType.custom:
        return null;
      case CropRatioType.ratio1x1:
        return 1.0;
      case CropRatioType.ratio3x2:
        baseRatio = 3.0 / 2.0;
        break;
      case CropRatioType.ratio4x3:
        baseRatio = 4.0 / 3.0;
        break;
      case CropRatioType.ratio16x9:
        baseRatio = 16.0 / 9.0;
        break;
    }
    return _isPortrait ? (1.0 / baseRatio) : baseRatio;
  }

  void _applyAspectRatio(CropRatioType preset) {
    setState(() {
      _selectedPreset = preset;
      _updateCropRectForTargetRatio();
    });
  }

  void _toggleOrientation() {
    setState(() {
      _isPortrait = !_isPortrait;
      if (_selectedPreset == CropRatioType.custom) {
        // For custom ratio, invert the current cropRect ratio around center
        final currentW = _cropRect.width;
        final currentH = _cropRect.height;
        final imgW = _decodedImage!.width.toDouble();
        final imgH = _decodedImage!.height.toDouble();

        // Calculate aspect ratio in absolute pixels
        final absW = currentW * imgW;
        final absH = currentH * imgH;

        // Invert dimensions
        final targetAbsW = absH;
        final targetAbsH = absW;

        double normW = targetAbsW / imgW;
        double normH = targetAbsH / imgH;

        if (normW > 1.0 || normH > 1.0) {
          final scale = (normW > normH) ? (1.0 / normW) : (1.0 / normH);
          normW *= scale;
          normH *= scale;
        }

        final cx = _cropRect.center.dx;
        final cy = _cropRect.center.dy;

        double left = cx - normW / 2;
        double top = cy - normH / 2;

        if (left < 0) left = 0;
        if (top < 0) top = 0;
        if (left + normW > 1.0) left = 1.0 - normW;
        if (top + normH > 1.0) top = 1.0 - normH;

        _cropRect = Rect.fromLTWH(left, top, normW, normH);
      } else {
        _updateCropRectForTargetRatio();
      }
    });
  }

  void _updateCropRectForTargetRatio() {
    final targetRatio = _getTargetAspectRatio();
    if (targetRatio == null || _decodedImage == null) return;

    final imgW = _decodedImage!.width.toDouble();
    final imgH = _decodedImage!.height.toDouble();
    final imgRatio = imgW / imgH;

    double normW, normH;

    if (targetRatio > imgRatio) {
      // Crop height is constrained
      normW = 1.0;
      normH = (imgW / targetRatio) / imgH;
    } else {
      // Crop width is constrained
      normH = 1.0;
      normW = (imgH * targetRatio) / imgW;
    }

    final cx = _cropRect.center.dx.clamp(normW / 2, 1.0 - normW / 2);
    final cy = _cropRect.center.dy.clamp(normH / 2, 1.0 - normH / 2);

    _cropRect = Rect.fromLTWH(
      cx - normW / 2,
      cy - normH / 2,
      normW,
      normH,
    );
  }

  void _resetCrop() {
    setState(() {
      _selectedPreset = CropRatioType.custom;
      _cropRect = const Rect.fromLTWH(0, 0, 1, 1);
    });
  }

  Future<Uint8List?> _cropImageFast(Rect normCropRect) async {
    if (_decodedImage == null) return null;

    final originalImage = _decodedImage!;
    final double origW = originalImage.width.toDouble();
    final double origH = originalImage.height.toDouble();

    // Calculate source bounds in pixels
    final double srcX = (normCropRect.left * origW).clamp(0.0, origW - 1.0);
    final double srcY = (normCropRect.top * origH).clamp(0.0, origH - 1.0);
    final double srcW = (normCropRect.width * origW).clamp(1.0, origW - srcX);
    final double srcH = (normCropRect.height * origH).clamp(1.0, origH - srcY);

    final int targetW = srcW.round().clamp(1, origW.toInt());
    final int targetH = srcH.round().clamp(1, origH.toInt());

    // Native Skia GPU Canvas crop
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final srcRect = Rect.fromLTWH(srcX, srcY, srcW, srcH);
    final dstRect = Rect.fromLTWH(0, 0, targetW.toDouble(), targetH.toDouble());

    final paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(originalImage, srcRect, dstRect, paint);

    final picture = recorder.endRecording();
    final ui.Image croppedUiImage = await picture.toImage(targetW, targetH);

    final byteData = await croppedUiImage.toByteData(format: ui.ImageByteFormat.png);
    croppedUiImage.dispose();

    return byteData?.buffer.asUint8List();
  }

  Future<void> _confirmCrop() async {
    if (_decodedImage == null || _isProcessingCrop) return;

    setState(() => _isProcessingCrop = true);

    try {
      // 1. Ultra-fast native Skia GPU engine crop (instantly done in <100ms)
      Uint8List? croppedBytes = await _cropImageFast(_cropRect);

      // 2. Fallback to CPU task if native GPU crop returned null
      if (croppedBytes == null) {
        final res = await compute(_cropImageTask, {
          'bytes': widget.imageBytes,
          'left': _cropRect.left,
          'top': _cropRect.top,
          'width': _cropRect.width,
          'height': _cropRect.height,
        });
        croppedBytes = res?['bytes'] as Uint8List?;
      }

      if (mounted) {
        Navigator.pop(context, croppedBytes ?? widget.imageBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('크롭 중 오류가 발생했습니다: $e')),
        );
        setState(() => _isProcessingCrop = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width > 900 ? 800 : double.infinity,
        height: MediaQuery.of(context).size.height > 900 ? 800 : MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.crop_rounded, color: AppTheme.uiWhite, size: 24),
                    SizedBox(width: 10),
                    Text(
                      '사진 크롭',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.uiWhite,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _resetCrop,
                      icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFFA0A0A0)),
                      label: const Text(
                        '초기화',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          color: Color(0xFFA0A0A0),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.uiWhite),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Crop Canvas Area
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black,
                  width: double.infinity,
                  child: _isLoading || _decodedImage == null
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.uiWhite))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return _buildCropCanvas(constraints);
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Controls Bar (Ratio Selector + Orientation Swap Button)
            _buildControlsBar(),
            const SizedBox(height: 16),
            // Action Buttons (Cancel / Confirm)
            Row(
              children: [
                Expanded(
                  child: HoverInteraction(
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Center(
                          child: Text(
                            '취소',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.uiWhite,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HoverInteraction(
                    child: InkWell(
                      onTap: _isProcessingCrop ? null : _confirmCrop,
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.uiWhite,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Center(
                          child: _isProcessingCrop
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
                                  '크롭 적용',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropCanvas(BoxConstraints constraints) {
    final imgW = _decodedImage!.width.toDouble();
    final imgH = _decodedImage!.height.toDouble();
    final canvasW = constraints.maxWidth;
    final canvasH = constraints.maxHeight;

    // Calculate fitted image rect inside canvas
    final scale = mathFitScale(imgW, imgH, canvasW, canvasH);
    final displayedW = imgW * scale;
    final displayedH = imgH * scale;
    final offsetX = (canvasW - displayedW) / 2;
    final offsetY = (canvasH - displayedH) / 2;

    final imageDisplayRect = Rect.fromLTWH(offsetX, offsetY, displayedW, displayedH);

    // Convert normalized _cropRect to pixel rect in canvas
    final cropPixelRect = Rect.fromLTWH(
      imageDisplayRect.left + _cropRect.left * displayedW,
      imageDisplayRect.top + _cropRect.top * displayedH,
      _cropRect.width * displayedW,
      _cropRect.height * displayedH,
    );

    return GestureDetector(
      onPanStart: (details) => _onPanStart(details.localPosition, cropPixelRect, imageDisplayRect),
      onPanUpdate: (details) => _onPanUpdate(details.localPosition, cropPixelRect, imageDisplayRect),
      onPanEnd: (_) => setState(() => _activeHandle = null),
      child: Stack(
        children: [
          // Render raw original image inside bounds
          Positioned.fromRect(
            rect: imageDisplayRect,
            child: RawImage(
              image: _decodedImage,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
          // Custom Painter for dim exterior, crop box grid, and drag handles
          CustomPaint(
            size: Size(canvasW, canvasH),
            painter: _CropOverlayPainter(
              imageRect: imageDisplayRect,
              cropRect: cropPixelRect,
              activeHandle: _activeHandle,
            ),
          ),
        ],
      ),
    );
  }

  void _onPanStart(Offset localPos, Rect cropPixelRect, Rect imageDisplayRect) {
    final handle = _getHitHandle(localPos, cropPixelRect);
    if (handle != null) {
      setState(() {
        _activeHandle = handle;
        _dragStartOffset = localPos;
        _initialCropRect = _cropRect;
      });
    }
  }

  void _onPanUpdate(Offset localPos, Rect cropPixelRect, Rect imageDisplayRect) {
    if (_activeHandle == null || _dragStartOffset == null || _initialCropRect == null) return;

    final delta = localPos - _dragStartOffset!;
    final normDeltaX = delta.dx / imageDisplayRect.width;
    final normDeltaY = delta.dy / imageDisplayRect.height;

    double left = _initialCropRect!.left;
    double top = _initialCropRect!.top;
    double right = _initialCropRect!.right;
    double bottom = _initialCropRect!.bottom;

    final targetRatio = _getTargetAspectRatio();

    switch (_activeHandle!) {
      case _DragHandleType.move:
        double newLeft = left + normDeltaX;
        double newTop = top + normDeltaY;
        final w = right - left;
        final h = bottom - top;

        newLeft = newLeft.clamp(0.0, 1.0 - w);
        newTop = newTop.clamp(0.0, 1.0 - h);

        setState(() {
          _cropRect = Rect.fromLTWH(newLeft, newTop, w, h);
        });
        return;

      case _DragHandleType.topLeft:
        left += normDeltaX;
        top += normDeltaY;
        break;
      case _DragHandleType.topRight:
        right += normDeltaX;
        top += normDeltaY;
        break;
      case _DragHandleType.bottomLeft:
        left += normDeltaX;
        bottom += normDeltaY;
        break;
      case _DragHandleType.bottomRight:
        right += normDeltaX;
        bottom += normDeltaY;
        break;
      case _DragHandleType.left:
        left += normDeltaX;
        break;
      case _DragHandleType.right:
        right += normDeltaX;
        break;
      case _DragHandleType.top:
        top += normDeltaY;
        break;
      case _DragHandleType.bottom:
        bottom += normDeltaY;
        break;
    }

    // Clamp normalized values inside [0..1]
    left = left.clamp(0.0, right - 0.05);
    top = top.clamp(0.0, bottom - 0.05);
    right = right.clamp(left + 0.05, 1.0);
    bottom = bottom.clamp(top + 0.05, 1.0);

    double newW = right - left;
    double newH = bottom - top;

    // Apply aspect ratio constraint if active preset is fixed
    if (targetRatio != null) {
      final imgW = _decodedImage!.width.toDouble();
      final imgH = _decodedImage!.height.toDouble();

      // Current ratio in pixels
      final currentPixelRatio = (newW * imgW) / (newH * imgH);

      if ((currentPixelRatio - targetRatio).abs() > 0.01) {
        if (_activeHandle == _DragHandleType.left || _activeHandle == _DragHandleType.right) {
          newH = (newW * imgW / targetRatio) / imgH;
          if (top + newH > 1.0) newH = 1.0 - top;
        } else {
          newW = (newH * imgH * targetRatio) / imgW;
          if (left + newW > 1.0) newW = 1.0 - left;
        }
      }
    }

    setState(() {
      _cropRect = Rect.fromLTWH(left, top, newW, newH);
    });
  }

  _DragHandleType? _getHitHandle(Offset touch, Rect cropRect) {
    const touchRadius = 24.0;

    // Corners
    if ((touch - cropRect.topLeft).distance <= touchRadius) return _DragHandleType.topLeft;
    if ((touch - cropRect.topRight).distance <= touchRadius) return _DragHandleType.topRight;
    if ((touch - cropRect.bottomLeft).distance <= touchRadius) return _DragHandleType.bottomLeft;
    if ((touch - cropRect.bottomRight).distance <= touchRadius) return _DragHandleType.bottomRight;

    // Sides
    if ((touch.dx - cropRect.left).abs() <= touchRadius && touch.dy >= cropRect.top && touch.dy <= cropRect.bottom) {
      return _DragHandleType.left;
    }
    if ((touch.dx - cropRect.right).abs() <= touchRadius && touch.dy >= cropRect.top && touch.dy <= cropRect.bottom) {
      return _DragHandleType.right;
    }
    if ((touch.dy - cropRect.top).abs() <= touchRadius && touch.dx >= cropRect.left && touch.dx <= cropRect.right) {
      return _DragHandleType.top;
    }
    if ((touch.dy - cropRect.bottom).abs() <= touchRadius && touch.dx >= cropRect.left && touch.dx <= cropRect.right) {
      return _DragHandleType.bottom;
    }

    // Inside rect -> Move
    if (cropRect.contains(touch)) return _DragHandleType.move;

    return null;
  }

  Widget _buildControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Ratio Presets horizontal list
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRatioChip('자유', CropRatioType.custom),
                      _buildRatioChip('1:1', CropRatioType.ratio1x1),
                      _buildRatioChip(_isPortrait ? '2:3' : '3:2', CropRatioType.ratio3x2),
                      _buildRatioChip(_isPortrait ? '3:4' : '4:3', CropRatioType.ratio4x3),
                      _buildRatioChip(_isPortrait ? '9:16' : '16:9', CropRatioType.ratio16x9),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 28, color: Colors.white24),
              const SizedBox(width: 8),
              // Orientation Swap Toggle Button (가로/세로 전환)
              HoverInteraction(
                child: InkWell(
                  onTap: _toggleOrientation,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.uiWhite.withAlpha(50),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPortrait ? Icons.stay_current_portrait_rounded : Icons.stay_current_landscape_rounded,
                          color: AppTheme.uiWhite,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isPortrait ? '세로' : '가로',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.uiWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatioChip(String label, CropRatioType preset) {
    final isSelected = _selectedPreset == preset;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: HoverInteraction(
        child: ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => _applyAspectRatio(preset),
          selectedColor: AppTheme.uiWhite,
          backgroundColor: const Color(0xFF3A3A3C),
          labelStyle: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black : AppTheme.uiWhite,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide.none,
          showCheckmark: false,
        ),
      ),
    );
  }

  static double mathFitScale(double srcW, double srcH, double maxW, double maxH) {
    final scaleW = maxW / srcW;
    final scaleH = maxH / srcH;
    return scaleW < scaleH ? scaleW : scaleH;
  }
}

enum _DragHandleType {
  move,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  left,
  right,
  top,
  bottom,
}

class _CropOverlayPainter extends CustomPainter {
  final Rect imageRect;
  final Rect cropRect;
  final _DragHandleType? activeHandle;

  _CropOverlayPainter({
    required this.imageRect,
    required this.cropRect,
    required this.activeHandle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dim exterior area outside cropRect
    final dimPaint = Paint()..color = Colors.black.withAlpha(160);

    final path = Path()
      ..addRect(imageRect)
      ..addRect(cropRect);
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dimPaint);

    // 2. Crop rect border
    final borderPaint = Paint()
      ..color = AppTheme.uiWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(cropRect, borderPaint);

    // 3. Grid lines (3x3 Rule of thirds)
    final gridPaint = Paint()
      ..color = AppTheme.uiWhite.withAlpha(90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cellW = cropRect.width / 3;
    final cellH = cropRect.height / 3;

    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(cropRect.left + cellW * i, cropRect.top),
        Offset(cropRect.left + cellW * i, cropRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + cellH * i),
        Offset(cropRect.right, cropRect.top + cellH * i),
        gridPaint,
      );
    }

    // 4. Corner handles
    final handlePaint = Paint()
      ..color = AppTheme.uiWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.square;

    const cornerLen = 16.0;

    // Top-Left
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(cornerLen, 0), handlePaint);
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(0, cornerLen), handlePaint);

    // Top-Right
    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(-cornerLen, 0), handlePaint);
    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(0, cornerLen), handlePaint);

    // Bottom-Left
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(cornerLen, 0), handlePaint);
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(0, -cornerLen), handlePaint);

    // Bottom-Right
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(-cornerLen, 0), handlePaint);
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(0, -cornerLen), handlePaint);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect ||
        oldDelegate.imageRect != imageRect ||
        oldDelegate.activeHandle != activeHandle;
  }
}

// Background Isolate Crop Task
Map<String, dynamic>? _cropImageTask(Map<String, dynamic> params) {
  try {
    final Uint8List rawBytes = params['bytes'];
    final double normLeft = params['left'];
    final double normTop = params['top'];
    final double normWidth = params['width'];
    final double normHeight = params['height'];

    final decoded = img_lib.decodeImage(rawBytes);
    if (decoded == null) return null;

    final cropX = (normLeft * decoded.width).round().clamp(0, decoded.width - 1);
    final cropY = (normTop * decoded.height).round().clamp(0, decoded.height - 1);
    final cropW = (normWidth * decoded.width).round().clamp(1, decoded.width - cropX);
    final cropH = (normHeight * decoded.height).round().clamp(1, decoded.height - cropY);

    final croppedImg = img_lib.copyCrop(
      decoded,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    final croppedJpg = img_lib.encodeJpg(croppedImg, quality: 95);
    return {'bytes': Uint8List.fromList(croppedJpg)};
  } catch (e) {
    debugPrint('Crop task failed: $e');
  }
  return null;
}
