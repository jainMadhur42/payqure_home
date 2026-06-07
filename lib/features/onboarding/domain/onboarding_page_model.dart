enum OnboardingIllustration { services, dailyLog, amountDue, organized }

class OnboardingPageModel {
  const OnboardingPageModel({
    required this.title,
    required this.subtitle,
    required this.illustration,
  });

  final String title;
  final String subtitle;
  final OnboardingIllustration illustration;
}
