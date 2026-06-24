import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import 'ledger_screen_shared.dart';

class Shimmer extends StatefulWidget {
  const Shimmer({required this.child, super.key});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final value = _controller.value;
            return LinearGradient(
              begin: Alignment(-1.0 + value * 2.4, -0.35),
              end: Alignment(-0.2 + value * 2.4, 0.35),
              colors: [
                AppColors.line.withValues(alpha: 0.55),
                Colors.white.withValues(alpha: 0.92),
                AppColors.line.withValues(alpha: 0.55),
              ],
              stops: const [0.15, 0.50, 0.85],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    required this.height,
    this.width,
    this.radius = AppRadius.md,
    super.key,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.line.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class HomeLoadingSkeleton extends StatelessWidget {
  const HomeLoadingSkeleton({required this.monthKey, super.key});

  final String monthKey;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            104,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Shimmer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBox(width: 112, height: 14, radius: 8),
                        SizedBox(height: AppSpacing.sm),
                        SkeletonBox(width: 170, height: 26, radius: 10),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    monthLabelShort(monthKey),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const _HeroSkeleton(),
            const SizedBox(height: AppSpacing.lg),
            const _QuickActionSkeleton(),
            const SizedBox(height: AppSpacing.lg),
            Shimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 96, height: 24, radius: 10),
                  SizedBox(height: AppSpacing.sm),
                  HomeServiceListSkeleton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeServiceListSkeleton extends StatelessWidget {
  const HomeServiceListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: List.generate(
          4,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: _ServiceCardSkeleton(),
          ),
        ),
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 86, height: 14, radius: 8),
            SizedBox(height: AppSpacing.sm),
            SkeletonBox(width: 160, height: 36, radius: 12),
            SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 42, radius: 12)),
                SizedBox(width: AppSpacing.lg),
                Expanded(child: SkeletonBox(height: 42, radius: 12)),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 42, radius: 12)),
                SizedBox(width: AppSpacing.lg),
                Expanded(child: SkeletonBox(height: 42, radius: 12)),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            SkeletonBox(width: 132, height: 16, radius: 8),
          ],
        ),
      ),
    );
  }
}

class _QuickActionSkeleton extends StatelessWidget {
  const _QuickActionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.45)),
      ),
      child: Shimmer(
        child: Row(
          children: const [
            SkeletonBox(width: 48, height: 48, radius: AppRadius.md),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 130, height: 18, radius: 8),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonBox(width: 210, height: 13, radius: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCardSkeleton extends StatelessWidget {
  const _ServiceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(width: 44, height: 44, radius: 8),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 130, height: 18, radius: 8),
                SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: 180, height: 12, radius: 7),
                SizedBox(height: AppSpacing.md),
                SkeletonBox(width: 150, height: 15, radius: 8),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 82, height: 22, radius: 999),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonBox(width: 72, height: 12, radius: 7),
              SizedBox(height: AppSpacing.xs),
              SkeletonBox(width: 86, height: 20, radius: 8),
            ],
          ),
        ],
      ),
    );
  }
}
