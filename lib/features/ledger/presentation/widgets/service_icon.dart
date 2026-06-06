import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

class ServiceIcon extends StatelessWidget {
  const ServiceIcon({required this.icon, required this.color, super.key});

  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_iconData, color: color),
    );
  }

  IconData get _iconData {
    return switch (icon) {
      'milk' => Icons.local_drink_outlined,
      'person' => Icons.person_pin_circle_outlined,
      'car' => Icons.directions_car_filled_outlined,
      'news' => Icons.newspaper_outlined,
      'water' => Icons.water_drop_outlined,
      _ => Icons.home_repair_service_outlined,
    };
  }
}

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({this.size = 88, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        AppAssets.appIcon,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
