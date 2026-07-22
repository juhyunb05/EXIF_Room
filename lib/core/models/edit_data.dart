import 'package:flutter/material.dart';

class EditData {
  final Rect cropRect;
  final double fineAngle;

  const EditData({
    this.cropRect = const Rect.fromLTWH(0, 0, 1, 1),
    this.fineAngle = 0.0,
  });

  bool get isIdentity => cropRect == const Rect.fromLTWH(0, 0, 1, 1) && fineAngle == 0.0;

  EditData copyWith({
    Rect? cropRect,
    double? fineAngle,
  }) {
    return EditData(
      cropRect: cropRect ?? this.cropRect,
      fineAngle: fineAngle ?? this.fineAngle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditData &&
          runtimeType == other.runtimeType &&
          cropRect == other.cropRect &&
          fineAngle == other.fineAngle;

  @override
  int get hashCode => cropRect.hashCode ^ fineAngle.hashCode;
}
