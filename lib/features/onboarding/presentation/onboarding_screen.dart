import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/onboarding_page_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onComplete, super.key});

  final Future<void> Function() onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = <OnboardingPageModel>[
    OnboardingPageModel(
      title: 'Track Household\nServices Easily',
      subtitle:
          'Never forget milk deliveries, maid\nattendance, or monthly payments again.',
      illustration: OnboardingIllustration.services,
    ),
    OnboardingPageModel(
      title: 'Log Daily\nDeliveries & Attendance',
      subtitle:
          'Track quantity-based and\nattendance-based services with just a few taps.',
      illustration: OnboardingIllustration.dailyLog,
    ),
    OnboardingPageModel(
      title: 'Know What\nYou Owe',
      subtitle:
          'Payqure Home calculates pending dues,\nadvances, and carry forwards automatically.',
      illustration: OnboardingIllustration.amountDue,
    ),
    OnboardingPageModel(
      title: 'Keep Everything\nOrganized',
      subtitle:
          'Record payments, generate printable\nstatements, and manage service providers in one place.',
      illustration: OnboardingIllustration.organized,
    ),
  ];

  int _selectedPage = 0;
  bool _isCompleting = false;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: const ValueKey('onboarding-screen'),
        backgroundColor: const Color(0xFFEDE7FF),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  key: const ValueKey('onboarding-page-view'),
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _selectedPage = index);
                  },
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _FirstOnboardingPage(page: _pages[index]);
                    }
                    return _StandardOnboardingPage(page: _pages[index]);
                  },
                ),
              ),
              _OnboardingBottomBar(
                pageCount: _pages.length,
                selectedPage: _selectedPage,
                isLastPage: _selectedPage == _pages.length - 1,
                isLoading: _isCompleting,
                onSkip: _complete,
                onNext: _nextPage,
                onComplete: _complete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _complete() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);
    await widget.onComplete();
    if (mounted) setState(() => _isCompleting = false);
  }
}

// ─── Page 1: unique layout ────────────────────────────────────────────────────

class _FirstOnboardingPage extends StatelessWidget {
  const _FirstOnboardingPage({required this.page});
  final OnboardingPageModel page;

  static const _chips = [
    _ServiceChip(icon: '🥛', label: 'Milkman'),
    _ServiceChip(icon: '🧹', label: 'Maid'),
    _ServiceChip(icon: '🚗', label: 'Car Wash'),
    _ServiceChip(icon: '💧', label: 'Water Can'),
    _ServiceChip(icon: '···', label: 'More', isDotted: true),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationHeight = constraints.maxHeight * 0.44;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Illustration – top section with soft lavender bg
                SizedBox(
                  height: illustrationHeight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      0,
                    ),
                    child: ClipRect(
                      child: Transform.translate(
                        offset: const Offset(0, 36),
                        child: Image.asset(
                          AppAssets.onboardingServices,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ),

                // App icon + brand name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        AppAssets.appIcon,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Payqure ',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                          TextSpan(
                            text: 'Home',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              color: AppColors.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Title
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      height: 1.15,
                    ),
                  ),
                ),

                // Subtitle
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    page.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                ),

                // Service chips
                const SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        _ServiceChipRow(chips: _chips.take(3).toList()),
                        const SizedBox(height: AppSpacing.xs),
                        _ServiceChipRow(chips: _chips.skip(3).toList()),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiceChipRow extends StatelessWidget {
  const _ServiceChipRow({required this.chips});

  final List<_ServiceChip> chips;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < chips.length; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.xs),
          chips[index],
        ],
      ],
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({
    required this.icon,
    required this.label,
    this.isDotted = false,
  });

  final String icon;
  final String label;
  final bool isDotted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pages 2–4: standard layout ───────────────────────────────────────────────

class _StandardOnboardingPage extends StatelessWidget {
  const _StandardOnboardingPage({required this.page});
  final OnboardingPageModel page;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - AppSpacing.xxl,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title — purple, bold, centered
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Subtitle
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    page.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Illustration — transparent PNG
                _OnboardingIllustration(
                  type: page.illustration,
                  availableHeight: constraints.maxHeight * 0.52,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Illustration ─────────────────────────────────────────────────────────────

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({
    required this.type,
    required this.availableHeight,
  });

  final OnboardingIllustration type;
  final double availableHeight;

  bool get _usesLandscapeArtwork =>
      type == OnboardingIllustration.dailyLog ||
      type == OnboardingIllustration.organized;

  double get _height => switch (type) {
    OnboardingIllustration.dailyLog => 420,
    OnboardingIllustration.amountDue => 400,
    OnboardingIllustration.organized => 430,
    _ => 380,
  };

  double get _scale => switch (type) {
    OnboardingIllustration.dailyLog => 1.9,
    OnboardingIllustration.amountDue => 1.3,
    OnboardingIllustration.organized => 1.9,
    _ => 1,
  };

  String get _asset => switch (type) {
    OnboardingIllustration.services => AppAssets.onboardingServices,
    OnboardingIllustration.dailyLog => AppAssets.onboardingDailyLog,
    OnboardingIllustration.amountDue => AppAssets.onboardingWallet,
    OnboardingIllustration.organized => AppAssets.onboardingOrganized,
  };

  @override
  Widget build(BuildContext context) {
    final height = availableHeight.clamp(300.0, _height).toDouble();
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 390, maxHeight: height),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: ClipRect(
          child: Transform.scale(
            scale: _scale,
            alignment: Alignment.center,
            child: Image.asset(
              _asset,
              key: ValueKey(_asset),
              fit: _usesLandscapeArtwork ? BoxFit.contain : BoxFit.scaleDown,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Page indicator ───────────────────────────────────────────────────────────

class PageIndicator extends StatelessWidget {
  const PageIndicator({
    required this.pageCount,
    required this.selectedPage,
    super.key,
  });

  final int pageCount;
  final int selectedPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(pageCount, (index) {
        final isSelected = index == selectedPage;
        return AnimatedContainer(
          key: ValueKey('onboarding-dot-$index'),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: isSelected ? 20 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        );
      }),
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────

class _OnboardingBottomBar extends StatelessWidget {
  const _OnboardingBottomBar({
    required this.pageCount,
    required this.selectedPage,
    required this.isLastPage,
    required this.isLoading,
    required this.onSkip,
    required this.onNext,
    required this.onComplete,
  });

  final int pageCount;
  final int selectedPage;
  final bool isLastPage;
  final bool isLoading;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          // Skip
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const ValueKey('onboarding-skip'),
                onPressed: isLoading ? null : onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.muted,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Skip'),
              ),
            ),
          ),

          PageIndicator(pageCount: pageCount, selectedPage: selectedPage),

          // Next / Get Started
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: isLastPage
                  ? FilledButton(
                      key: const ValueKey('onboarding-get-started'),
                      onPressed: isLoading ? null : onComplete,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Get Started'),
                    )
                  : TextButton(
                      key: const ValueKey('onboarding-next'),
                      onPressed: isLoading ? null : onNext,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Next'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
