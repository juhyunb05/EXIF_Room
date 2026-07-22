import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'image_processor.dart';
import '../../core/models/exif_data.dart';
import '../../core/models/poster_project.dart';
import '../../core/services/database_service.dart';
import '../../core/services/file_manager_service.dart';
import '../../core/models/edit_data.dart';
import '../../core/utils/poster_layout_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/poster_canvas.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/hover_interaction.dart';
import '../../widgets/image_edit_dialog.dart';
import 'widgets/editor_action_panel.dart';
import 'widgets/editor_form.dart';

class EditorScreen extends StatefulWidget {
  final String imagePath;
  final ExifData? initialExif;
  final Uint8List? webImageBytes;

  const EditorScreen({
    super.key,
    required this.imagePath,
    this.initialExif,
    this.webImageBytes,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late ExifData _currentExif;
  bool _isExporting = false;
  int _imageRotation = 0;
  EditData _editData = const EditData();

  late final TextEditingController _cameraMakeController;
  late final TextEditingController _cameraNameController;
  late final TextEditingController _locationController;
  late final TextEditingController _focalLengthController;
  late final TextEditingController _apertureController;
  late final TextEditingController _shutterSpeedController;
  late final TextEditingController _isoController;

  @override
  void initState() {
    super.initState();
    _currentExif = widget.initialExif ?? ExifData();
    _cameraMakeController =
        TextEditingController(text: _currentExif.cameraMake);
    _cameraNameController =
        TextEditingController(text: _currentExif.cameraName);
    _locationController = TextEditingController(text: _currentExif.location);
    _focalLengthController =
        TextEditingController(text: _currentExif.focalLength);
    _apertureController = TextEditingController(text: _currentExif.aperture);
    _shutterSpeedController =
        TextEditingController(text: _currentExif.shutterSpeed);
    _isoController = TextEditingController(text: _currentExif.iso);
  }

  @override
  void dispose() {
    _cameraMakeController.dispose();
    _cameraNameController.dispose();
    _locationController.dispose();
    _focalLengthController.dispose();
    _apertureController.dispose();
    _shutterSpeedController.dispose();
    _isoController.dispose();

    // Let Flutter manage cache; avoid aggressive clearing to reduce jank.
    super.dispose();
  }

  Future<void> _exportPoster() async {
    setState(() => _isExporting = true);

    Uint8List? fileBytes;
    Uint8List? imageBytes;
    Uint8List? thumbnailBytes;

    try {
      if (widget.webImageBytes != null) {
        fileBytes = widget.webImageBytes!;
      } else if (kIsWeb) {
        final response = await http.get(Uri.parse(widget.imagePath));
        fileBytes = response.bodyBytes;
      } else {
        fileBytes = await File(widget.imagePath).readAsBytes();
      }

      final codec = await ui.instantiateImageCodec(fileBytes);
      final frameInfo = await codec.getNextFrame();
      final ui.Image img = frameInfo.image;

      double ratio =
          (img.width * _editData.cropRect.width) /
              (img.height * _editData.cropRect.height);
      if (_imageRotation % 2 != 0) {
        ratio = 1.0 / ratio;
      }
      final double imageHeight = 2400 / ratio;

      img.dispose();

      int nameLength =
          (_currentExif.cameraName ?? "UNKNOWN CAMERA").length;
      int nameLines = (nameLength / 16).ceil();
      if (nameLines < 1) nameLines = 1;

      double leftHeight =
          PosterLayoutConfig.leftBrandHeight +
          PosterLayoutConfig.modelToSpacer +
          (PosterLayoutConfig.leftBrandHeight * nameLines);
      if (_currentExif.cameraMake != null &&
          _currentExif.cameraMake!.isNotEmpty) {
        leftHeight += PosterLayoutConfig.leftBrandSpacer + 80;
      }
      if (_currentExif.location != null &&
          _currentExif.location!.isNotEmpty) {
        leftHeight += PosterLayoutConfig.locationTextHeight +
            PosterLayoutConfig.locationSpacer;
      }

      double rightHeight = PosterLayoutConfig.rightBlockFixedHeight;

      final double textHeight =
          leftHeight > rightHeight ? leftHeight : rightHeight;

      final double totalHeight = PosterLayoutConfig.topPadding +
          imageHeight +
          PosterLayoutConfig.imageToInfoPadding +
          textHeight +
          PosterLayoutConfig.bottomPadding;

      final captureResult = await _captureOffscreenWidget(
        Material(
          child: PosterCanvas(
            imagePath: widget.imagePath,
            webImageBytes: widget.webImageBytes,
            exifData: _currentExif,
            editData: _editData,
            imageRotation: _imageRotation,
            isPreview: false,
          ),
        ),
        Size(PosterLayoutConfig.exportWidth, totalHeight),
        pixelRatio: 1.0,
      );

      final processedData = await processExportedImageHelper(
        rawRgba: captureResult['rawRgba'],
        width: captureResult['width'],
        height: captureResult['height'],
      );

      imageBytes = processedData['jpg'];
      thumbnailBytes = processedData['thumb'];

      final fileName =
          FileManagerService.generateFileName(_currentExif, 'jpg');
      String? filePath;

      if (!kIsWeb) {
        final directory = await getApplicationDocumentsDirectory();
        filePath = p.join(directory.path, fileName);
        final file = File(filePath);
        if (imageBytes != null) {
          await file.writeAsBytes(imageBytes);
        }
      }

      final project = PosterProject(
        originalImagePath: widget.imagePath,
        exportedImagePath: filePath,
        exif: _currentExif,
        createdAt: DateTime.now(),
        exported: true,
        webExportedImageBytes: null,
        thumbnailBytes: thumbnailBytes,
      );

      await DatabaseService().saveProject(
        project,
        originalImageBytes: kIsWeb ? imageBytes : null,
      );

      if (mounted) {
        _showSuccessSheet(
          kIsWeb ? fileName : filePath!,
          webBytes: kIsWeb ? imageBytes : null,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Export failed: $e")),
        );
      }
    } finally {
      fileBytes = null;
      imageBytes = null;
      thumbnailBytes = null;

      // Let Flutter manage cache; avoid aggressive clearing.
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<Map<String, dynamic>> _captureOffscreenWidget(
    Widget widget,
    Size targetSize, {
    double pixelRatio = 1.0,
  }) async {
    final GlobalKey boundaryKey = GlobalKey();

    final OverlayEntry entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: -targetSize.width * 2,
          top: -targetSize.height * 2,
          child: Material(
            color: Colors.transparent,
            child: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox(
                width: targetSize.width,
                height: targetSize.height,
                child: widget,
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(entry);

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final RenderRepaintBoundary boundary =
          boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image image =
          await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return {
        'rawRgba': byteData!.buffer.asUint8List(),
        'width': image.width,
        'height': image.height,
      };
    } finally {
      entry.remove();
    }
  }

  void _showSuccessSheet(String path, {Uint8List? webBytes}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(153),
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF262626),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Text(
                  "저장완료",
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.uiWhite,
                  ),
                ),
              ),
              Divider(height: 1, color: AppTheme.uiWhite.withAlpha(31)),
              _buildDialogButton(
                icon: Icons.save_alt_rounded,
                text: "저장하기",
                onTap: () async {
                  Navigator.pop(dialogContext);
                  if (kIsWeb) {
                    if (webBytes != null) {
                      await FileManagerService.shareOrSaveImage(
                        path,
                        false,
                        webBytes: webBytes,
                      );
                    }
                  } else {
                    await FileManagerService.shareOrSaveImage(
                      path,
                      Platform.isWindows,
                      saveToDevice: true,
                    );
                  }
                  if (!mounted) return;
                  Navigator.pop(context, true);
                },
              ),
              if (!kIsWeb && !Platform.isWindows) ...[
                Divider(height: 1, color: AppTheme.uiWhite.withAlpha(31)),
                _buildDialogButton(
                  icon: Icons.share_outlined,
                  text: "공유",
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await FileManagerService.shareOrSaveImage(path, false);
                    if (!mounted) return;
                    Navigator.pop(context, true);
                  },
                ),
              ],
              Divider(height: 1, color: AppTheme.uiWhite.withAlpha(31)),
              _buildDialogButton(
                icon: Icons.check_rounded,
                text: "완료",
                onTap: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context, true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return HoverInteraction(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.uiWhite, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.uiWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 1200;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          LoadingOverlay(isLoading: _isExporting, text: '저장중...'),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _buildPreviewArea(),
        ),
        Container(
          width: 400,
          decoration: const BoxDecoration(
            color: AppTheme.canvasColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(-5, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EditorActionPanel(
                          onEdit: _openEditDialog,
                          onRotate: () {
                            setState(() {
                              _imageRotation = (_imageRotation + 1) % 4;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        EditorForm(
                          currentExif: _currentExif,
                          cameraMakeController: _cameraMakeController,
                          cameraNameController: _cameraNameController,
                          locationController: _locationController,
                          focalLengthController: _focalLengthController,
                          apertureController: _apertureController,
                          shutterSpeedController: _shutterSpeedController,
                          isoController: _isoController,
                          onExifChanged: (exif) => setState(() => _currentExif = exif),
                          parentContext: context,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(left: 24, right: 24, bottom: 20, top: 10),
                child: _buildBottomButtons(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Positioned(
          top: size.height * 0.25,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: AppTheme.canvasColor,
          ),
        ),
        Positioned.fill(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                expandedHeight: size.height * 0.55,
                collapsedHeight: size.height * 0.25,
                toolbarHeight: 0,
                backgroundColor: AppTheme.backgroundColor,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: SafeArea(
                  bottom: false,
                  child: _buildPreviewArea(),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _EditButtonsHeaderDelegate(
                  child: EditorActionPanel(
                    onEdit: _openEditDialog,
                    onRotate: () {
                      setState(() {
                        _imageRotation = (_imageRotation + 1) % 4;
                      });
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  constraints:
                      BoxConstraints(minHeight: size.height * 0.45),
                  padding:
                      const EdgeInsets.fromLTRB(24, 16, 24, 120),
                  child: EditorForm(
                    currentExif: _currentExif,
                    cameraMakeController: _cameraMakeController,
                    cameraNameController: _cameraNameController,
                    locationController: _locationController,
                    focalLengthController: _focalLengthController,
                    apertureController: _apertureController,
                    shutterSpeedController: _shutterSpeedController,
                    isoController: _isoController,
                    onExifChanged: (exif) => setState(() => _currentExif = exif),
                    parentContext: context,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.canvasColor.withAlpha(0),
                  AppTheme.canvasColor,
                ],
              ),
            ),
            padding:
                const EdgeInsets.only(left: 24, right: 24, bottom: 20, top: 24),
            child: SafeArea(
              top: false,
              child: _buildBottomButtons(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditDialog() async {
    Uint8List? sourceBytes = widget.webImageBytes;
    if (sourceBytes == null) {
      if (kIsWeb) {
        final response = await http.get(Uri.parse(widget.imagePath));
        sourceBytes = response.bodyBytes;
      } else {
        sourceBytes = await File(widget.imagePath).readAsBytes();
      }
    }

    if (!mounted || sourceBytes.isEmpty) return;

    final result = await ImageEditDialog.show(
      context,
      sourceBytes,
      initialEditData: _editData,
    );

    if (result != null && mounted) {
      setState(() {
        _editData = result;
      });
    }
  }

  Widget _buildPreviewArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Center(
        child: PosterCanvas(
          imagePath: widget.imagePath,
          webImageBytes: widget.webImageBytes,
          exifData: _currentExif,
          editData: _editData,
          imageRotation: _imageRotation,
          isPreview: true,
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: HoverInteraction(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    '취소',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.uiWhite,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: HoverInteraction(
            child: InkWell(
              onTap: _isExporting ? null : _exportPoster,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _isExporting
                      ? Colors.grey.withAlpha(100)
                      : AppTheme.uiWhite,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    _isExporting ? '저장중...' : '저장하기',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
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
    );
  }
}

class _EditButtonsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _EditButtonsHeaderDelegate({
    required this.child,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.canvasColor,
            AppTheme.canvasColor.withAlpha(0),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: child,
    );
  }

  @override
  double get maxExtent => 84.0;

  @override
  double get minExtent => 84.0;

  @override
  bool shouldRebuild(covariant _EditButtonsHeaderDelegate oldDelegate) {
    return true;
  }
}
