import 'dart:io';

import 'package:yaml/yaml.dart';

/// Writes the `launcher_name` section of `pubspec.yaml` as the localized app
/// name on Android (`values-<lang>/strings.xml`) and iOS
/// (`<lang>.lproj/InfoPlist.strings`). The `default` entry is the name for
/// languages without their own entry.
///
/// Output matches `launcher_name` 1.0.2 byte for byte, except that names are
/// escaped so characters such as `'` no longer break the build.
class LauncherName {
  LauncherName(this.projectDirectory);

  static const defaultLanguageKey = 'default';
  static const _androidResourcesPath = 'android/app/src/main/res';
  static const _androidManifestPath =
      'android/app/src/main/AndroidManifest.xml';
  static const _iosResourcesPath = 'ios/Runner/Resources';
  static const _iosInfoPlistPath = 'ios/Runner/Info.plist';

  final Directory projectDirectory;

  static Map<String, String> readNamesByLanguage(String pubspecSource) {
    final pubspec = loadYaml(pubspecSource);
    final launcherNames = pubspec is YamlMap ? pubspec['launcher_name'] : null;
    if (launcherNames is! YamlMap) {
      throw const FormatException('pubspec.yaml has no launcher_name map.');
    }

    final namesByLanguage = <String, String>{
      for (final MapEntry(:key, :value) in launcherNames.entries)
        '$key': '$value',
    };
    if (!namesByLanguage.containsKey(defaultLanguageKey)) {
      throw const FormatException('launcher_name needs a default entry.');
    }
    return namesByLanguage;
  }

  void apply(Map<String, String> namesByLanguage) {
    _applyAndroid(namesByLanguage);
    _applyIos(namesByLanguage);
  }

  void _applyAndroid(Map<String, String> namesByLanguage) {
    final resourcesDirectory = _directory(_androidResourcesPath);
    _deleteGeneratedLanguageDirectories(
      resourcesDirectory,
      directoryNamePattern: RegExp(r'^values-[a-z]{2,3}$'),
      generatedFileSuffix: 'strings.xml',
    );

    for (final MapEntry(key: language, value: name)
        in namesByLanguage.entries) {
      final languageDirectory = Directory(
        language == defaultLanguageKey
            ? '${resourcesDirectory.path}/values'
            : '${resourcesDirectory.path}/values-$language',
      )..createSync();
      File('${languageDirectory.path}/strings.xml').writeAsStringSync(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        '  <string name="appName">${escapeAndroidString(name)}</string>\n'
        '</resources>',
      );
    }

    final manifestFile = _file(_androidManifestPath);
    final manifestLines = manifestFile.readAsLinesSync().map(
          (line) => line.replaceAll(
            RegExp(r'android:label="[^"]*(\\"[^"]*)*"'),
            'android:label="@string/appName"',
          ),
        );
    manifestFile.writeAsStringSync('${manifestLines.join('\n')}\n');
  }

  void _applyIos(Map<String, String> namesByLanguage) {
    final resourcesDirectory = _directory(_iosResourcesPath)..createSync();
    _deleteGeneratedLanguageDirectories(
      resourcesDirectory,
      directoryNamePattern: RegExp(r'^[a-z]{2,3}\.lproj$'),
      generatedFileSuffix: 'InfoPlist.strings',
    );

    for (final MapEntry(key: language, value: name)
        in namesByLanguage.entries) {
      final languageDirectory = language == defaultLanguageKey
          ? resourcesDirectory
          : (Directory('${resourcesDirectory.path}/$language.lproj')
            ..createSync());
      File('${languageDirectory.path}/InfoPlist.strings').writeAsStringSync(
        '"CFBundleDisplayName" = "${escapeIosString(name)}";',
      );
    }

    final infoPlistFile = _file(_iosInfoPlistPath);
    final infoPlistLines = infoPlistFile.readAsLinesSync();
    for (var lineIndex = 0;
        lineIndex < infoPlistLines.length - 1;
        lineIndex++) {
      if (infoPlistLines[lineIndex].contains('CFBundleDisplayName')) {
        infoPlistLines[lineIndex + 1] = '\t<string>\${PRODUCT_NAME}</string>';
      }
    }
    infoPlistFile.writeAsStringSync(infoPlistLines.join('\n'));
  }

  /// Removes language directories this tool generated earlier, so languages
  /// dropped from `launcher_name` fall back to the default name. Directories
  /// holding anything else are left alone.
  void _deleteGeneratedLanguageDirectories(
    Directory resourcesDirectory, {
    required RegExp directoryNamePattern,
    required String generatedFileSuffix,
  }) {
    final generatedLanguageDirectories =
        resourcesDirectory.listSync().whereType<Directory>().where((directory) {
      final directoryName = directory.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .last;
      if (!directoryNamePattern.hasMatch(directoryName)) {
        return false;
      }
      final entries = directory.listSync();
      return entries.length == 1 &&
          entries.single.path.endsWith(generatedFileSuffix);
    }).toList();
    for (final directory in generatedLanguageDirectories) {
      directory.deleteSync(recursive: true);
    }
  }

  Directory _directory(String relativePath) =>
      Directory('${projectDirectory.path}/$relativePath');

  File _file(String relativePath) =>
      File('${projectDirectory.path}/$relativePath');

  /// Escapes [name] for an Android string resource, where `'`, `"`, `\`, `&`
  /// and `<` break aapt2 and a leading `@` or `?` reads as a reference.
  static String escapeAndroidString(String name) {
    final escapedName = name
        .replaceAll(r'\', r'\\')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('"', r'\"')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\n');
    return escapedName.startsWith('@') || escapedName.startsWith('?')
        ? '\\$escapedName'
        : escapedName;
  }

  /// Escapes [name] for a value in an iOS `.strings` file.
  static String escapeIosString(String name) => name
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n');
}
