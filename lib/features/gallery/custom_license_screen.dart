import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_overlay.dart';

class GroupedLicense {
  final String packageName;
  final List<LicenseParagraph> paragraphs;

  GroupedLicense({required this.packageName, required this.paragraphs});
}

class CustomLicenseScreen extends StatefulWidget {
  const CustomLicenseScreen({super.key});

  @override
  State<CustomLicenseScreen> createState() => _CustomLicenseScreenState();
}

class _CustomLicenseScreenState extends State<CustomLicenseScreen> {
  late Future<List<GroupedLicense>> _licensesFuture;

  @override
  void initState() {
    super.initState();
    _licensesFuture = _loadLicenses();
  }

  Future<List<GroupedLicense>> _loadLicenses() async {
    final Map<String, List<LicenseEntry>> packageMap = {};

    await for (final LicenseEntry entry in LicenseRegistry.licenses) {
      for (final String packageName in entry.packages) {
        packageMap.putIfAbsent(packageName, () => []).add(entry);
      }
    }

    final List<GroupedLicense> result = [];

    for (final entry in packageMap.entries) {
      final String packageName = entry.key;
      final List<LicenseEntry> entries = entry.value;

      // 연도 추출하여 정렬
      entries.sort((a, b) {
        final yearA = _extractYear(a);
        final yearB = _extractYear(b);
        final yearCompare = yearA.compareTo(yearB);
        if (yearCompare != 0) return yearCompare;
        
        final textA = a.paragraphs.isNotEmpty ? a.paragraphs.first.text : '';
        final textB = b.paragraphs.isNotEmpty ? b.paragraphs.first.text : '';
        return textA.compareTo(textB);
      });

      final List<LicenseParagraph> mergedParagraphs = [];
      for (int i = 0; i < entries.length; i++) {
        mergedParagraphs.addAll(entries[i].paragraphs);
        if (i < entries.length - 1) {
          mergedParagraphs.add(const LicenseParagraph('\n---\n', LicenseParagraph.centeredIndent));
        }
      }

      result.add(GroupedLicense(
        packageName: packageName,
        paragraphs: mergedParagraphs,
      ));
    }

    result.sort((a, b) => a.packageName.toLowerCase().compareTo(b.packageName.toLowerCase()));

    return result;
  }

  int _extractYear(LicenseEntry entry) {
    for (final p in entry.paragraphs) {
      final match = RegExp(r'\b(19\d{2}|20\d{2})\b').firstMatch(p.text);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    }
    return 9999;
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
          '오픈소스 라이선스',
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
      body: FutureBuilder<List<GroupedLicense>>(
        future: _licensesFuture,
        builder: (context, snapshot) {
          Widget content;
          final bool isLoading = snapshot.connectionState == ConnectionState.waiting;

          if (snapshot.hasError) {
            content = Center(
              child: Text(
                '라이선스를 불러오는 중 오류가 발생했습니다.\n${snapshot.error}',
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
                '등록된 오픈소스 라이선스가 없습니다.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  color: AppTheme.subtitleColor,
                  fontSize: 16,
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final licenses = snapshot.data!;
            content = ListView.separated(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 100.0, bottom: 20.0),
            itemCount: licenses.length,
            separatorBuilder: (context, index) => Divider(
              color: AppTheme.uiWhite.withAlpha(61),
              height: 1,
              thickness: 0.5,
            ),
            itemBuilder: (context, index) {
              final entry = licenses[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                title: Text(
                  entry.packageName,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Color(0xFFF0F4F8),
                    letterSpacing: -0.3,
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.uiWhite.withAlpha(138)),
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          CustomLicenseDetailScreen(license: entry),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  );
                },
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

class CustomLicenseDetailScreen extends StatelessWidget {
  final GroupedLicense license;

  const CustomLicenseDetailScreen({super.key, required this.license});

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
              title: Text(
                license.packageName,
                style: const TextStyle(
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
            body: ListView(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 100.0, bottom: 16.0),
              children: [
                ...license.paragraphs.map((paragraph) {
                  final double indent = paragraph.indent.toDouble() * 8.0;
                  final bool isCentered = paragraph.indent == LicenseParagraph.centeredIndent;
                  return Padding(
                    padding: EdgeInsets.only(
                      top: 2.0,
                      bottom: 2.0,
                      left: isCentered ? 0 : indent,
                    ),
                    child: Text(
                      paragraph.text,
                      textAlign: isCentered ? TextAlign.center : TextAlign.start,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        color: Color(0xFFCCCCCC),
                        height: 1.5,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
