import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android uses Tide as the application label', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:label="Tide"'));
  });

  test('iOS uses Tide as the bundle name', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(
      infoPlist,
      matches(RegExp(r'<key>CFBundleName</key>\s*<string>Tide</string>')),
    );
  });

  test('macOS uses Tide as the product name', () {
    final appInfo = File(
      'macos/Runner/Configs/AppInfo.xcconfig',
    ).readAsStringSync();

    expect(appInfo, contains('PRODUCT_NAME = Tide'));
  });
}
