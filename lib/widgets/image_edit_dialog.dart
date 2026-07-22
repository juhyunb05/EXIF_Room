import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/models/edit_data.dart';
import '../theme/app_theme.dart';
import 'hover_interaction.dart';

enum CropRatioType {
  original,
  custom,
  ratio1x1,
  ratio3x2,
  ratio4x3,
  ratio16x9,
}

class ImageEditDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final EditData? initialEditData;

  const ImageEditDialog({
    super.key,
    required this.imageBytes,
    this.initialEditData,
  });

  static Future<EditData?> show(
    BuildContext context,
    Uint8List imageBytes, {
    EditData? initialEditData,
  }) {
    return showDialog<EditData>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => ImageEditDialog(
        imageBytes: imageBytes,
        initialEditData: initialEditData,
      ),
    );
  }

  @override
  State<ImageEditDialog> createState() => _ImageEditDialogState();
}

class _ImageEditDialogState extends State<ImageEditDialog> {
  ui.Image? _decodedImage;
  bool _isLoading = true;

  // Selected crop ratio & orientation
  CropRatioType _selectedPreset = CropRatioType.custom;
  bool _isPortrait = false;

  // Normalized crop rect in [0..1] relative to original image size
  Rect _cropRect = const Rect.fromLTWH(0, 0, 1, 1);

  // Fine rotation angle in degrees (-45.0 to +45.0)
  double _fineAngle = 0.0;

  // Is user actively adjusting rotation slider?
  bool _isAdjustingAngle = false;

  // Active drag handle state for crop
  _DragHandleType? _activeHandle;
  Offset? _dragStartOffset;
  Rect? _initialCropRect;

