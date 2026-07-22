import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/models/exif_data.dart';
import '../../../theme/app_theme.dart';

class EditorForm extends StatelessWidget {
  final ExifData currentExif;
  final TextEditingController cameraMakeController;
  final TextEditingController cameraNameController;
  final TextEditingController locationController;
  final TextEditingController focalLengthController;
  final TextEditingController apertureController;
  final TextEditingController shutterSpeedController;
  final TextEditingController isoController;
  final Function(ExifData) onExifChanged;
  final BuildContext parentContext;

  const EditorForm({
    super.key,
    required this.currentExif,
    required this.cameraMakeController,
    required this.cameraNameController,
    required this.locationController,
    required this.focalLengthController,
    required this.apertureController,
    required this.shutterSpeedController,
    required this.isoController,
    required this.onExifChanged,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildElegantField(
          "카메라 제조사",
          cameraMakeController,
          (v) {
            currentExif.cameraMake = v;
            onExifChanged(currentExif);
          },
          [FilteringTextInputFormatter.singleLineFormatter],
        ),
        _buildElegantField(
          "모델명",
          cameraNameController,
          (v) {
            currentExif.cameraName = v;
            onExifChanged(currentExif);
          },
          [FilteringTextInputFormatter.singleLineFormatter],
        ),
        _buildElegantField(
          "위치 (도시, 국가)",
          locationController,
          (v) {
            currentExif.location = v;
            onExifChanged(currentExif);
          },
          [FilteringTextInputFormatter.singleLineFormatter],
        ),
        _buildDateField(
          "날짜",
          currentExif.shotDate,
        ),
        Row(
          children: [
            Expanded(
              child: _buildElegantField(
                "초점 거리",
                focalLengthController,
                (v) {
                  currentExif.focalLength = v;
                  onExifChanged(currentExif);
                },
                [FilteringTextInputFormatter.singleLineFormatter],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildElegantField(
                "조리개",
                apertureController,
                (v) {
                  currentExif.aperture = v;
                  onExifChanged(currentExif);
                },
                [
                  FilteringTextInputFormatter.singleLineFormatter,
                  FilteringTextInputFormatter.allow(RegExp(r'^[fF]?/?[0-9]*\.?[0-9]*$')),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _buildElegantField(
                "셔터 속도",
                shutterSpeedController,
                (v) {
                  currentExif.shutterSpeed = v;
                  onExifChanged(currentExif);
                },
                [
                  FilteringTextInputFormatter.singleLineFormatter,
                  FilteringTextInputFormatter.allow(RegExp(r'^[0-9/\"s]*$')),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildElegantField(
                "ISO",
                isoController,
                (v) {
                  currentExif.iso = v;
                  onExifChanged(currentExif);
                },
                [
                  FilteringTextInputFormatter.singleLineFormatter,
                  FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9\s]*$')),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildElegantField(
    String label,
    TextEditingController controller,
    Function(String) onChanged,
    List<TextInputFormatter>? inputFormatters,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppTheme.subtitleColor.withAlpha(150),
            ),
          ),
          TextField(
            controller: controller,
            inputFormatters: inputFormatters,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.uiWhite,
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
    final displayDate = value != null
        ? DateFormat("yyyy/MM/dd HH:mm").format(value)
        : "";
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppTheme.subtitleColor.withAlpha(150),
            ),
          ),
          InkWell(
            onTap: () async {
              final initialDate = value ?? DateTime.now();
              final date = await showDatePicker(
                context: parentContext,
                initialDate: initialDate,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppTheme.uiWhite,
                        onPrimary: Colors.black,
                        surface: AppTheme.canvasColor,
                        onSurface: AppTheme.uiWhite,
                        secondary: AppTheme.uiWhite,
                        onSecondary: Colors.black,
                        surfaceTint: Colors.transparent,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.uiWhite,
                          textStyle: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (date != null) {
                if (!parentContext.mounted) return;
                final time = await showTimePicker(
                  context: parentContext,
                  initialTime: TimeOfDay.fromDateTime(initialDate),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppTheme.uiWhite,
                          onPrimary: Colors.black,
                          surface: AppTheme.canvasColor,
                          onSurface: AppTheme.uiWhite,
                          secondary: AppTheme.uiWhite,
                          onSecondary: Colors.black,
                          surfaceTint: Colors.transparent,
                        ),
                        timePickerTheme: TimePickerThemeData(
                          backgroundColor: AppTheme.canvasColor,
                          hourMinuteTextColor: AppTheme.uiWhite,
                          hourMinuteColor: AppTheme.uiWhite.withAlpha(20),
                          dayPeriodTextColor: WidgetStateColor.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? Colors.black
                                  : AppTheme.uiWhite),
                          dayPeriodColor: WidgetStateColor.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? AppTheme.uiWhite
                                  : AppTheme.uiWhite.withAlpha(20)),
                          dialHandColor: AppTheme.uiWhite,
                          dialBackgroundColor: AppTheme.uiWhite.withAlpha(10),
                          dialTextColor: WidgetStateColor.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? Colors.black
                                  : AppTheme.uiWhite),
                          entryModeIconColor: AppTheme.uiWhite,
                          helpTextStyle: const TextStyle(
                              color: AppTheme.uiWhite,
                              fontFamily: 'Pretendard'),
                          cancelButtonStyle: TextButton.styleFrom(
                              foregroundColor: AppTheme.uiWhite,
                              textStyle:
                                  const TextStyle(fontFamily: 'Pretendard')),
                          confirmButtonStyle: TextButton.styleFrom(
                              foregroundColor: AppTheme.uiWhite,
                              textStyle:
                                  const TextStyle(fontFamily: 'Pretendard')),
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.uiWhite,
                            textStyle: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (time != null) {
                  currentExif.shotDate = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                  onExifChanged(currentExif);
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                displayDate.isEmpty ? "날짜 선택" : displayDate,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: displayDate.isEmpty ? Colors.grey : AppTheme.uiWhite,
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
