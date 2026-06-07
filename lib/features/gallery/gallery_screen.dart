import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:heic_to_png_jpg/heic_to_png_jpg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/poster_project.dart';
import '../../core/services/database_service.dart';
import '../../core/services/exif_service.dart';
import '../../core/services/file_manager_service.dart';
import '../../core/utils/heic_converter_web.dart';
import '../../theme/app_theme.dart';
import '../editor/editor_screen.dart';
import 'custom_license_screen.dart';
import 'privacy_policy_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<PosterProject> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await DatabaseService().getAllProjects();
    setState(() {
      _projects = projects..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    String? selectedPath;
    String? selectedName;

    if (kIsWeb) {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        
      );
      selectedPath = image?.path;
      selectedName = image?.name;
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final typeGroup = const XTypeGroup(
        label: 'Images',
        extensions: <String>['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif'],
      );
      final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
      selectedPath = file?.path;
      selectedName = file?.name;
    } else {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        
      );
      selectedPath = image?.path;
      selectedName = image?.name;
    }

    if (selectedPath != null) {
      String currentPath = selectedPath;
      final extension = p.extension(selectedName ?? currentPath).toLowerCase();
      
      if (kIsWeb && (extension == '.heic' || extension == '.heif')) {
        try {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('HEIC 파일을 JPG로 변환 중입니다. 잠시만 기다려주세요...')),
            );
          }
          currentPath = await convertHeicWeb(currentPath);
        } catch (e) {
          debugPrint('Failed to convert HEIC on Web: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('HEIC 파일 변환에 실패했습니다: $e')),
            );
          }
          return;
        }
      }

      if (!kIsWeb && (extension == '.heic' || extension == '.heif')) {
        try {
          final outputPath = await HeicConverter.convertFile(
            inputPath: currentPath,
            format: ImageFormat.jpg,
            quality: 100,
          );
          currentPath = outputPath;
        } catch (e) {
          debugPrint('Failed to convert HEIC: $e');
        }
      }

      final internalPath = kIsWeb ? currentPath : await FileManagerService.copyToInternalStorage(currentPath);
      final exif = await ExifService.extractExif(selectedPath);
      if (mounted) {
        final result = await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                EditorScreen(imagePath: internalPath, initialExif: exif),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
        if (result == true) _loadProjects();
      }
    }
  }

  void _viewImage(PosterProject project) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: kIsWeb
                ? (project.webExportedImageBytes != null
                    ? Image.memory(
                        project.webExportedImageBytes!,
                        fit: BoxFit.contain,
                      )
                    : Image.network(
                        project.originalImagePath,
                        fit: BoxFit.contain,
                      ))
                : Image.file(
                    File(project.exportedImagePath ?? project.originalImagePath),
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ),
    );
  }

  void _showProjectOptions(BuildContext context, PosterProject project, Rect itemRect) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withAlpha(204), // Dimming effect
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ProjectContextMenu(
            project: project,
            itemRect: itemRect,
            onDelete: () async {
              Navigator.pop(context);
              if (project.id != null) {
                await DatabaseService().deleteProject(project.id!);
              }
              _loadProjects();
            },
          );
        },
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(204), // 80% opaque black barrier
      barrierDismissible: true, // Close when barrier is tapped
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E), // Dark grey
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40), // Curved corners (40)
          ),
          child: Container(
            width: 300, // Fixed width 300
            height: 400, // Fixed height 400
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 52, // Pushed down by 20px
              bottom: 30, // 30px away from bottom edge
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 60, // Leave 60px for bottom button area (40px button + 20px spacing)
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo Image
                        Image.asset(
                          'assets/images/logoFullPng.png',
                          height: 48,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_library_outlined, color: Colors.white, size: 32),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'EXIF',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Room',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        // Version
                        const Text(
                          'v0.1.1',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Info buttons
                        _buildInfoMenuButton(
                          text: '오픈소스 라이선스',
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    const CustomLicenseScreen(),
                                transitionsBuilder:
                                    (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildInfoMenuButton(
                          text: 'Github Repository',
                          onTap: () {
                            _launchURL('https://github.com/juhyunb05/EXIF_Room');
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildInfoMenuButton(
                          text: '개인정보 처리방침',
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    const PrivacyPolicyScreen(),
                                transitionsBuilder:
                                    (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _showClearDataConfirmation(context);
                      },
                      child: Container(
                        width: 240, // Fixed width 240
                        height: 40, // Fixed height 40
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D0C0C),
                          borderRadius: BorderRadius.circular(20), // Border radius 20
                        ),
                        child: const Center(
                          child: Text(
                            '모든 데이터 지우기',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF453A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoMenuButton({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFFF0F4F8),
          ),
        ),
      ),
    );
  }

  void _showClearDataConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(204),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF453A), size: 40),
                const SizedBox(height: 16),
                const Text(
                  '모든 데이터 지우기',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '정말 모든 데이터를 지우시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              '취소',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          
                          // Perform clear
                          await DatabaseService().box.clear();
                          
                          if (!kIsWeb) {
                            try {
                              final dir = await getApplicationDocumentsDirectory();
                              final importedDir = Directory(p.join(dir.path, 'imported_images'));
                              if (await importedDir.exists()) {
                                await importedDir.delete(recursive: true);
                              }
                            } catch (e) {
                              debugPrint('Failed to delete files: $e');
                            }
                          }
                          
                          // Reload projects list
                          _loadProjects();
                          
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('모든 데이터가 삭제되었습니다.'),
                              backgroundColor: Color(0xFF3D0C0C),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D0C0C),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              '지우기',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF453A),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    floating: true,
                    toolbarHeight: 72.0,
                    flexibleSpace: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.backgroundColor,
                            AppTheme.backgroundColor.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                    centerTitle: true,
                    title: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {}, // Current gallery
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              child: Icon(Icons.dashboard_rounded, color: Color(0xFFF0F4F8), size: 22),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {}, // Add category
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              child: Icon(Icons.add, color: Color(0xFFF0F4F8), size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      GestureDetector(
                        onTap: () => _showInfoDialog(context), // Info button
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(Icons.info_outline_rounded, color: Color(0xFFF0F4F8), size: 24),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  if (_isLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_projects.isEmpty)
                    _buildEmptyState()
                  else
                    _buildProjectGrid(),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 120,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppTheme.backgroundColor.withAlpha(230),
                          AppTheme.backgroundColor.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 96,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Icon(Icons.add, color: Color(0xFFF0F4F8), size: 28),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                '현재 갤러리가 비어있습니다.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFF0F4F8),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '사진을 생성하려면 하단의 + 버튼을 눌러주세요.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFF0F4F8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      sliver: SliverMasonryGrid.extent(
        maxCrossAxisExtent: 250,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childCount: _projects.length,
        itemBuilder: (context, index) {
          final project = _projects[index];
          return Builder(
            builder: (itemContext) {
              return Hero(
                tag: project.id ?? project.hashCode,
                child: GestureDetector(
                  onTap: () => _viewImage(project),
                  onLongPress: () {
                    final box = itemContext.findRenderObject() as RenderBox;
                    final rect = box.localToGlobal(Offset.zero) & box.size;
                    _showProjectOptions(context, project, rect);
                  },
                  onSecondaryTap: () {
                    final box = itemContext.findRenderObject() as RenderBox;
                    final rect = box.localToGlobal(Offset.zero) & box.size;
                    _showProjectOptions(context, project, rect);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: kIsWeb
                        ? (project.webExportedImageBytes != null
                            ? Image.memory(project.webExportedImageBytes!)
                            : Image.network(project.originalImagePath))
                        : Image.file(
                            File(
                              project.exportedImagePath ??
                                  project.originalImagePath,
                            ),
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProjectContextMenu extends StatefulWidget {
  final PosterProject project;
  final Rect itemRect;
  final VoidCallback onDelete;

  const _ProjectContextMenu({
    required this.project,
    required this.itemRect,
    required this.onDelete,
  });

  @override
  State<_ProjectContextMenu> createState() => _ProjectContextMenuState();
}

class _ProjectContextMenuState extends State<_ProjectContextMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const pillHeight = 60.0;
    const spacing = 20.0;
    
    final scaledHeight = widget.itemRect.height * 1.05;
    final heightDiff = (scaledHeight - widget.itemRect.height) / 2;
    
    final spaceBelow = screenSize.height - widget.itemRect.bottom - heightDiff;
    final showBelow = spaceBelow >= (pillHeight + spacing);
    
    double pillTop;
    if (showBelow) {
      pillTop = widget.itemRect.bottom + heightDiff + spacing;
    } else {
      pillTop = widget.itemRect.top - heightDiff - spacing - pillHeight;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dismiss background
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            top: widget.itemRect.top,
            left: widget.itemRect.left,
            width: widget.itemRect.width,
            height: widget.itemRect.height,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: Hero(
                tag: widget.project.id ?? widget.project.hashCode,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(128),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: kIsWeb 
                      ? (widget.project.webExportedImageBytes != null
                          ? Image.memory(
                              widget.project.webExportedImageBytes!,
                              fit: BoxFit.contain,
                            )
                          : Image.network(
                              widget.project.exportedImagePath ?? widget.project.originalImagePath,
                              fit: BoxFit.contain,
                            ))
                      : Image.file(
                          File(widget.project.exportedImagePath ?? widget.project.originalImagePath),
                          fit: BoxFit.contain, // Maintain aspect ratio when scaled
                        ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: pillTop,
            left: widget.itemRect.center.dx,
            child: FractionalTranslation(
              translation: const Offset(-0.5, 0),
              child: FadeTransition(
                opacity: _controller,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
                  ),
                  child: Material(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(30),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_downward_rounded, color: Colors.black87),
                          onPressed: () {
                            Navigator.pop(context);
                            final path = widget.project.exportedImagePath ?? widget.project.originalImagePath;
                            final ext = p.extension(path).isEmpty ? 'png' : p.extension(path).replaceAll('.', '');
                            final customName = FileManagerService.generateFileName(widget.project.exif, ext);
                            FileManagerService.shareOrSaveImage(
                              path,
                              !kIsWeb && Platform.isWindows,
                              saveToDevice: true,
                              webBytes: widget.project.webExportedImageBytes,
                              customFileName: customName,
                            );
                          },
                        ),
                        if (!kIsWeb && !Platform.isWindows)
                          IconButton(
                            icon: const Icon(Icons.share_rounded, color: Colors.black87),
                            onPressed: () {
                              Navigator.pop(context);
                              final path = widget.project.exportedImagePath ?? widget.project.originalImagePath;
                              FileManagerService.shareOrSaveImage(path, false);
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          onPressed: widget.onDelete,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}
