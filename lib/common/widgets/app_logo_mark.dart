import 'package:flutter/material.dart';

import '../../core/assets/app_assets.dart';

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({
    this.size = 88,
    this.borderRadius,
    this.fit = BoxFit.cover,
    super.key,
  });

  final double size;
  final double? borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? size * 0.22),
      child: Image.asset(
        AppAssets.appIcon,
        width: size,
        height: size,
        fit: fit,
      ),
    );
  }
}
