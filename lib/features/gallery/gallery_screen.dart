import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_selector/file_selector.dart';
import 'package:heic_to_png_jpg/heic_to_png_jpg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/poster_project.dart';
import '../../core/models/project_category.dart';
import '../../core/providers/gallery_provider.dart';
import 'package:provider/provider.dart';
import '../../core/services/database_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../core/services/exif_service.dart';
import '../../core/services/file_manager_service.dart';
import '../../core/utils/heic_converter_web.dart';
import '../../theme/app_theme.dart';
import '../editor/editor_screen.dart';
import 'custom_license_screen.dart';
import 'privacy_policy_screen.dart';
import 'version_info_screen.dart';
import '../../widgets/hover_interaction.dart';
import 'widgets/gallery_grid.dart';
import 'widgets/category_bar.dart';
import 'widgets/project_context_menu.dart';
import 'widgets/image_viewer_dialog.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  String _currentVersion = 'v0.0.0';

  @override
  void initState() {
    super.initState();
    // Projects are already loaded by MultiProvider during app startup
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final rawText = await DefaultAssetBundle.of(context).loadString('versionInfo.md');
      final lines = rawText.split('\n');
      for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.startsWith('# ')) {
          final parts = line.substring(2).split(' ');
          if (parts.isNotEmpty) {
            setState(() {
              _currentVersion = parts[0];
            });
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load version: $e');
    }
  }

  Future<void> _loadProjects() async {
    // Left for compatibility with _pickImage return, but provider handles it
    await context.read<GalleryProvider>().loadProjects();
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
      barrierColor: Colors.black.withAlpha(204), // 80% opacity black barrier
      builder: (context) => ImageViewerDialog(project: project),
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
          return ProjectContextMenu(
            project: project,
            itemRect: itemRect,
            onAssignCategory: () {
              Navigator.pop(context);
              Future.microtask(() {
                if (mounted) _showAssignCategoryDialog(project);
              });
            },
            onDelete: () async {
              Navigator.pop(context);
              if (project.id != null) {
                await context.read<GalleryProvider>().deleteProject(project.id!);
              }
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog({PosterProject? projectToAssign}) {
    final provider = context.read<GalleryProvider>();
    if (provider.categories.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('분류는 최대 5개까지 생성할 수 있습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final textController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(204),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    '새 분류 추가',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.uiWhite,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: textController,
                  autofocus: true,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    color: AppTheme.uiWhite,
                  ),
                  decoration: InputDecoration(
                    hintText: '분류 이름을 입력하세요',
                    hintStyle: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF8E8E93), width: 1),
                    ),
                  ),
                  onSubmitted: (_) async {
                    await _createNewCategory(textController.text, dialogContext, projectToAssign: projectToAssign);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: HoverInteraction(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(dialogContext),
                          behavior: HitTestBehavior.opaque,
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
                        child: GestureDetector(
                          onTap: () async {
                            await _createNewCategory(textController.text, dialogContext, projectToAssign: projectToAssign);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4F8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                '만들기',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E1E1E),
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
      },
    );
  }

  Future<void> _createNewCategory(String name, BuildContext dialogContext, {PosterProject? projectToAssign}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('분류 이름을 입력해 주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final newCat = await context.read<GalleryProvider>().createCategory(trimmedName);
      if (newCat != null && projectToAssign != null) {
        await context.read<GalleryProvider>().assignProjectToCategory(projectToAssign, newCat.id);
      }

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }
    } catch (e, stack) {
      debugPrint('Error creating category: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('분류 생성 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  void _showCategoryOptionsDialog(ProjectCategory cat) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(204),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '분류 ${cat.number}: ${cat.name}',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.uiWhite,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                HoverInteraction(
                  enableScale: false,
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(dialogContext);
                      await context.read<GalleryProvider>().deleteCategory(cat.id);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D0C0C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          '분류 삭제',
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
                const SizedBox(height: 12),
                HoverInteraction(
                  enableScale: false,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(dialogContext),
                    child: Container(
                      width: double.infinity,
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
                            color: AppTheme.uiWhite,
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

  void _showAssignCategoryDialog(PosterProject project) {
    final Set<int> selectedCategoryIds = project.categoryIdList.toSet();

    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(204),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Consumer<GalleryProvider>(
              builder: (context, provider, child) {
                final categories = provider.categories;
                return Dialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '분류 지정',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.uiWhite,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (categories.isEmpty) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      '생성된 분류가 없습니다.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 14,
                                        color: Color(0xFF8E8E93),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                for (final cat in categories) ...[
                                  _buildCategoryOptionItem(
                                    category: cat,
                                    isSelected: selectedCategoryIds.contains(cat.id),
                                    onTap: () {
                                      setDialogState(() {
                                        if (selectedCategoryIds.contains(cat.id)) {
                                          selectedCategoryIds.remove(cat.id);
                                        } else {
                                          selectedCategoryIds.add(cat.id);
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                const SizedBox(height: 4),
                                _buildAddCategoryOptionItem(
                                  onTap: () {
                                    Navigator.pop(dialogContext);
                                    Future.microtask(() {
                                      if (mounted) _showAddCategoryDialog(projectToAssign: project);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: HoverInteraction(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(dialogContext),
                                  behavior: HitTestBehavior.opaque,
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
                                child: GestureDetector(
                                  onTap: () async {
                                    await provider.assignProjectToCategories(project, selectedCategoryIds.toList());
                                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F4F8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '완료',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E1E1E),
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
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryOptionItem({
    required ProjectCategory category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return HoverInteraction(
      enableScale: false,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3A3A3C) : const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(14),
            border: isSelected ? Border.all(color: AppTheme.uiWhite.withAlpha(128)) : null,
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.folder_rounded, size: 24, color: Color(0xFFF0F4F8)),
                  Positioned(
                    top: 6,
                    child: Text(
                      '${category.number}',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.uiWhite,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_rounded, color: AppTheme.uiWhite, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddCategoryOptionItem({required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: HoverInteraction(
          hoverScale: 1.08,
          child: IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.add_rounded, color: AppTheme.uiWhite, size: 28),
            tooltip: '새 분류 추가',
          ),
        ),
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
            height: 450, // Fixed height 450
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
                        SvgPicture.asset(
                          'assets/images/logoFullSvg.svg',
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 6),
                        // Version
                        Text(
                          _currentVersion,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Info buttons
                        _buildInfoMenuButton(
                          text: '공지 및 변경사항',
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    const VersionInfoScreen(),
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
                        const SizedBox(height: 10),
                        _buildInfoMenuButton(
                          text: 'Github Repository',
                          isExternal: true,
                          onTap: () {
                            _launchURL('https://github.com/juhyunb05/EXIF_Room');
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
                    child: HoverInteraction(
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoMenuButton({required String text, required VoidCallback onTap, bool isExternal = false}) {
    return HoverInteraction(
      enableScale: false,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFF0F4F8),
                ),
              ),
              if (isExternal) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: Color(0xFF8E8E93),
                ),
              ],
            ],
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
                    color: AppTheme.uiWhite,
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
                      child: HoverInteraction(
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
                        child: GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            
                            // Perform clear
                            await DatabaseService().clearAllData();
                            
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
    return Consumer<GalleryProvider>(
      builder: (context, provider, child) {
        final displayedProjects = provider.filteredProjects;
        final isLoading = provider.isLoading;

        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Stack(
                children: [
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      scrollbars: false,
                    ),
                    child: CustomScrollView(
                      slivers: [
                        const SliverPadding(
                          padding: EdgeInsets.only(top: 84),
                        ),
                        if (isLoading || displayedProjects.isEmpty)
                          _buildEmptyState(provider.selectedCategoryId != null)
                        else
                          GalleryGrid(
                            projects: displayedProjects,
                            onShowOptions: (project, rect) => _showProjectOptions(context, project, rect),
                            onViewImage: _viewImage,
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 90,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
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
                    top: 20,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        const SizedBox(width: 48),
                        Expanded(
                          child: Center(
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF222222),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CategoryBar(
                                    onAddCategory: _showAddCategoryDialog,
                                    onCategoryOptions: _showCategoryOptionsDialog,
                                    onInfoDialog: () => _showInfoDialog(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        HoverInteraction(
                          child: GestureDetector(
                            onTap: () => _showInfoDialog(context),
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.info_outline_rounded, color: Color(0xFFF0F4F8), size: 24),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                      child: HoverInteraction(
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
                  ),
                  LoadingOverlay(isLoading: isLoading),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isCategorySelected) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isCategorySelected ? '이 분류에 지정된 사진이 없습니다.' : '현재 갤러리가 비어있습니다.',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFF0F4F8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isCategorySelected
                    ? '사진을 길게 누르거나 우클릭하면 나타나는 메뉴에서 분류를 지정할 수 있습니다.'
                    : '사진을 생성하려면 하단의 + 버튼을 눌러주세요.',
                style: const TextStyle(
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

}
