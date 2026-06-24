import 'device_os_unsupported.dart'
    if (dart.library.io) 'device_os_io.dart'
    as platform;

/// A human-readable `os version` string for the current device (e.g.
/// `android 14 (API 34)` or `ios Version 17.2`), or `null` when it cannot be
/// determined (such as on the web).
String? currentDeviceOs() => platform.deviceOs();
