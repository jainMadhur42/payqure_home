enum AppToastTone { success, error, info, warning }

class AppToastEvent {
  const AppToastEvent({
    required this.id,
    required this.message,
    this.tone = AppToastTone.success,
  });

  final int id;
  final String message;
  final AppToastTone tone;
}
