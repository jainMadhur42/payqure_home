import 'package:package_info_plus/package_info_plus.dart';

class AppVersionInfo {
  const AppVersionInfo({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  String get label {
    if (buildNumber.trim().isEmpty) {
      return 'Version $version';
    }
    return 'Version $version ($buildNumber)';
  }
}

abstract interface class AppVersionProvider {
  Future<AppVersionInfo> load();
}

class PackageInfoAppVersionProvider implements AppVersionProvider {
  const PackageInfoAppVersionProvider();

  @override
  Future<AppVersionInfo> load() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return AppVersionInfo(
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );
  }
}

class FallbackAppVersionProvider implements AppVersionProvider {
  const FallbackAppVersionProvider();

  @override
  Future<AppVersionInfo> load() async {
    return const AppVersionInfo(version: '1.0.0', buildNumber: '1');
  }
}