  @override
  void initState() {
    super.initState();
    if (widget.initialEditData != null) {
      _cropRect = widget.initialEditData!.cropRect;
      _fineAngle = widget.initialEditData!.fineAngle;
    }
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
      case CropRatioType.original:
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
      if (preset == CropRatioType.original) {
        _cropRect = const Rect.fromLTWH(0, 0, 1, 1);
        _fineAngle = 0.0;
      } else {
        _updateCropRectForTargetRatio();
      }
    });
  }

  void _toggleOrientation() {
    setState(() {
      _isPortrait = !_isPortrait;
      if (_selectedPreset == CropRatioType.custom) {
        final currentW = _cropRect.width;
        final currentH = _cropRect.height;
        final imgW = _decodedImage!.width.toDouble();
        final imgH = _decodedImage!.height.toDouble();

        final absW = currentW * imgW;
        final absH = currentH * imgH;

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
      normW = 1.0;
      normH = (imgW / targetRatio) / imgH;
    } else {
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

  void _resetAll() {
    setState(() {
      _selectedPreset = CropRatioType.original;
      _cropRect = const Rect.fromLTWH(0, 0, 1, 1);
      _fineAngle = 0.0;
    });
  }

  // Exact Mathematical Adaptive Fill Scale Algorithm
  // Calculates the EXACT minimum scale factor required to ensure that all 4 corners
  // of cropPixelRect remain covered by valid photo pixels.
  // Returns 1.0 if cropPixelRect is already completely inside the rotated photo boundaries.
  double _calculateAdaptiveFillScale(Rect imageDisplayRect, Rect cropPixelRect) {
    if (_fineAngle == 0.0) return 1.0;

    final rad = _fineAngle * math.pi / 180.0;
    final cosA = math.cos(rad);
    final sinA = math.sin(rad);

    final center = imageDisplayRect.center;
    final dw = imageDisplayRect.width;
    final dh = imageDisplayRect.height;

    final corners = [
      cropPixelRect.topLeft,
      cropPixelRect.topRight,
      cropPixelRect.bottomLeft,
      cropPixelRect.bottomRight,
    ];

    double maxRequiredScale = 1.0;

    for (final corner in corners) {
      final dx = corner.dx - center.dx;
      final dy = corner.dy - center.dy;

      // Rotate corner vector back to unrotated photo coordinate frame
      final u = dx * cosA + dy * sinA;
      final v = -dx * sinA + dy * cosA;

      final reqScaleX = (2.0 * u.abs()) / dw;
      final reqScaleY = (2.0 * v.abs()) / dh;

      if (reqScaleX > maxRequiredScale) maxRequiredScale = reqScaleX;
      if (reqScaleY > maxRequiredScale) maxRequiredScale = reqScaleY;
    }

    return maxRequiredScale;
  }

  void _confirmEdit() {
    if (_decodedImage == null) return;
    final result = EditData(
      cropRect: _cropRect,
      fineAngle: _fineAngle,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width > 900 ? 840 : double.infinity,
        height: MediaQuery.of(context).size.height > 900 ? 840 : MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppTheme.uiWhite, size: 24),
                    SizedBox(width: 10),
                    Text(
                      '편집',
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
                      onPressed: _resetAll,
                      icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFFA0A0A0)),
                      label: const Text(
                        '원본으로 복원',
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
            // Unified Canvas Area (Live fine rotation preview + interactive crop overlay)
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
                            return _buildEditCanvas(constraints);
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Single Unified Controls Section (Crop Ratios + Fine Rotation Slider on the same view)
            _buildUnifiedControlsSection(),
            const SizedBox(height: 16),
            // Bottom Action Buttons (Cancel / Confirm)
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
                      onTap: _confirmEdit,
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.uiWhite,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Center(
                          child: Text(
                            '편집 적용',
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

  Widget _buildUnifiedControlsSection() {
    final angleString = _fineAngle > 0
        ? '+${_fineAngle.toStringAsFixed(1)}°'
        : '${_fineAngle.toStringAsFixed(1)}°';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Aspect Ratio Presets + Orientation Swap Button
          Row(
            children: [
              Expanded(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.06, 0.94, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildRatioChip('원본', CropRatioType.original),
                        _buildRatioChip('자유', CropRatioType.custom),
                        _buildRatioChip(_isPortrait ? '3:4' : '4:3', CropRatioType.ratio4x3),
                        _buildRatioChip(_isPortrait ? '2:3' : '3:2', CropRatioType.ratio3x2),
                        _buildRatioChip('1:1', CropRatioType.ratio1x1),
                        _buildRatioChip(_isPortrait ? '9:16' : '16:9', CropRatioType.ratio16x9),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: Colors.white24),
              const SizedBox(width: 8),
              HoverInteraction(
                child: InkWell(
                  onTap: _toggleOrientation,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.uiWhite.withAlpha(50),
                      ),
                    ),
                    child: Icon(
                      _isPortrait ? Icons.stay_current_portrait_rounded : Icons.stay_current_landscape_rounded,
                      color: AppTheme.uiWhite,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Fine Rotation Slider + Angle readout badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.rotate_right_rounded, color: Color(0xFFA0A0A0), size: 16),
                  SizedBox(width: 6),
                  Text(
                    '회전 (수평 맞춤)',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFA0A0A0),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      angleString,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.uiWhite,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _fineAngle = 0.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '0° 리셋',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 11,
                          color: Color(0xFFA0A0A0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _RulerSlider(
            value: _fineAngle,
            min: -45.0,
            max: 45.0,
            onChangeStart: () => setState(() => _isAdjustingAngle = true),
            onChangeEnd: () => setState(() => _isAdjustingAngle = false),
            onChanged: (val) {
              setState(() {
                _fineAngle = val;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditCanvas(BoxConstraints constraints) {
    final imgW = _decodedImage!.width.toDouble();
    final imgH = _decodedImage!.height.toDouble();
    final canvasW = constraints.maxWidth;
    final canvasH = constraints.maxHeight;

    final scale = mathFitScale(imgW, imgH, canvasW, canvasH);
    final displayedW = imgW * scale;
    final displayedH = imgH * scale;
    final offsetX = (canvasW - displayedW) / 2;
    final offsetY = (canvasH - displayedH) / 2;

    final imageDisplayRect = Rect.fromLTWH(offsetX, offsetY, displayedW, displayedH);

    final cropPixelRect = Rect.fromLTWH(
      imageDisplayRect.left + _cropRect.left * displayedW,
      imageDisplayRect.top + _cropRect.top * displayedH,
      _cropRect.width * displayedW,
      _cropRect.height * displayedH,
    );

    // Compute exact adaptive fill scale based on imageDisplayRect and cropPixelRect
    final fillScale = _calculateAdaptiveFillScale(imageDisplayRect, cropPixelRect);

    return GestureDetector(
      onPanStart: (details) => _onPanStart(details.localPosition, cropPixelRect, imageDisplayRect),
      onPanUpdate: (details) => _onPanUpdate(details.localPosition, cropPixelRect, imageDisplayRect),
      onPanEnd: (_) => setState(() => _activeHandle = null),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Render original image centered in canvas, rotated & scaled adaptively
          Positioned(
            left: offsetX,
            top: offsetY,
            width: displayedW,
            height: displayedH,
            child: Transform.scale(
              scale: fillScale,
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: _fineAngle * math.pi / 180.0,
                alignment: Alignment.center,
                child: RawImage(
                  image: _decodedImage,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          // Custom Painter for crop overlay & horizon alignment grid
          CustomPaint(
            size: Size(canvasW, canvasH),
            painter: _EditOverlayPainter(
              imageRect: imageDisplayRect,
              cropRect: cropPixelRect,
              activeHandle: _activeHandle,
              isAdjustingAngle: _isAdjustingAngle || _fineAngle != 0.0,
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

    left = left.clamp(0.0, right - 0.05);
    top = top.clamp(0.0, bottom - 0.05);
    right = right.clamp(left + 0.05, 1.0);
    bottom = bottom.clamp(top + 0.05, 1.0);

    double newW = right - left;
    double newH = bottom - top;

    if (targetRatio != null) {
      final imgW = _decodedImage!.width.toDouble();
      final imgH = _decodedImage!.height.toDouble();

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

    if ((touch - cropRect.topLeft).distance <= touchRadius) return _DragHandleType.topLeft;
    if ((touch - cropRect.topRight).distance <= touchRadius) return _DragHandleType.topRight;
    if ((touch - cropRect.bottomLeft).distance <= touchRadius) return _DragHandleType.bottomLeft;
    if ((touch - cropRect.bottomRight).distance <= touchRadius) return _DragHandleType.bottomRight;

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

    if (cropRect.contains(touch)) return _DragHandleType.move;

    return null;
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

class _EditOverlayPainter extends CustomPainter {
  final Rect imageRect;
  final Rect cropRect;
  final _DragHandleType? activeHandle;
  final bool isAdjustingAngle;

  _EditOverlayPainter({
    required this.imageRect,
    required this.cropRect,
    required this.activeHandle,
    required this.isAdjustingAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dim entire canvas exterior area outside cropRect
    final dimPaint = Paint()..color = Colors.black.withAlpha(185);

    final outerCanvasRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(outerCanvasRect)
      ..addRect(cropRect);
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dimPaint);

    // 2. Alignment grid (dense grid lines visible when fine angle != 0 or adjusting)
    if (isAdjustingAngle) {
      final alignGridPaint = Paint()
        ..color = AppTheme.uiWhite.withAlpha(60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      const gridCount = 6;
      final stepW = cropRect.width / gridCount;
      final stepH = cropRect.height / gridCount;

      for (int i = 1; i < gridCount; i++) {
        canvas.drawLine(
          Offset(cropRect.left + stepW * i, cropRect.top),
          Offset(cropRect.left + stepW * i, cropRect.bottom),
          alignGridPaint,
        );
        canvas.drawLine(
          Offset(cropRect.left, cropRect.top + stepH * i),
          Offset(cropRect.right, cropRect.top + stepH * i),
          alignGridPaint,
        );
      }
    }

    // 3. Crop rect border
    final borderPaint = Paint()
      ..color = AppTheme.uiWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(cropRect, borderPaint);

    // 4. Rule of thirds 3x3 grid lines
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

    // 5. Corner handles
    final handlePaint = Paint()
      ..color = AppTheme.uiWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.square;

    const cornerLen = 16.0;

    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(cornerLen, 0), handlePaint);
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(0, cornerLen), handlePaint);

    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(-cornerLen, 0), handlePaint);
    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(0, cornerLen), handlePaint);

    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(cornerLen, 0), handlePaint);
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(0, -cornerLen), handlePaint);

    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(-cornerLen, 0), handlePaint);
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(0, -cornerLen), handlePaint);
  }

  @override
  bool shouldRepaint(covariant _EditOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect ||
        oldDelegate.imageRect != imageRect ||
        oldDelegate.activeHandle != activeHandle ||
        oldDelegate.isAdjustingAngle != isAdjustingAngle;
  }
}

class _RulerSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final VoidCallback? onChangeStart;
  final VoidCallback? onChangeEnd;

  const _RulerSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
  });

  @override
  State<_RulerSlider> createState() => _RulerSliderState();
}

class _RulerSliderState extends State<_RulerSlider> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2E).withAlpha(180),
          borderRadius: BorderRadius.circular(24),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) {
            widget.onChangeStart?.call();
          },
          onHorizontalDragUpdate: (details) {
            const pixelsPerDegree = 7.0;
            final deltaDegrees = -details.delta.dx / pixelsPerDegree;
            final newValue = (widget.value + deltaDegrees).clamp(widget.min, widget.max);
            widget.onChanged(double.parse(newValue.toStringAsFixed(1)));
          },
          onHorizontalDragEnd: (_) {
            widget.onChangeEnd?.call();
          },
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [0.0, 0.18, 0.82, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: CustomPaint(
              painter: _RulerPainter(
                value: widget.value,
                min: widget.min,
                max: widget.max,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;

  _RulerPainter({
    required this.value,
    required this.min,
    required this.max,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const pixelsPerDegree = 7.0;

    final minorTickPaint = Paint()
      ..color = Colors.white.withAlpha(50)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final tick5Paint = Paint()
      ..color = Colors.white.withAlpha(120)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final tick10Paint = Paint()
      ..color = Colors.white.withAlpha(180)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final centerIndicatorPaint = Paint()
      ..color = const Color(0xFF4C8CFF)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final visibleDegreesRange = (size.width / (2 * pixelsPerDegree)).ceil() + 2;
    final startDeg = (value - visibleDegreesRange).floor().clamp(min.floor(), max.floor());
    final endDeg = (value + visibleDegreesRange).ceil().clamp(min.ceil(), max.ceil());

    for (int deg = startDeg; deg <= endDeg; deg++) {
      final x = centerX + (deg - value) * pixelsPerDegree;
      if (x < 0 || x > size.width) continue;

      final double tickHeight;
      final Paint paint;

      if (deg % 10 == 0) {
        tickHeight = 22.0;
        paint = tick10Paint;
      } else if (deg % 5 == 0) {
        tickHeight = 14.0;
        paint = tick5Paint;
      } else {
        tickHeight = 8.0;
        paint = minorTickPaint;
      }

      canvas.drawLine(
        Offset(x, centerY - tickHeight / 2),
        Offset(x, centerY + tickHeight / 2),
        paint,
      );
    }

    const centerLineHeight = 24.0;
    canvas.drawLine(
      Offset(centerX, centerY - centerLineHeight / 2),
      Offset(centerX, centerY + centerLineHeight / 2),
      centerIndicatorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.min != min || oldDelegate.max != max;
  }
}
