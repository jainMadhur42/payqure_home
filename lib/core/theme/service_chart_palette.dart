import 'package:flutter/material.dart';

abstract final class ServiceChartPalette {
  static const colors = <Color>[
    Color(0xFF5B34DA),
    Color(0xFF00897B),
    Color(0xFFE65100),
    Color(0xFF1565C0),
    Color(0xFFC62828),
    Color(0xFF6A1B9A),
    Color(0xFF2E7D32),
    Color(0xFFAD1457),
    Color(0xFF00695C),
    Color(0xFFEF6C00),
    Color(0xFF283593),
    Color(0xFF558B2F),
    Color(0xFF00838F),
    Color(0xFFD84315),
    Color(0xFF4527A0),
    Color(0xFF0277BD),
    Color(0xFF9E9D24),
    Color(0xFF7B1FA2),
    Color(0xFF00796B),
    Color(0xFF3949AB),
    Color(0xFFF4511E),
    Color(0xFF43A047),
    Color(0xFF8E24AA),
    Color(0xFF039BE5),
    Color(0xFFC0A000),
    Color(0xFF5E35B1),
    Color(0xFF00ACC1),
    Color(0xFFE53935),
    Color(0xFF7CB342),
    Color(0xFFEC407A),
  ];

  static Color colorAt(int index) => colors[index % colors.length];
}
