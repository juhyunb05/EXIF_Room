import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CustomLicenseScreen extends StatefulWidget {
  const CustomLicenseScreen({super.key});

  @override
  State<CustomLicenseScreen> createState() => _CustomLicenseScreenState();
}

class _CustomLicenseScreenState extends State<CustomLicenseScreen> {
  late Future<List<LicenseEntry>> _licensesFuture;

  @override
  void initState() {
    super.initState();
    _licensesFuture = _loadLicenses();
  }

  Future<List<LicenseEntry>> _loadLicenses() async {
    final List<LicenseEntry> licenses = [];
    await for (final LicenseEntry entry in LicenseRegistry.licenses) {
      licenses.add(entry);
    }
    return licenses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          '오픈소스 라이선스',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<LicenseEntry>>(
        future: _licensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
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
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                '등록된 오픈소스 라이선스가 없습니다.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  color: AppTheme.subtitleColor,
                  fontSize: 16,
                ),
              ),
            );
          }

          final licenses = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            itemCount: licenses.length,
            separatorBuilder: (context, index) => const Divider(
              color: Colors.white24,
              height: 48,
              thickness: 0.5,
            ),
            itemBuilder: (context, index) {
              final entry = licenses[index];
              final packagesText = entry.packages.join(', ');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Package Headers
                  Text(
                    packagesText,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFFF0F4F8),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // License Texts
                  ...entry.paragraphs.map((paragraph) {
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
              );
            },
          );
        },
      ),
    );
  }
}
