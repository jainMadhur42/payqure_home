import 'package:flutter/material.dart';

enum ServiceTemplateType { quantity, attendance, fixedMonthly }

extension ServiceTemplateTypeX on ServiceTemplateType {
  String get label {
    return switch (this) {
      ServiceTemplateType.quantity => 'Quantity Based',
      ServiceTemplateType.attendance => 'Attendance Based',
      ServiceTemplateType.fixedMonthly => 'Fixed Monthly',
    };
  }

  Color get color {
    return switch (this) {
      ServiceTemplateType.quantity => const Color(0xFF0E9F52),
      ServiceTemplateType.attendance => const Color(0xFFFF6B1A),
      ServiceTemplateType.fixedMonthly => const Color(0xFF1668E8),
    };
  }
}
