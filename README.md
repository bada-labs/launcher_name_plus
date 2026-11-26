# launcher_name_plus

[![pub package](https://img.shields.io/pub/v/launcher_name_plus.svg)](https://pub.dev/packages/launcher_name_plus)
[![CI](https://github.com/bada-labs/launcher_name_plus/actions/workflows/ci.yaml/badge.svg)](https://github.com/bada-labs/launcher_name_plus/actions/workflows/ci.yaml)

Localize your Flutter app's launcher name (the name under the app icon) on Android and iOS from `pubspec.yaml`.

This is a maintained, drop-in successor of [`launcher_name`](https://pub.dev/packages/launcher_name), which has not been updated since 1.0.2 (2023). It uses the same `launcher_name` configuration and writes the same files. Bada Labs uses it to ship over 100 localized app flavors.

## What's different from `launcher_name` 1.0.2

- **Special characters work.** Names with `'`, `"`, `\`, `&`, `<` or a leading `@`/`?` are escaped. In 1.0.2 a name like `L'application` broke the Android resource build.
- **No race conditions.** Every file is written before the command exits.
- **Failures fail.** A missing `pubspec.yaml`, `launcher_name` section or `default` entry exits with a non-zero code, so CI and release scripts stop instead of shipping the wrong name.
- **Pure Dart.** No Flutter SDK dependency.

For names without special characters, the output is byte-for-byte identical to 1.0.2.

## Migrating from `launcher_name`

1. In `dev_dependencies`, replace `launcher_name` with `launcher_name_plus`.
2. Replace `dart run launcher_name:main` with `dart run launcher_name_plus:main`.

Your `launcher_name:` section stays as it is.

## Usage

### 1. Configure

```yaml
dev_dependencies:
  launcher_name_plus: ^1.0.3

launcher_name:
  default: "My App"   # required: used for languages without their own entry
  ko: "내 앱"
  ja: "マイアプリ"
  fr: "L'application"
```

Keys are language codes (two or three lowercase letters, see [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)).

### 2. Run

From your app root:

```sh
dart run launcher_name_plus:main
```

### What it writes

**Android**

- `android/app/src/main/res/values/strings.xml` with the default name, and `values-<lang>/strings.xml` for each language.
- `android:label` in `AndroidManifest.xml` becomes `@string/appName`.

**iOS**

- `ios/Runner/Resources/InfoPlist.strings` with the default name, and `<lang>.lproj/InfoPlist.strings` for each language.
- `CFBundleDisplayName` in `Info.plist` becomes `${PRODUCT_NAME}`, so the localized strings take over.
- Add the `ios/Runner/Resources` folder to the Runner target in Xcode once, so the `.lproj` folders are bundled.

**Removing a language**

When you drop a language from `launcher_name`, its generated folder is deleted on the next run. Only folders that hold nothing but the generated file are touched, so `values-night` or folders with your own resources are left alone.

## Scope

This package fixes bugs and keeps up with Dart, Flutter, Android and iOS changes. New features are considered conservatively to keep it small and dependable.

## Credits

Based on [`launcher_name`](https://pub.dev/packages/launcher_name) by OJ Creator, under the BSD 3-Clause license. Maintained by [Bada Labs](https://badalabs.com).
