# Contributing

Thanks for helping improve `scobro_flutter_photo_tools`.

## Reporting a bug or asking for a feature

Open an issue using the bug report or feature request template. For bugs,
include your Flutter version (`flutter --version`), the platform, and the
smallest code that shows the problem.

## Making a change

1. Fork the repo and create a branch from `main`.
2. Run `flutter pub get` in the root and in `example/`.
3. Make your change, with tests. Public APIs need dartdoc comments (the
   `public_member_api_docs` lint enforces it).
4. Check everything passes:

   ```sh
   dart format --output=none --set-exit-if-changed .
   flutter analyze --fatal-infos
   (cd example && flutter analyze --fatal-infos)
   flutter test --coverage --exclude-tags golden
   dart run tool/coverage_gate.dart --min 90
   (cd example && flutter test)
   ```

5. Add a line to `CHANGELOG.md` under a new "Unreleased" heading.
6. Open a pull request and fill in the template.

## Golden tests

Golden images are generated and compared on Linux with the fonts in
`test/fonts`, so they are skipped on Windows and macOS. If your change alters
how a widget looks, run the **Update goldens** workflow on your branch (or
`flutter test --tags golden --update-goldens` on Linux) and commit the new
images.

## Screenshots

`doc/screenshots` is written by a skipped test:

```sh
flutter test --tags screenshot --run-skipped --update-goldens
```

## Code style

- Follow the lints in `analysis_options.yaml` and `dart format`.
- Keep the package free of app-level dependencies (HTTP clients, state
  management, routers).
- Take colours from the `ColorScheme` and text from `PhotoToolsStrings`;
  never hard-code either in a widget.

By contributing you agree that your contributions are licensed under the MIT
License and that you'll follow the [code of conduct](CODE_OF_CONDUCT.md).
