import 'dart:io';

import 'package:test/test.dart';

void main() {
  late Directory appDirectory;
  final mainScript = File('bin/main.dart').absolute.path;

  Future<ProcessResult> runCli() => Process.run(
        Platform.resolvedExecutable,
        ['run', mainScript],
        workingDirectory: appDirectory.path,
      );

  setUp(() {
    appDirectory = Directory.systemTemp.createTempSync('launcher_name_cli');
  });

  tearDown(() => appDirectory.deleteSync(recursive: true));

  test('fails when pubspec.yaml is missing', () async {
    final result = await runCli();

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('pubspec.yaml not found'));
  });

  test('fails when the default name is missing', () async {
    File('${appDirectory.path}/pubspec.yaml')
        .writeAsStringSync('name: app\nlauncher_name:\n  ko: 앱\n');

    final result = await runCli();

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('default'));
  });

  test('writes localized names for a Flutter app layout', () async {
    File('${appDirectory.path}/pubspec.yaml').writeAsStringSync(
      'name: app\nlauncher_name:\n  default: "L\'app"\n  ko: 앱\n',
    );
    File('${appDirectory.path}/android/app/src/main/AndroidManifest.xml')
      ..createSync(recursive: true)
      ..writeAsStringSync('<application android:label="app">\n');
    Directory('${appDirectory.path}/android/app/src/main/res')
        .createSync(recursive: true);
    File('${appDirectory.path}/ios/Runner/Info.plist')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        '<key>CFBundleDisplayName</key>\n<string>App</string>\n',
      );

    final result = await runCli();

    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(
      File('${appDirectory.path}/android/app/src/main/res/values/strings.xml')
          .readAsStringSync(),
      contains(r"L\'app"),
    );
    expect(
      File('${appDirectory.path}/ios/Runner/Resources/ko.lproj/InfoPlist.strings')
          .readAsStringSync(),
      '"CFBundleDisplayName" = "앱";',
    );
  });
}
