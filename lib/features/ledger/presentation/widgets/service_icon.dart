import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/service_template.dart';
import '../../domain/entities/service_template_catalog.dart';

class ServiceIcon extends StatelessWidget {
  const ServiceIcon({
    required this.icon,
    required this.color,
    this.serviceName,
    this.templateType,
    this.size = 44,
    super.key,
  });

  final String icon;
  final Color color;
  final String? serviceName;
  final ServiceTemplateType? templateType;
  final double size;

  @override
  Widget build(BuildContext context) {
    final template = templateType == null
        ? null
        : ServiceTemplateCatalog.forService(
            name: serviceName ?? '',
            icon: icon,
            type: templateType!,
          );
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: template == null
          ? Icon(_iconData, color: color, size: size * 0.52)
          : Text(
              template.emoji,
              style: TextStyle(fontSize: size * 0.48, height: 1),
            ),
    );
  }

  IconData get _iconData {
    return switch (icon) {
      'milk' => Icons.local_drink_outlined,
      'person' => Icons.person_pin_circle_outlined,
      'car' => Icons.directions_car_filled_outlined,
      'news' => Icons.newspaper_outlined,
      'water' => Icons.water_drop_outlined,
      'ironing_service' || 'ironing' => Icons.iron_outlined,
      'laundry' => Icons.local_laundry_service_outlined,
      'tiffin' => Icons.lunch_dining_outlined,
      'egg' => Icons.egg_outlined,
      'vegetable' => Icons.eco_outlined,
      'pet_food' => Icons.pets_outlined,
      'flower' => Icons.local_florist_outlined,
      'maid' => Icons.cleaning_services_outlined,
      'cook' => Icons.soup_kitchen_outlined,
      'driver' => Icons.drive_eta_outlined,
      'babysitter' => Icons.child_care_outlined,
      'gardener' => Icons.yard_outlined,
      'custom_quantity' => Icons.inventory_2_outlined,
      'custom_attendance' => Icons.person_outline,
      'custom_monthly' => Icons.calendar_month_outlined,
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
