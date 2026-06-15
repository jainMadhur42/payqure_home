import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository contains only Android and iOS platform projects', () {
    expect(Directory('android').existsSync(), isTrue);
    expect(Directory('ios').existsSync(), isTrue);
    expect(Directory('web').existsSync(), isFalse);
    expect(Directory('macos').existsSync(), isFalse);
    expect(Directory('linux').existsSync(), isFalse);
    expect(Directory('windows').existsSync(), isFalse);

    final metadata = File('.metadata').readAsStringSync();
    expect(metadata, isNot(contains('platform: web')));
    expect(metadata, isNot(contains('platform: macos')));
    expect(metadata, isNot(contains('platform: linux')));
    expect(metadata, isNot(contains('platform: windows')));
  });

  test('iOS target is configured for iPhone only', () {
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
    final appIconContents = File(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
    ).readAsStringSync();

    expect(project, isNot(contains('TARGETED_DEVICE_FAMILY = "1,2"')));
    expect(project, isNot(contains('TARGETED_DEVICE_FAMILY = 2')));
    expect(infoPlist, isNot(contains('UISupportedInterfaceOrientations~ipad')));
    expect(infoPlist, contains('<key>UIRequiresFullScreen</key>'));
    expect(infoPlist, contains('<true/>'));
    expect(appIconContents, isNot(contains('"idiom" : "ipad"')));
  });
}
