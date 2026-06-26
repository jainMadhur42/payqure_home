import 'package:url_launcher/url_launcher.dart';

/// External feedback links (improvement suggestions form).
abstract final class FeedbackLinks {
  static const suggestionFormUrl = 'https://forms.gle/M41Qzj8y9cHCkjVy9';

  /// Opens the suggestions form in the browser. Returns `true` when launched.
  static Future<bool> openSuggestionForm() async {
    final uri = Uri.parse(suggestionFormUrl);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
