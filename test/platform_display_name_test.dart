import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

String _lastXcconfigValue(String contents, String key) {
  final assignments = RegExp(
    '^\\s*${RegExp.escape(key)}\\s*=\\s*(.+?)\\s*\$',
    multiLine: true,
  ).allMatches(contents);

  return assignments.last.group(1)!.trim();
}

String? _plistString(String contents, String key) => RegExp(
  '<key>\\s*${RegExp.escape(key)}\\s*</key>\\s*<string>\\s*(.*?)\\s*</string>',
  dotAll: true,
).firstMatch(contents)?.group(1);

void main() {
  test('Android uses Tide as the application label', () {
    final manifest = _read('android/app/src/main/AndroidManifest.xml');
    final application = RegExp(
      r'<application\b[^>]*>',
      dotAll: true,
    ).firstMatch(manifest)!.group(0)!;

    expect(
      application,
      matches(RegExp(r'''android:label\s*=\s*["']Tide["']''')),
    );
  });

  test('iOS uses Tide as the bundle name', () {
    final infoPlist = _read('ios/Runner/Info.plist');

    expect(_plistString(infoPlist, 'CFBundleName'), 'Tide');
  });

  test('macOS uses its effective product name in the project product', () {
    final appInfo = _read('macos/Runner/Configs/AppInfo.xcconfig');
    final project = _read('macos/Runner.xcodeproj/project.pbxproj');
    final productName = _lastXcconfigValue(appInfo, 'PRODUCT_NAME');
    final appName = '$productName.app';

    expect(productName, 'Tide');
    expect(project, contains('/* $appName */'));
    expect(project, contains('path = $appName;'));
    expect(
      project,
      isNot(matches(RegExp(r'/\* tide\.app \*/|path = tide\.app;'))),
    );
  });

  test('macOS test hosts use the effective product and executable names', () {
    final appInfo = _read('macos/Runner/Configs/AppInfo.xcconfig');
    final project = _read('macos/Runner.xcodeproj/project.pbxproj');
    final productName = _lastXcconfigValue(appInfo, 'PRODUCT_NAME');
    final expectedTestHost =
        r'$(BUILT_PRODUCTS_DIR)/'
        '$productName.app/'
        r'$(BUNDLE_EXECUTABLE_FOLDER_PATH)/'
        '$productName';

    final testHosts = RegExp(
      r'TEST_HOST\s*=\s*"([^"]+)";',
    ).allMatches(project).map((match) => match.group(1));
    expect(testHosts, isNotEmpty);
    expect(testHosts, everyElement(expectedTestHost));
    expect(project, isNot(contains('/tide.app/')));
    expect(project, isNot(contains(r'$(BUNDLE_EXECUTABLE_FOLDER_PATH)/tide')));
  });

  test('macOS scheme uses the effective Runner product name', () {
    final appInfo = _read('macos/Runner/Configs/AppInfo.xcconfig');
    final scheme = _read(
      'macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme',
    );
    final productName = _lastXcconfigValue(appInfo, 'PRODUCT_NAME');
    final appName = '$productName.app';

    final runnerBuildableNames = RegExp(
      r'BuildableName\s*=\s*"([^"]+\.app)"',
    ).allMatches(scheme).map((match) => match.group(1));
    expect(runnerBuildableNames, isNotEmpty);
    expect(runnerBuildableNames, everyElement(appName));

    expect(scheme, isNot(contains('tide.app')));
  });

  test('technical application identifiers remain lowercase', () {
    final androidBuild = _read('android/app/build.gradle.kts');
    final macAppInfo = _read('macos/Runner/Configs/AppInfo.xcconfig');
    final iosProject = _read('ios/Runner.xcodeproj/project.pbxproj');
    final pubspec = _read('pubspec.yaml');

    expect(androidBuild, contains('namespace = "app.tidenotes.tide"'));
    expect(androidBuild, contains('applicationId = "app.tidenotes.tide"'));
    expect(
      _lastXcconfigValue(macAppInfo, 'PRODUCT_BUNDLE_IDENTIFIER'),
      'app.tidenotes.tide',
    );
    expect(
      iosProject,
      contains('PRODUCT_BUNDLE_IDENTIFIER = app.tidenotes.tide;'),
    );
    expect(pubspec, matches(RegExp(r'^name:\s*tide\s*$', multiLine: true)));
  });
}
