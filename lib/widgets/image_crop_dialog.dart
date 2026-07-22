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

  // Normalized crop edges in [0..1] relative to original image size
  // Stored as raw doubles to avoid Rect LTWH↔LTRB conversion drift.
  double _cropL = 0.0;
  double _cropT = 0.0;
  double _cropR = 1.0;
  double _cropB = 1.0;

  // Active drag state
  _DragHandleType? _activeHandle;
  Offset? _dragStartOffset;
  // Snapshot of crop edges at drag start
  double _initL = 0.0, _initT = 0.0, _initR = 1.0, _initB = 1.0;

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
        final currentW = _cropR - _cropL;
        final currentH = _cropB - _cropT;
        final imgW = _decodedImage!.width.toDouble();
        final imgH = _decodedImage!.height.toDouble();

        final absW = currentW * imgW;
        final absH = currentH * imgH;

        double normW = absH / imgW;
        double normH = absW / imgH;

        if (normW > 1.0 || normH > 1.0) {
          final scale = (normW > normH) ? (1.0 / normW) : (1.0 / normH);
          normW *= scale;
          normH *= scale;
        }

        final cx = (_cropL + _cropR) / 2.0;
        final cy = (_cropT + _cropB) / 2.0;

        double left = cx - normW / 2;
        double top = cy - normH / 2;

        if (left < 0) left = 0;
        if (top < 0) top = 0;
        if (left + normW > 1.0) left = 1.0 - normW;
        if (top + normH > 1.0) top = 1.0 - normH;

        _cropL = left; _cropT = top;
        _cropR = left + normW; _cropB = top + normH;
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

    final cx = ((_cropL + _cropR) / 2.0).clamp(normW / 2, 1.0 - normW / 2);
    final cy = ((_cropT + _cropB) / 2.0).clamp(normH / 2, 1.0 - normH / 2);

    _cropL = cx - normW / 2;
    _cropT = cy - normH / 2;
    _cropR = _cropL + normW;
    _cropB = _cropT + normH;
  }

  void _resetCrop() {
    setState(() {
      _selectedPreset = CropRatioType.custom;
      _cropL = 0.0; _cropT = 0.0; _cropR = 1.0; _cropB = 1.0;
    });
  }

  Future<Uint8List?> _cropImageFast() async {
    if (_decodedImage == null) return null;

    final originalImage = _decodedImage!;
    final double origW = originalImage.width.toDouble();
    final double origH = originalImage.height.toDouble();

    final double srcX = (_cropL * origW).clamp(0.0, origW - 1.0);
    final double srcY = (_cropT * origH).clamp(0.0, origH - 1.0);
    final double srcW = ((_cropR - _cropL) * origW).clamp(1.0, origW - srcX);
    final double srcH = ((_cropB - _cropT) * origH).clamp(1.0, origH - srcY);

    final int targetW = srcW.round().clamp(1, origW.toInt());
    final int targetH = srcH.round().clamp(1, origH.toInt());

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
      Uint8List? croppedBytes = await _cropImageFast();

      if (croppedBytes == null) {
        final res = await compute(_cropImageTask, {
          'bytes': widget.imageBytes,
          'left': _cropL,
          'top': _cropT,
          'width': _cropR - _cropL,
          'height': _cropB - _cropT,
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

    final scale = mathFitScale(imgW, imgH, canvasW, canvasH);
    final displayedW = imgW * scale;
    final displayedH = imgH * scale;
    final offsetX = (canvasW - displayedW) / 2;
    final offsetY = (canvasH - displayedH) / 2;

    final imageDisplayRect = Rect.fromLTWH(offsetX, offsetY, displayedW, displayedH);

    // Build pixel rect directly from raw LTRB — no Rect width/height roundtrip
    final cropPixelRect = Rect.fromLTRB(
      offsetX + _cropL * displayedW,
      offsetY + _cropT * displayedH,
      offsetX + _cropR * displayedW,
      offsetY + _cropB * displayedH,
    );

    return GestureDetector(
      onPanStart: (details) => _onPanStart(details.localPosition, cropPixelRect, imageDisplayRect),
      onPanUpdate: (details) => _onPanUpdate(details.localPosition, imageDisplayRect),
      onPanEnd: (_) => setState(() => _activeHandle = null),
      child: Stack(
        children: [
          Positioned.fromRect(
            rect: imageDisplayRect,
            child: RawImage(
              image: _decodedImage,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
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
        _initL = _cropL; _initT = _cropT; _initR = _cropR; _initB = _cropB;
      });
    }
  }

  void _onPanUpdate(Offset localPos, Rect imageDisplayRect) {
    if (_activeHandle == null || _dragStartOffset == null || _decodedImage == null) return;

    final delta = localPos - _dragStartOffset!;
    final normDeltaX = delta.dx / imageDisplayRect.width;
    final normDeltaY = delta.dy / imageDisplayRect.height;

    final targetRatio = _getTargetAspectRatio();

    // Move handle: translate the whole rect
    if (_activeHandle == _DragHandleType.move) {
      final w = _initR - _initL;
      final h = _initB - _initT;
      final nl = (_initL + normDeltaX).clamp(0.0, 1.0 - w);
      final nt = (_initT + normDeltaY).clamp(0.0, 1.0 - h);
      setState(() {
        _cropL = nl; _cropT = nt; _cropR = nl + w; _cropB = nt + h;
      });
      return;
    }

    final double initW = _initR - _initL;
    final double initH = _initB - _initT;
    const double minSize = 0.05;

    if (targetRatio != null) {
      final imgW = _decodedImage!.width.toDouble();
      final imgH = _decodedImage!.height.toDouble();
      final k = (imgH / imgW) * targetRatio; // normW / normH

      double newL = _initL, newT = _initT, newR = _initR, newB = _initB;

      switch (_activeHandle!) {
        case _DragHandleType.bottomRight: {
          // Anchor: Top-Left (_initL, _initT)
          final dWx = normDeltaX;
          final dWy = normDeltaY * k;
          final requestedW = initW + ((dWx.abs() > dWy.abs()) ? dWx : dWy);
          final maxWx = 1.0 - _initL;
          final maxWy = (1.0 - _initT) * k;
          final maxW = (maxWx < maxWy) ? maxWx : maxWy;
          final finalW = requestedW.clamp(minSize, maxW);
          final finalH = finalW / k;
          newL = _initL;
          newT = _initT;
          newR = _initL + finalW;
          newB = _initT + finalH;
          break;
        }
        case _DragHandleType.bottomLeft: {
          // Anchor: Top-Right (_initR, _initT)
          final dWx = -normDeltaX;
          final dWy = normDeltaY * k;
          final requestedW = initW + ((dWx.abs() > dWy.abs()) ? dWx : dWy);
          final maxWx = _initR;
          final maxWy = (1.0 - _initT) * k;
          final maxW = (maxWx < maxWy) ? maxWx : maxWy;
          final finalW = requestedW.clamp(minSize, maxW);
          final finalH = finalW / k;
          newR = _initR;
          newT = _initT;
          newL = _initR - finalW;
          newB = _initT + finalH;
          break;
        }
        case _DragHandleType.topRight: {
          // Anchor: Bottom-Left (_initL, _initB)
          final dWx = normDeltaX;
          final dWy = -normDeltaY * k;
          final requestedW = initW + ((dWx.abs() > dWy.abs()) ? dWx : dWy);
          final maxWx = 1.0 - _initL;
          final maxWy = _initB * k;
          final maxW = (maxWx < maxWy) ? maxWx : maxWy;
          final finalW = requestedW.clamp(minSize, maxW);
          final finalH = finalW / k;
          newL = _initL;
          newB = _initB;
          newR = _initL + finalW;
          newT = _initB - finalH;
          break;
        }
        case _DragHandleType.topLeft: {
          // Anchor: Bottom-Right (_initR, _initB)
          final dWx = -normDeltaX;
          final dWy = -normDeltaY * k;
          final requestedW = initW + ((dWx.abs() > dWy.abs()) ? dWx : dWy);
          final maxWx = _initR;
          final maxWy = _initB * k;
          final maxW = (maxWx < maxWy) ? maxWx : maxWy;
          final finalW = requestedW.clamp(minSize, maxW);
          final finalH = finalW / k;
          newR = _initR;
          newB = _initB;
          newL = _initR - finalW;
          newT = _initB - finalH;
          break;
        }
        case _DragHandleType.left: {
          // Anchor: Top-Right (Right & Top fixed)
          final requestedW = initW - normDeltaX;
          final maxWx = _initR;
          final maxWy = (1.0 - _initT) * k;
          final maxW = (maxWx < maxWy) ? maxWx : maxWy;
          final finalW = requestedW.clamp(minSize, maxW);
          final finalH = finalW / k;
          newR = _initR;
          newT = _initT;
          newL = _initR - finalW;
          newB = _initT + finalH;
          break;
        }
        case _DragHandleType.right: {
          // Anchor: Top-Left (Left & Top fixed)
          final requestedW = initW + normDeltaX;
          final maxWx = 1.0 - _initL;
          final maxWy = (1.0 - _initT) * k;
          final maxW = (maxWx < maxWy) ? maxWx : maxWy;
          final finalW = requestedW.clamp(minSize, maxW);
          final finalH = finalW / k;
          newL = _initL;
          newT = _initT;
          newR = _initL + finalW;
          newB = _initT + finalH;
          break;
        }
        case _DragHandleType.top: {
          // Anchor: Bottom-Left (Left & Bottom fixed)
          final requestedW = (initH - normDeltaY) * k;
          final maxWx = 1.0 - _initL;
          final maxWy = _initB * k;
          final maxW = (maxWx < maxWy) ? maxWx : maxWy;
          final finalW = requestedW.clamp(minSize, maxW);
          final finalH = finalW / k;
          newL = _initL;
          newB = _initB;
          newR = _initL + finalW;
          newT = _initB - finalH;
          break;
        }
        case _DragHandleType.bottom: {
          // Anchor: Top-Left (Left & Top fixed)
          final requestedW = (initH + normDeltaY) * k;
          final maxWx = 1.0 - _initL;
          final maxWy = (1.0 - _initT) * k;
          final maxW = (maxWx < maxWy) ? maxWx : maxWy;
          final finalW = requestedW.clamp(minSize, maxW);
          final finalH = finalW / k;
          newL = _initL;
          newT = _initT;
          newR = _initL + finalW;
          newB = _initT + finalH;
          break;
        }
        case _DragHandleType.move:
          break;
      }

      setState(() {
        _cropL = newL;
        _cropT = newT;
        _cropR = newR;
        _cropB = newB;
      });
    } else {
      // Free aspect ratio mode
      double newL = _initL, newT = _initT, newR = _initR, newB = _initB;

      switch (_activeHandle!) {
        case _DragHandleType.topLeft:
          newL = (_initL + normDeltaX).clamp(0.0, _initR - 0.05);
          newT = (_initT + normDeltaY).clamp(0.0, _initB - 0.05);
          newR = _initR;
          newB = _initB;
          break;
        case _DragHandleType.topRight:
          newR = (_initR + normDeltaX).clamp(_initL + 0.05, 1.0);
          newT = (_initT + normDeltaY).clamp(0.0, _initB - 0.05);
          newL = _initL;
          newB = _initB;
          break;
        case _DragHandleType.bottomLeft:
          newL = (_initL + normDeltaX).clamp(0.0, _initR - 0.05);
          newB = (_initB + normDeltaY).clamp(_initT + 0.05, 1.0);
          newR = _initR;
          newT = _initT;
          break;
        case _DragHandleType.bottomRight:
          newR = (_initR + normDeltaX).clamp(_initL + 0.05, 1.0);
          newB = (_initB + normDeltaY).clamp(_initT + 0.05, 1.0);
          newL = _initL;
          newT = _initT;
          break;
        case _DragHandleType.left:
          newL = (_initL + normDeltaX).clamp(0.0, _initR - 0.05);
          newR = _initR;
          break;
        case _DragHandleType.right:
          newR = (_initR + normDeltaX).clamp(_initL + 0.05, 1.0);
          newL = _initL;
          break;
        case _DragHandleType.top:
          newT = (_initT + normDeltaY).clamp(0.0, _initB - 0.05);
          newB = _initB;
          break;
        case _DragHandleType.bottom:
          newB = (_initB + normDeltaY).clamp(_initT + 0.05, 1.0);
          newT = _initT;
          break;
        case _DragHandleType.move:
          break;
      }

      setState(() {
        _cropL = newL;
        _cropT = newT;
        _cropR = newR;
        _cropB = newB;
      });
    }
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
