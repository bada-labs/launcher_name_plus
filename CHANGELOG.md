# Changelog

## 1.0.3

First release of `launcher_name_plus`, a maintained successor of [`launcher_name`](https://pub.dev/packages/launcher_name) 1.0.2. Output is byte-for-byte identical to 1.0.2 for names without special characters.

* Escape `'`, `"`, `\`, `&`, `<` and a leading `@` or `?` in Android `strings.xml`, and `"` and `\` in iOS `InfoPlist.strings`. Names such as `Tom's App` no longer break the Android resource build.
* Write every file before exiting. 1.0.2 started some writes without awaiting them, so the iOS `Resources` folder could be listed before it existed.
* Exit with a non-zero code and a message when `pubspec.yaml`, the `launcher_name` section or its `default` entry is missing, instead of printing an error and exiting successfully.
* Depend only on Dart (`yaml`), not on the Flutter SDK.
