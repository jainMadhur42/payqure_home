import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Platform-aware links to the app's store listings and the logic to open the
/// correct one for rating/reviewing.
abstract final class StoreLinks {
  static const appStoreUrl =
      'https://apps.apple.com/in/app/payqure-home-milk-made-tracker/id6778286542';
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.payqure.home';

  static bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  /// `App Store` on iOS, `Play Store` everywhere else (Android default).
  static String get storeName => _isIos ? 'App Store' : 'Play Store';

  /// The store listing URL for the current OS.
  static String get reviewUrl => _isIos ? appStoreUrl : playStoreUrl;

  /// Opens the store listing for the current OS in the store app/browser.
  /// Returns `true` when it launched successfully.
  static Future<bool> openReview() async {
    final uri = Uri.parse(reviewUrl);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
