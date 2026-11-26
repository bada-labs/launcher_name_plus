import 'dart:io';

import 'package:launcher_name_plus/launcher_name_plus.dart';

/// Run from the root of a Flutter app: `dart run launcher_name_plus:main`.
void main() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('pubspec.yaml not found. Run this from your app root.');
    exit(66);
  }

  try {
    final namesByLanguage = LauncherName.readNamesByLanguage(
      pubspecFile.readAsStringSync(),
    );
    LauncherName(Directory.current).apply(namesByLanguage);
    stdout.writeln(
      'Localized the launcher name in ${namesByLanguage.length - 1} '
      'languages plus the default.',
    );
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exit(65);
  } on FileSystemException catch (error) {
    stderr.writeln('${error.message}: ${error.path}');
    exit(74);
  }
}
