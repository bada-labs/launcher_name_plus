import 'dart:io';

import 'package:launcher_name_plus/launcher_name_plus.dart';
import 'package:test/test.dart';

void main() {
  late Directory projectDirectory;

  File projectFile(String relativePath) =>
      File('${projectDirectory.path}/$relativePath');

  void writeProjectFile(String relativePath, String contents) => (projectFile(
        relativePath,
      )..createSync(recursive: true))
          .writeAsStringSync(contents);

  setUp(() {
    projectDirectory = Directory.systemTemp.createTempSync('launcher_name');
    writeProjectFile(
      'android/app/src/main/AndroidManifest.xml',
      '<manifest>\n    <application\n        android:label="Old">\n'
          '    </application>\n</manifest>\n',
    );
    writeProjectFile(
      'android/app/src/main/res/values-night/styles.xml',
      '<resources/>',
    );
    writeProjectFile(
      'android/app/src/main/res/values-de/strings.xml',
      '<resources/>',
    );
    writeProjectFile(
      'ios/Runner/Info.plist',
      '<dict>\n\t<key>CFBundleDisplayName</key>\n\t<string>Old</string>\n</dict>\n',
    );
    writeProjectFile('ios/Runner/Resources/de.lproj/InfoPlist.strings', '');
  });

  tearDown(() => projectDirectory.deleteSync(recursive: true));

  test('reads names by language and requires a default entry', () {
    expect(
      LauncherName.readNamesByLanguage(
        'launcher_name:\n  default: App\n  ko: 앱\n',
      ),
      {'default': 'App', 'ko': '앱'},
    );
    expect(
      () => LauncherName.readNamesByLanguage('launcher_name:\n  ko: 앱\n'),
      throwsFormatException,
    );
    expect(
      () => LauncherName.readNamesByLanguage('name: app\n'),
      throwsFormatException,
    );
    expect(() => LauncherName.readNamesByLanguage(''), throwsFormatException);
  });

  test('writes localized names and removes dropped languages', () {
    LauncherName(projectDirectory).apply({'default': 'App', 'ko': '앱'});

    expect(
      projectFile(
        'android/app/src/main/res/values-ko/strings.xml',
      ).readAsStringSync(),
      '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
      '  <string name="appName">앱</string>\n</resources>',
    );
    expect(
      projectFile('android/app/src/main/res/values/strings.xml').existsSync(),
      isTrue,
    );
    expect(
      Directory(
        '${projectDirectory.path}/android/app/src/main/res/values-de',
      ).existsSync(),
      isFalse,
    );
    expect(
      projectFile(
        'android/app/src/main/res/values-night/styles.xml',
      ).existsSync(),
      isTrue,
    );
    expect(
      projectFile(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync(),
      contains('android:label="@string/appName"'),
    );

    expect(
      projectFile(
        'ios/Runner/Resources/ko.lproj/InfoPlist.strings',
      ).readAsStringSync(),
      '"CFBundleDisplayName" = "앱";',
    );
    expect(
      projectFile('ios/Runner/Resources/InfoPlist.strings').readAsStringSync(),
      '"CFBundleDisplayName" = "App";',
    );
    expect(
      Directory(
        '${projectDirectory.path}/ios/Runner/Resources/de.lproj',
      ).existsSync(),
      isFalse,
    );
    expect(
      projectFile('ios/Runner/Info.plist').readAsStringSync(),
      '<dict>\n\t<key>CFBundleDisplayName</key>\n'
      '\t<string>\${PRODUCT_NAME}</string>\n</dict>',
    );
  });

  test('escapes characters that break Android and iOS string files', () {
    expect(
      LauncherName.escapeAndroidString('Tom\'s \\ <A&B> "x"'),
      'Tom\\\'s \\\\ &lt;A&amp;B> \\"x\\"',
    );
    expect(LauncherName.escapeAndroidString('@app'), r'\@app');
    expect(LauncherName.escapeIosString(r'Say "hi" \o/'), r'Say \"hi\" \\o/');
  });
}
