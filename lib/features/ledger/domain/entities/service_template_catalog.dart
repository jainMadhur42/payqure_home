import 'service_template.dart';

enum ServiceTemplateCategory {
  daily('Daily Services'),
  attendance('Attendance Services'),
  monthly('Monthly Services'),
  custom('Custom Services');

  const ServiceTemplateCategory(this.label);

  final String label;
}

class ServiceTemplateDefinition {
  const ServiceTemplateDefinition({
    required this.id,
    required this.title,
    required this.emoji,
    required this.iconIdentifier,
    required this.templateType,
    required this.category,
    required this.units,
    required this.defaultUnit,
    this.defaultQuantity = 1,
    this.isCustom = false,
  });

  final String id;
  final String title;
  final String emoji;
  final String iconIdentifier;
  final ServiceTemplateType templateType;
  final ServiceTemplateCategory category;
  final List<String> units;
  final String defaultUnit;
  final double defaultQuantity;
  final bool isCustom;
}

abstract final class ServiceTemplateCatalog {
  static const templates = <ServiceTemplateDefinition>[
    ServiceTemplateDefinition(
      id: 'milkman',
      title: 'Milkman',
      emoji: '🥛',
      iconIdentifier: 'milk',
      templateType: ServiceTemplateType.quantity,
      category: ServiceTemplateCategory.daily,
      units: ['Liter', 'Milliliter', 'Packet', 'Bottle'],
      defaultUnit: 'Liter',
    ),
    ServiceTemplateDefinition(
      id: 'water_can',
      title: 'Water Can',
      emoji: '💧',
      iconIdentifier: 'water',
      templateType: ServiceTemplateType.quantity,
      category: ServiceTemplateCategory.daily,
      units: ['Can', 'Bottle', 'Jar', 'Liter'],
      defaultUnit: 'Can',
    ),
    ServiceTemplateDefinition(
      id: 'ironing_service',
      title: 'Ironing Service',
      emoji: '👕',
      iconIdentifier: 'ironing_service',
      templateType: ServiceTemplateType.quantity,
      category: ServiceTemplateCategory.daily,
      units: ['Piece', 'Clothes', 'Set'],
      defaultUnit: 'Piece',
    ),
    ServiceTemplateDefinition(
      id: 'laundry_service',
      title: 'Laundry Service',
      emoji: '🧺',
      iconIdentifier: 'laundry',
      templateType: ServiceTemplateType.quantity,
      category: ServiceTemplateCategory.daily,
      units: ['Kg', 'Piece', 'Bundle'],
      defaultUnit: 'Kg',
    ),
    ServiceTemplateDefinition(
      id: 'ironing',
      title: 'Ironing',
      emoji: '👔',
      iconIdentifier: 'ironing',
      templateType: ServiceTemplateType.quantity,
      category: ServiceTemplateCategory.daily,
      units: ['Piece', 'Clothes'],
      defaultUnit: 'Piece',
    ),
    ServiceTemplateDefinition(
      id: 'tiffin_service',
      title: 'Tiffin Service',
      emoji: '🍱',
      iconIdentifier: 'tiffin',
      templateType: ServiceTemplateType.quantity,
      category: ServiceTemplateCategory.daily,
      units: ['Meal', 'Tiffin', 'Plate'],
      defaultUnit: 'Meal',
    ),
    ServiceTemplateDefinition(
      id: 'egg_delivery',
      title: 'Egg Delivery',
      emoji: '🥚',
      iconIdentifier: 'egg',
      templateType: ServiceTemplateType.quantity,
      category: ServiceTemplateCategory.daily,
      units: ['Piece', 'Dozen', 'Tray'],
      defaultUnit: 'Piece',
    ),
    ServiceTemplateDefinition(
      id: 'vegetable_delivery',
      title: 'Vegetable Delivery',
      emoji: '🥬',
      iconIdentifier: 'vegetable',
      templateType: ServiceTemplateType.quantity,
      category: ServiceTemplateCategory.daily,
      units: ['Kg', 'Gram', 'Packet'],
      defaultUnit: 'Kg',
    ),
    ServiceTemplateDefinition(
      id: 'pet_food_delivery',
      title: 'Pet Food Delivery',
      emoji: '🐶',
      iconIdentifier: 'pet_food',
      templateType: ServiceTemplateType.quantity,
      category: ServiceTemplateCategory.daily,
      units: ['Packet', 'Kg', 'Box'],
      defaultUnit: 'Packet',
    ),
    ServiceTemplateDefinition(
      id: 'flower_maala_delivery',
      title: 'Flower Maala Delivery',
      emoji: '🌸',
      iconIdentifier: 'flower',
      templateType: ServiceTemplateType.quantity,
      category: ServiceTemplateCategory.daily,
      units: ['Packet', 'Piece', 'Bundle'],
      defaultUnit: 'Packet',
    ),
    ServiceTemplateDefinition(
      id: 'maid',
      title: 'Maid',
      emoji: '🧹',
      iconIdentifier: 'maid',
      templateType: ServiceTemplateType.attendance,
      category: ServiceTemplateCategory.attendance,
      units: [],
      defaultUnit: 'Day',
    ),
    ServiceTemplateDefinition(
      id: 'cook',
      title: 'Cook',
      emoji: '👩‍🍳',
      iconIdentifier: 'cook',
      templateType: ServiceTemplateType.attendance,
      category: ServiceTemplateCategory.attendance,
      units: [],
      defaultUnit: 'Day',
    ),
    ServiceTemplateDefinition(
      id: 'driver',
      title: 'Driver',
      emoji: '🚗',
      iconIdentifier: 'driver',
      templateType: ServiceTemplateType.attendance,
      category: ServiceTemplateCategory.attendance,
      units: [],
      defaultUnit: 'Day',
    ),
    ServiceTemplateDefinition(
      id: 'babysitter',
      title: 'Babysitter',
      emoji: '👶',
      iconIdentifier: 'babysitter',
      templateType: ServiceTemplateType.attendance,
      category: ServiceTemplateCategory.attendance,
      units: [],
      defaultUnit: 'Day',
    ),
    ServiceTemplateDefinition(
      id: 'gardener',
      title: 'Gardener',
      emoji: '🌱',
      iconIdentifier: 'gardener',
      templateType: ServiceTemplateType.attendance,
      category: ServiceTemplateCategory.attendance,
      units: [],
      defaultUnit: 'Day',
    ),
    ServiceTemplateDefinition(
      id: 'car_wash',
      title: 'Car Wash',
      emoji: '🚘',
      iconIdentifier: 'car',
      templateType: ServiceTemplateType.attendance,
      category: ServiceTemplateCategory.attendance,
      units: [],
      defaultUnit: 'Day',
    ),
    ServiceTemplateDefinition(
      id: 'newspaper',
      title: 'Newspaper',
      emoji: '📰',
      iconIdentifier: 'news',
      templateType: ServiceTemplateType.fixedMonthly,
      category: ServiceTemplateCategory.monthly,
      units: [],
      defaultUnit: 'Month',
    ),
    ServiceTemplateDefinition(
      id: 'custom_quantity',
      title: 'Quantity Based',
      emoji: '📦',
      iconIdentifier: 'custom_quantity',
      templateType: ServiceTemplateType.quantity,
      category: ServiceTemplateCategory.custom,
      units: ['Unit', 'Piece', 'Kg', 'Liter', 'Packet'],
      defaultUnit: 'Unit',
      isCustom: true,
    ),
    ServiceTemplateDefinition(
      id: 'custom_attendance',
      title: 'Attendance Based',
      emoji: '👤',
      iconIdentifier: 'custom_attendance',
      templateType: ServiceTemplateType.attendance,
      category: ServiceTemplateCategory.custom,
      units: [],
      defaultUnit: 'Day',
      isCustom: true,
    ),
    ServiceTemplateDefinition(
      id: 'custom_monthly',
      title: 'Fixed Monthly',
      emoji: '📅',
      iconIdentifier: 'custom_monthly',
      templateType: ServiceTemplateType.fixedMonthly,
      category: ServiceTemplateCategory.custom,
      units: [],
      defaultUnit: 'Month',
      isCustom: true,
    ),
  ];

  static ServiceTemplateDefinition byId(String? id) {
    return templates.firstWhere(
      (template) => template.id == id,
      orElse: () => templates.first,
    );
  }

  static ServiceTemplateDefinition forService({
    required String name,
    required String icon,
    required ServiceTemplateType type,
    String? templateId,
  }) {
    for (final template in templates) {
      if (template.id == templateId ||
          template.iconIdentifier == icon ||
          template.title.toLowerCase() == name.toLowerCase()) {
        return template;
      }
    }
    return templates.firstWhere(
      (template) => template.isCustom && template.templateType == type,
    );
  }
}
