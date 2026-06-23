import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android notification icon exists and is protected from shrinking', () {
    final icon = File('android/app/src/main/res/drawable/ic_notification.xml');
    final keepRules = File('android/app/src/main/res/raw/keep.xml');

    expect(icon.existsSync(), isTrue);
    expect(keepRules.existsSync(), isTrue);
    expect(
      keepRules.readAsStringSync(),
      contains('tools:keep="@drawable/ic_notification"'),
    );
  });
}
