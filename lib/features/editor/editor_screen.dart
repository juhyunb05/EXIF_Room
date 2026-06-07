import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image/image.dart' as img_lib;


import '../../core/models/exif_data.dart';
import '../../core/models/poster_project.dart';
import '../../core/services/database_service.dart';
import '../../core/services/file_manager_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/poster_canvas.dart';

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
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isExporting = false;
  int _imageRotation = 0;

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
    _cameraMakeController = TextEditingController(text: _currentExif.cameraMake);
    _cameraNameController = TextEditingController(text: _currentExif.cameraName);
    _locationController = TextEditingController(text: _currentExif.location);
    _focalLengthController = TextEditingController(text: _currentExif.focalLength);
    _apertureController = TextEditingController(text: _currentExif.aperture);
    _shutterSpeedController = TextEditingController(text: _currentExif.shutterSpeed);
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
    
    // 화면 이탈 시 남아있을 수 있는 모든 이미지 텍스처 리소스 강제 반환
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    super.dispose();
  }

  Future<void> _exportPoster() async {
    setState(() => _isExporting = true);
    
    // 메모리 즉시 해제를 위해 대형 로컬 그래픽 버퍼들을 미리 선언
    Uint8List? fileBytes;
    Uint8List? imageBytes;
    img_lib.Image? decodedImage;
    img_lib.Image? resized;
    Uint8List? thumbnailBytes;

    try {
      if (widget.webImageBytes != null) {
        fileBytes = widget.webImageBytes!;
      } else if (kIsWeb) {
        final response = await http.get(Uri.parse(widget.imagePath));
        fileBytes = response.bodyBytes;
      } else {
        fileBytes = await XFile(widget.imagePath).readAsBytes();
      }
      final codec = await ui.instantiateImageCodec(fileBytes);
      final frameInfo = await codec.getNextFrame();
      final ui.Image img = frameInfo.image;
      double ratio = img.width / img.height;
      if (_imageRotation % 2 != 0) {
        ratio = img.height / img.width;
      }
      final double imageHeight = 2400 / ratio;
      
      // 즉시 이미지 객체를 해제하여 힙 메모리 누수 방지
      img.dispose();
      
      // Accurately calculate the height of the info section
      int nameLength = (_currentExif.cameraName ?? "UNKNOWN CAMERA").length;
      int nameLines = (nameLength / 16).ceil();
      if (nameLines < 1) nameLines = 1;
      
      double leftHeight = 56.0 + 72.0 + (100.0 * nameLines); // Name, spacer, date
      if (_currentExif.cameraMake != null && _currentExif.cameraMake!.isNotEmpty) {
        leftHeight += 80.0; // 56 text + 24 spacer
      }
      if (_currentExif.location != null && _currentExif.location!.isNotEmpty) {
        leftHeight += 88.0; // 72 text + 16 spacer
      }
      
      double rightHeight = 240.0; // 80 text + 80 spacer + 80 text
      
      final double textHeight = leftHeight > rightHeight ? leftHeight : rightHeight;

      // 200 (top) + image + 320 (middle) + dynamic text height + 320 (bottom)
      final double totalHeight = 200 + imageHeight + 320 + textHeight + 320;

      imageBytes = await _screenshotController.captureFromWidget(
        Material(
          child: PosterCanvas(
            imagePath: widget.imagePath,
            webImageBytes: widget.webImageBytes,
            exifData: _currentExif,
            imageRotation: _imageRotation,
            isPreview: false,
          ),
        ),
        targetSize: Size(2800, totalHeight),
        delay: const Duration(milliseconds: 500),
      );

      // 썸네일 생성 로직 (JPEG 40% 압축 및 1/4 사이즈 다운샘플링)
      try {
        decodedImage = img_lib.decodeImage(imageBytes);
        if (decodedImage != null) {
          resized = img_lib.copyResize(
            decodedImage,
            width: 700,
            interpolation: img_lib.Interpolation.linear,
          );
          thumbnailBytes = Uint8List.fromList(img_lib.encodeJpg(resized, quality: 40));
        }
      } catch (e) {
        debugPrint('Failed to generate thumbnail: $e');
      }

      final fileName = FileManagerService.generateFileName(_currentExif, 'png');
      String? filePath;

      if (!kIsWeb) {
        final directory = await getApplicationDocumentsDirectory();
        filePath = p.join(directory.path, fileName);
        final file = File(filePath);
        await file.writeAsBytes(imageBytes);
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

      await DatabaseService().saveProject(project, originalImageBytes: kIsWeb ? imageBytes : null);

      if (mounted) {
        _showSuccessSheet(kIsWeb ? fileName : filePath!, webBytes: kIsWeb ? imageBytes : null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Export failed: $e")));
      }
    } finally {
      // 대형 그래픽 메모리 객체들의 레퍼런스를 null 처리하여 가비지 수집 즉시 유도
      fileBytes = null;
      imageBytes = null;
      decodedImage = null;
      resized = null;
      thumbnailBytes = null;

      // 이미지 캐시를 강제 정화하여 렌더링 텍스처 즉시 반환
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showSuccessSheet(String path, {Uint8List? webBytes}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(153),
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF262626), // Dark iOS-like gray
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                    color: Colors.white,
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              _buildDialogButton(
                icon: Icons.save_alt_rounded,
                text: "저장하기",
                onTap: () async {
                  Navigator.pop(dialogContext);
                  if (kIsWeb) {
                    if (webBytes != null) {
                      await FileManagerService.shareOrSaveImage(path, false, webBytes: webBytes);
                    }
                  } else {
                    await FileManagerService.shareOrSaveImage(path, Platform.isWindows, saveToDevice: true);
                  }
                  if (!mounted) return;
                  Navigator.pop(context, true);
                },
              ),
              if (!kIsWeb && !Platform.isWindows) ...[
                const Divider(height: 1, color: Colors.white12),
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
              const Divider(height: 1, color: Colors.white12),
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

  Widget _buildDialogButton({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: isDesktop
          ? AppBar(
              actions: [
                _buildSaveButton(),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildSaveButton() {
    return IconButton(
      onPressed: _isExporting ? null : _exportPoster,
      icon: _isExporting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(
              Icons.save_rounded,
              color: Colors.white,
            ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
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
          child: SingleChildScrollView(
            child: _buildEditPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final size = MediaQuery.of(context).size;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: size.height * 0.55,
          actions: [
            _buildSaveButton(),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: kToolbarHeight),
                child: _buildPreviewArea(),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            constraints: BoxConstraints(minHeight: size.height * 0.45),
            decoration: const BoxDecoration(
              color: AppTheme.canvasColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: _buildEditPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewArea() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Screenshot(
            controller: _screenshotController,
            child: Center(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: PosterCanvas(
                  imagePath: widget.imagePath,
                  webImageBytes: widget.webImageBytes,
                  exifData: _currentExif,
                  imageRotation: _imageRotation,
                  isPreview: true,
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(128),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.rotate_90_degrees_ccw, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _imageRotation = (_imageRotation + 1) % 4;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildElegantField(
            "카메라 제조사",
            _cameraMakeController,
            (v) => setState(() => _currentExif.cameraMake = v),
          ),
          _buildElegantField(
            "카메라",
            _cameraNameController,
            (v) => setState(() => _currentExif.cameraName = v),
          ),
          _buildElegantField(
            "위치 (도시, 국가)",
            _locationController,
            (v) => setState(() => _currentExif.location = v),
          ),
          _buildDateField(
            "날짜",
            _currentExif.shotDate,
          ),
          Row(
            children: [
              Expanded(
                child: _buildElegantField(
                  "초점 거리",
                  _focalLengthController,
                  (v) => setState(
                    () => _currentExif.focalLength = v,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildElegantField(
                  "조리개",
                  _apertureController,
                  (v) => setState(() => _currentExif.aperture = v),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildElegantField(
                  "셔터 속도",
                  _shutterSpeedController,
                  (v) => setState(
                    () => _currentExif.shutterSpeed = v,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildElegantField(
                  "ISO",
                  _isoController,
                  (v) => setState(() => _currentExif.iso = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElegantField(
    String label,
    TextEditingController controller,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'Pretendard', 
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.subtitleColor.withAlpha(150),
            ),
          ),
          TextField(
            controller: controller,
            style: TextStyle(fontFamily: 'Pretendard', 
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: InputBorder.none,
            ),
            onChanged: onChanged,
          ),
          Container(height: 1, color: Colors.grey.withAlpha(50)),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? value) {
    final displayDate = value != null ? DateFormat("yyyy/MM/dd HH:mm").format(value) : "";
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'Pretendard', 
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.subtitleColor.withAlpha(150),
            ),
          ),
          InkWell(
            onTap: () async {
              final initialDate = value ?? DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppTheme.primaryColor,
                        onPrimary: Colors.black,
                        surface: AppTheme.canvasColor,
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null && mounted) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(initialDate),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppTheme.primaryColor,
                          onPrimary: Colors.black,
                          surface: AppTheme.canvasColor,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (time != null && mounted) {
                  setState(() {
                    _currentExif.shotDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                displayDate.isEmpty ? "날짜 선택" : displayDate,
                style: TextStyle(fontFamily: 'Pretendard', 
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: displayDate.isEmpty ? Colors.grey : Colors.white,
                ),
              ),
            ),
          ),
          Container(height: 1, color: Colors.grey.withAlpha(50)),
        ],
      ),
    );
  }
}
