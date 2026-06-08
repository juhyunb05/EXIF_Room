import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_overlay.dart';

class VersionSection {
  final String title;
  final String content;

  VersionSection({required this.title, required this.content});
}

class VersionInfoScreen extends StatefulWidget {
  const VersionInfoScreen({super.key});

  @override
  State<VersionInfoScreen> createState() => _VersionInfoScreenState();
}

class _VersionInfoScreenState extends State<VersionInfoScreen> {
  late Future<List<VersionSection>> _versionDataFuture;

  @override
  void initState() {
    super.initState();
    _versionDataFuture = _loadAndParseVersionInfo();
  }

  Future<List<VersionSection>> _loadAndParseVersionInfo() async {
    final rawText = await DefaultAssetBundle.of(context).loadString('versionInfo.md');
    return _parseVersionMarkdown(rawText);
  }

  List<VersionSection> _parseVersionMarkdown(String rawText) {
    final List<String> lines = rawText.split('\n');
    final List<VersionSection> sections = [];
    String? currentTitle;
    final StringBuffer currentContent = StringBuffer();

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('# ')) {
        if (currentTitle != null) {
          sections.add(VersionSection(
            title: currentTitle,
            content: currentContent.toString().trim(),
          ));
          currentContent.clear();
        }
        currentTitle = line.substring(2);
      } else {
        if (currentTitle != null) {
          if (currentContent.isNotEmpty) currentContent.write('\n');
          currentContent.write(line);
        }
      }
    }

    if (currentTitle != null) {
      sections.add(VersionSection(
        title: currentTitle,
        content: currentContent.toString().trim(),
      ));
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: const Text(
                '공지 및 변경사항',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: FutureBuilder<List<VersionSection>>(
              future: _versionDataFuture,
              builder: (context, snapshot) {
                Widget content;
                final bool isLoading = snapshot.connectionState == ConnectionState.waiting;

                if (snapshot.hasError) {
                  content = Center(
                    child: Text(
                      '버전 정보를 불러오는 중 오류가 발생했습니다.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    ),
                  );
                } else if (!isLoading && (!snapshot.hasData || snapshot.data!.isEmpty)) {
                  content = const Center(
                    child: Text(
                      '버전 정보가 없습니다.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: AppTheme.subtitleColor,
                        fontSize: 16,
                      ),
                    ),
                  );
                } else if (snapshot.hasData) {
                  final sections = snapshot.data!;
                  content = ListView.separated(
                    padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 100.0, bottom: 20.0),
                    itemCount: sections.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 48,
                      thickness: 1,
                      color: const Color(0xFF8E8E93).withAlpha(50),
                    ),
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFFF0F4F8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            section.content,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              color: Color(0xFFCCCCCC),
                              height: 1.6,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  content = const SizedBox.shrink();
                }

                return Stack(
                  children: [
                    content,
                    LoadingOverlay(isLoading: isLoading),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
