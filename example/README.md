# Example

Add the package and a `launcher_name` section to your app's `pubspec.yaml`:

```yaml
dev_dependencies:
  launcher_name_plus: ^1.0.3

launcher_name:
  default: "My App"
  ko: "내 앱"
  ja: "マイアプリ"
  fr: "L'application"
```

Then run it from the app root:

```sh
dart run launcher_name_plus:main
```

It writes:

- `android/app/src/main/res/values/strings.xml` and `values-<lang>/strings.xml`, and points `android:label` in `AndroidManifest.xml` to `@string/appName`.
- `ios/Runner/Resources/InfoPlist.strings` and `<lang>.lproj/InfoPlist.strings`, and sets `CFBundleDisplayName` in `Info.plist` to `${PRODUCT_NAME}`.

The French name above contains `'`, which `launcher_name` 1.0.2 wrote unescaped and broke the Android build. This package writes it as `L\'application`.
