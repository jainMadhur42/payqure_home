import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/core/app_info/store_links.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('iOS resolves to the App Store listing', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(StoreLinks.storeName, 'App Store');
    expect(StoreLinks.reviewUrl, StoreLinks.appStoreUrl);
    expect(StoreLinks.reviewUrl, contains('apps.apple.com'));
    expect(StoreLinks.reviewUrl, contains('id6778286542'));
  });

  test('Android resolves to the Play Store listing', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    expect(StoreLinks.storeName, 'Play Store');
    expect(StoreLinks.reviewUrl, StoreLinks.playStoreUrl);
    expect(StoreLinks.reviewUrl, contains('play.google.com'));
    expect(StoreLinks.reviewUrl, contains('com.payqure.home'));
  });
}
