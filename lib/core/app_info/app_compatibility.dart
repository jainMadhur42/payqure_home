import 'package:pub_semver/pub_semver.dart';

abstract final class AppCompatibilityContract {
  static const clientSchemaVersion = 6;
}

enum AppCompatibilityStatus {
  compatible,
  updateAvailable,
  appUpdateRequired,
  backendUpgradeRequired,
}

class AppCompatibilityConfig {
  const AppCompatibilityConfig({
    required this.currentSchemaVersion,
    required this.minimumSupportedSchemaVersion,
    required this.minimumAppVersion,
    required this.latestAppVersion,
  });

  final int currentSchemaVersion;
  final int minimumSupportedSchemaVersion;
  final String minimumAppVersion;
  final String latestAppVersion;

  factory AppCompatibilityConfig.fromJson(Map<String, dynamic> json) {
    return AppCompatibilityConfig(
      currentSchemaVersion: _int(json['current_schema_version']),
      minimumSupportedSchemaVersion: _int(
        json['minimum_supported_schema_version'],
      ),
      minimumAppVersion: json['minimum_app_version'].toString(),
      latestAppVersion: json['latest_app_version'].toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'current_schema_version': currentSchemaVersion,
    'minimum_supported_schema_version': minimumSupportedSchemaVersion,
    'minimum_app_version': minimumAppVersion,
    'latest_app_version': latestAppVersion,
  };

  static int _int(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.parse(value.toString());
  }
}

class AppCompatibilityDecision {
  const AppCompatibilityDecision({
    required this.status,
    required this.config,
    required this.installedAppVersion,
    required this.clientSchemaVersion,
  });

  final AppCompatibilityStatus status;
  final AppCompatibilityConfig config;
  final String installedAppVersion;
  final int clientSchemaVersion;

  bool get blocksApp =>
      status == AppCompatibilityStatus.appUpdateRequired ||
      status == AppCompatibilityStatus.backendUpgradeRequired;
}

abstract final class AppCompatibilityEvaluator {
  static AppCompatibilityDecision evaluate({
    required AppCompatibilityConfig config,
    required String installedAppVersion,
    required int clientSchemaVersion,
  }) {
    final installed = Version.parse(installedAppVersion);
    final minimum = Version.parse(config.minimumAppVersion);
    final latest = Version.parse(config.latestAppVersion);
    if (config.currentSchemaVersion < config.minimumSupportedSchemaVersion ||
        latest < minimum) {
      throw const FormatException('Invalid app compatibility configuration.');
    }

    final status =
        clientSchemaVersion < config.minimumSupportedSchemaVersion ||
            installed < minimum
        ? AppCompatibilityStatus.appUpdateRequired
        : clientSchemaVersion > config.currentSchemaVersion
        ? AppCompatibilityStatus.backendUpgradeRequired
        : installed < latest
        ? AppCompatibilityStatus.updateAvailable
        : AppCompatibilityStatus.compatible;

    return AppCompatibilityDecision(
      status: status,
      config: config,
      installedAppVersion: installedAppVersion,
      clientSchemaVersion: clientSchemaVersion,
    );
  }
}
