import 'package:flutter/material.dart';

import '../../domain/entities/app_route.dart';
import '../../../legal/presentation/legal_screens.dart';
import '../../../onboarding/presentation/onboarding_screen.dart';
import '../controllers/ledger_controller.dart';
import 'app_update_required_screen.dart';
import 'ledger_flow_screen.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

class LedgerHomeScreen extends StatefulWidget {
  const LedgerHomeScreen({required this.controller, super.key});

  final LedgerController controller;

  @override
  State<LedgerHomeScreen> createState() => _LedgerHomeScreenState();
}

class _LedgerHomeScreenState extends State<LedgerHomeScreen> {
  int _lastToastEventId = 0;

  LedgerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant LedgerHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == controller) {
      return;
    }
    oldWidget.controller.removeListener(_handleControllerChanged);
    _lastToastEventId = 0;
    controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    final event = controller.toastEvent;
    if (event == null || event.id == _lastToastEventId) {
      return;
    }
    _lastToastEventId = event.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(event.message)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  reverseDuration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) {
                    final direction = controller.isBackwardNavigation ? -1 : 1;
                    final slide =
                        Tween<Offset>(
                          begin: Offset(0.12 * direction, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        );
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: _screenForRoute(),
                ),
                if (controller.isLoading &&
                    controller.route != LedgerRoute.splash &&
                    controller.route != LedgerRoute.appUpdateRequired &&
                    controller.route != LedgerRoute.onboarding &&
                    controller.route != LedgerRoute.dashboard)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x66FFFFFF),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _screenForRoute() {
    return switch (controller.route) {
      LedgerRoute.splash => SplashScreen(
        key: const ValueKey('splash'),
        onDone: controller.completeSplash,
      ),
      LedgerRoute.appUpdateRequired => AppUpdateRequiredScreen(
        key: const ValueKey('app-update-required'),
        decision: controller.appCompatibilityDecision!,
        onRetry: controller.retryCompatibilityCheck,
      ),
      LedgerRoute.onboarding => OnboardingScreen(
        key: const ValueKey('onboarding'),
        onComplete: controller.completeOnboarding,
        onStarted: controller.trackOnboardingStarted,
        onScreenViewed: controller.trackOnboardingScreenViewed,
        onSkipped: controller.trackOnboardingSkipped,
      ),
      LedgerRoute.login => LoginScreen(
        key: const ValueKey('login'),
        controller: controller,
      ),
      LedgerRoute.register => RegisterScreen(
        key: const ValueKey('register'),
        controller: controller,
      ),
      LedgerRoute.emailVerificationPending => EmailVerificationScreen(
        key: const ValueKey('email-verification'),
        controller: controller,
      ),
      LedgerRoute.forgotPassword => ForgotPasswordScreen(
        key: const ValueKey('forgot-password'),
        controller: controller,
      ),
      LedgerRoute.resetPasswordOtp => ResetPasswordOtpScreen(
        key: const ValueKey('reset-password-otp'),
        controller: controller,
      ),
      LedgerRoute.privacyPolicyAcceptance => PrivacyPolicyAcceptanceView(
        key: const ValueKey('privacy-policy-acceptance'),
        controller: controller,
      ),
      _ => LedgerFlowScreen(
        key: ValueKey('ledger-${controller.route.name}'),
        controller: controller,
      ),
    };
  }
}
