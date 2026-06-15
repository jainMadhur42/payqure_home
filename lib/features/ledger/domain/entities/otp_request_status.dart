enum OtpRequestPurpose { signup, passwordReset }

class OtpRequestStatus {
  const OtpRequestStatus({
    required this.usedCount,
    required this.windowResetsAt,
    required this.blocked,
  });

  static const maximumRequests = 3;

  final int usedCount;
  final DateTime? windowResetsAt;
  final bool blocked;

  Duration remaining(DateTime now) {
    final resetAt = windowResetsAt;
    if (resetAt == null) {
      return Duration.zero;
    }
    final remaining = resetAt.difference(now.toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

abstract interface class OtpRequestStatusProvider {
  OtpRequestStatus? statusFor(OtpRequestPurpose purpose);
}
