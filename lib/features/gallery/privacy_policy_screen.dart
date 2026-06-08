import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_overlay.dart';

class PrivacySection {
  final String? title;
  final String content;

  PrivacySection({this.title, required this.content});
}

class PrivacyPolicyData {
  final String intro;
  final List<PrivacySection> sections;
  final String? date;

  PrivacyPolicyData({required this.intro, required this.sections, this.date});
}

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late Future<PrivacyPolicyData> _privacyDataFuture;

  @override
  void initState() {
    super.initState();
    _privacyDataFuture = _loadAndParsePrivacyPolicy();
  }

  Future<PrivacyPolicyData> _loadAndParsePrivacyPolicy() async {
    final assetPath = kIsWeb
        ? 'assets/privacy/privacy_policy_web.md'
        : 'assets/privacy/privacy_policy_native.md';

    final rawText = await DefaultAssetBundle.of(context).loadString(assetPath);
    return _parsePrivacyMarkdown(rawText);
  }

  PrivacyPolicyData _parsePrivacyMarkdown(String rawText) {
    final List<String> lines = rawText.split('\n');

    String intro = '';
    final List<PrivacySection> sections = [];
    String? date;

    String? currentTitle;
    final StringBuffer currentContent = StringBuffer();
    bool hasIntroFinished = false;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // # 대제목은 건너뜀
      if (line.startsWith('# ')) {
        continue;
      }

      // 시행일자 처리
      if (line.startsWith('시행일자:')) {
        date = line;
        continue;
      }

      // ## 조항 구분 처리
      if (line.startsWith('## ')) {
        hasIntroFinished = true;
        if (currentTitle != null || currentContent.isNotEmpty) {
          sections.add(PrivacySection(
            title: currentTitle,
            content: currentContent.toString().trim(),
          ));
          currentContent.clear();
        }
        currentTitle = line.substring(3);
      } else {
        if (!hasIntroFinished) {
          if (intro.isNotEmpty) intro += '\n';
          intro += line;
        } else {
          if (currentContent.isNotEmpty) currentContent.write('\n');
          currentContent.write(line);
        }
      }
    }

    // 마지막 남은 조항 처리
    if (currentTitle != null || currentContent.isNotEmpty) {
      sections.add(PrivacySection(
        title: currentTitle,
        content: currentContent.toString().trim(),
      ));
    }

    return PrivacyPolicyData(intro: intro, sections: sections, date: date);
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
          '개인정보 처리방침',
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
      body: FutureBuilder<PrivacyPolicyData>(
        future: _privacyDataFuture,
        builder: (context, snapshot) {
          Widget content;
          final bool isLoading = snapshot.connectionState == ConnectionState.waiting;

          if (snapshot.hasError) {
            content = Center(
              child: Text(
                '개인정보 처리방침을 불러오는 중 오류가 발생했습니다.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  color: Colors.redAccent,
                  fontSize: 14,
                ),
              ),
            );
          } else if (!isLoading && !snapshot.hasData) {
            content = const Center(
              child: Text(
                '개인정보 처리방침을 찾을 수 없습니다.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  color: AppTheme.subtitleColor,
                  fontSize: 16,
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            content = SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 100.0, bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.intro.isNotEmpty)
                  Text(
                    data.intro,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      color: Color(0xFFEBEBEB),
                      height: 1.6,
                    ),
                  ),
                const SizedBox(height: 24),
                ...data.sections.map((section) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (section.title != null)
                          Text(
                            section.title!,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFFF0F4F8),
                            ),
                          ),
                        const SizedBox(height: 8),
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
                    ),
                  );
                }),
                if (data.date != null) ...[
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      data.date!,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.subtitleColor,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
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
