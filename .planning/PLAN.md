# Implementation Plan — `scobro_flutter_photo_tools`

| Field | Value |
|-------|-------|
| Package location | `C:\repos\flutter_image_tools\src` (git repo root and package root) |
| Published name | `scobro_flutter_photo_tools` (D-1) |
| GitHub | `https://github.com/scottpaulbrown/scobro_flutter_photo_tools` (public, D-17) |
| Source app | `C:\repos\FamilyAssistant\app`, Phase 14 "Family pictures" (commits `6a3e5bb`, `a8e9ee5`; design plan `documentation/phase-14-family-pictures/flutter-design-plan.md`) |
| First version | 0.1.0 (D-16) |
| Status | **Planned — ready to build** |
| Last updated | 2026-10-25 |

This file lives in `.planning/`, which `.pubignore` excludes, so it is never published.

---

## 1. Goal

Take the photo picking, framing (crop / rotate / zoom), rendering, validation and upload-handoff code that FamilyAssistant built in Phase 14, and turn it into a general-purpose Flutter package that:

- any Flutter app can use, whatever its state management, HTTP stack, router or design system;
- meets everything pub.dev needs to publish it, and aims for the full 160 pana points;
- is structured, tested and documented like a professional open-source package.

**Out of scope:** moving FamilyAssistant onto the package (D-5, separate plan); free-form crop, upload progress, drag-drop/paste, flip/straighten (later versions, §11).

## 2. What exists today (source inventory)

All paths are under `app/lib/features/household/` unless noted.

| Piece | Source file(s) | Coupling to remove | Becomes |
|-------|----------------|--------------------|---------|
| Framing model + geometry | `models/photo_framing.dart` (`PhotoFraming`, `PhotoFramingGeometry.cropRect/rotatedSize`) | None (pure Dart + `dart:ui`) | `PhotoFraming`, `FramingGeometry`, generalised from a square to any aspect ratio (D-3) |
| Renderer | `services/member_photo_renderer.dart` (`package:image` in `compute`: decode → `bakeOrientation` → rotate → crop → resize 512² → flatten on white → JPEG q88) | Fixed size, format, quality and background | `PhotoRenderer` + `RenderOptions` |
| Validator | `services/member_photo_validator.dart` (magic bytes JPEG/PNG/WebP, 5 MB) | Fixed limit, English messages copied from the server | `ImageValidator` + `ValidationRules`, returns typed `ImageValidationError` |
| Picker | `services/member_photo_picker.dart` (sealed `MemberPhotoPick`, `PluginMemberPhotoPicker` on `file_picker` + `image_picker`, a fake, a Riverpod provider) | Riverpod provider, "Member" naming | `PhotoSourcePicker` (interface), `PluginPhotoSourcePicker`, `FakePhotoSourcePicker` (in `testing.dart`) |
| Framing state | `view-models/member_photo_framing.dart` (`MemberPhotoFramingNotifier`) | Riverpod codegen | `PhotoEditorController` (`ChangeNotifier`) |
| Framing screen | `screens/member_photo_framing_screen.dart` (607 lines: `_Stage`, `_StagePainter`, `paintFramedImage`, `FramedPhoto`, `_ZoomRow`, preview strip, discard prompt) | go_router, `PrimaryScaffold`, `ActionBand`, `AppRadius`, `AppFonts`, `HouseholdMemberAvatar`, English strings | `PhotoEditor` (widget), `PhotoEditorPage`, `showPhotoEditor()`, `FramedImage`, `paintFramedImage` |
| Source sheet | `widgets/member_photo_actions_sheet.dart` (`MemberPhotoAction {device, camera, google, remove}`) | Riverpod, `showAdaptiveSheet`, "Google picture" | `showPhotoSourceSheet()` with `CustomPhotoSource`s and an optional Remove row |
| Change-photo avatar | `widgets/member_photo_change_avatar.dart` | None (Material only) | `ChangePhotoBadge` |
| Member avatar | `widgets/household_member_badge.dart` (`HouseholdMemberAvatar`) | `HouseholdMemberSummary`, `colorFromMemberColorId`, Riverpod bytes provider | `PhotoAvatar` |
| Bytes cache | `view-models/member_photo_bytes.dart` (keepAlive family on `(id, photoVersion)`) | Riverpod, household client | `VersionedImageLoader` + `VersionedMemoryImage` |
| Flow | `widgets/member_photo_flow.dart` (`changeSavedMemberPhoto`, `chooseStagedMemberPhoto`) | Auth, household notifier, go_router, snack bars | `PhotoFlow.run()` (upload or staged) |
| Upload / download | `commands/set_household_member_photo.dart`, `queries/get_household_member_photo.dart`, `clients/household_client.dart`, `app/lib/core/http/web_request_service.dart` | The app's whole HTTP stack | **Not extracted.** Apps pass callbacks (D-2). README shows Dio / `http` / Firebase Storage examples. |
| Tests | `app/test/features/household/{models,services,view-models,screens,widgets}/…photo…`, `app/test/helpers/test_images.dart` | Riverpod harness | Ported (§8) |

Known issues to fix while extracting:

- **EXIF on the preview path.** The renderer calls `bakeOrientation`, but the on-screen stage decodes with `ui.instantiateImageCodec` and never does. Flutter's codec probably respects EXIF, but nothing tests it. **Add a fixture JPEG with orientation 6 and a test proving preview geometry and rendered output agree**; if they don't, the controller decodes the `ui.Image` from the orientation-baked bytes.
- **HEIC.** iOS gallery picks may be HEIC and are refused today (fixed by D-12).
- **Huge camera shots.** `pickImage` is called without `maxWidth`, so 48 MP photos are decoded at full size twice. The picker now passes `maxWidth/maxHeight` (default 4096, `PickerOptions.maxDimension`).
- **Web has no isolates.** `compute` runs on the main thread on web, so a large render can stall a frame or two. Document it; the pre-downscale above keeps it small.

## 3. Decisions

| ID | Decision | Answer | Effect |
|----|----------|--------|--------|
| D-1 | Package name | **`scobro_flutter_photo_tools`** (free on pub.dev as of 2026-10-25; `flutter_image_tools` is taken). Folder stays `flutter_image_tools`. | Library `lib/scobro_flutter_photo_tools.dart`; test helpers in `lib/testing.dart`. |
| D-2 | Upload scope | **Callback only.** The package produces the final bytes and calls an app-supplied `Future<T> Function(EditedImage)`; it shows busy and error states but has no HTTP dependency. | No `dio`/`http` dependency. `errorMessage: String Function(Object error)?` lets the app turn its own exceptions into text. |
| D-3 | Crop shapes | **Any fixed aspect ratio** (`aspectRatio`, default 1.0) **plus a guide shape** (`circle`, `roundedRect`, `rect`). No free-form crop in v1. | Geometry finds "the largest rect of the ratio" instead of "the largest square". A `circle` guide at a ratio other than 1:1 draws an oval (asserted and documented). Output size = `outputLongEdge` (default 1024) with the short edge from the ratio. |
| D-4 | State management | **None.** Plain `ChangeNotifier` controller. | No Riverpod and no `build_runner`. |
| D-5 | Migrate FamilyAssistant | **Separate plan later.** | The app's code is untouched (§11). |
| D-6 | License | **MIT** | `LICENSE` at the root. |
| D-7 | Hosting and CI | **Public GitHub + GitHub Actions**, with tag-triggered OIDC publishing. | §7, §9. |
| D-8 | Strings | **Overridable `PhotoToolsStrings`** with English defaults. | Set once through `PhotoToolsScope`, or per widget. Typed errors become text through `strings.validationMessage(error)`. |
| D-9 | Repo layout | **`src` is the git root and the package root.** | §6. |
| D-10 | Platforms | **All six:** Android, iOS, web, Windows, macOS, Linux. | Camera on Android, iOS and web; desktop shows device files only. |
| D-11 | Output formats | **JPEG (default) and PNG.** | `OutputFormat.jpeg(quality: 88, background: 0xFFFFFFFF)` / `OutputFormat.png()`. |
| D-12 | HEIC | **`image_picker` gallery on Android/iOS** (returns JPEG); `file_picker` on web and desktop. | The validator still refuses HEIC elsewhere with `unsupportedFormat`. |
| D-13 | Editor presentation | **Embeddable `PhotoEditor` + `PhotoEditorPage` + `showPhotoEditor()`** (a plain `MaterialPageRoute`, not a full-screen dialog). | Router-agnostic; go_router apps can host `PhotoEditorPage` in their own route. |
| D-14 | Display widgets | **`ChangePhotoBadge`, `PhotoAvatar`, `PhotoPreviewStrip`, `VersionedImageLoader`.** | §5.6–§5.7. |
| D-15 | v1 extras | **Custom sources + Remove** only. | `CustomPhotoSource` rows; opt-in Remove with confirmation. |
| D-16 | First version | **0.1.0**; move to 1.0.0 once two apps use it. | `CHANGELOG.md` starts at 0.1.0. |
| D-17 | GitHub repo | **`scottpaulbrown/scobro_flutter_photo_tools`** | `homepage`, `repository`, `issue_tracker` in `pubspec.yaml`. |
| D-18 | Publisher | **Personal Google account** (no verified publisher), like the foundation packages. | No domain setup. pana does not score publisher verification, so no points are lost. |
| D-19 | Minimum SDK | **The lowest the dependencies allow, proven by a `pub downgrade` CI job.** | Floor: `file_picker 11.0.0` (Dart ≥3.4, Flutter ≥3.22), `image_picker 1.2.0` (Dart ^3.6, Flutter ≥3.27), `image 4.5.0` (Dart ≥3.2). So **`sdk: ^3.6.0`, `flutter: ">=3.27.0"`**, with wide upper bounds so newer apps get newer plugins (`file_picker: ">=11.0.0 <14.0.0"` *if* its API is the same across 11–13; check during P2, otherwise `^11.0.0`). |
| D-20 | Testing beyond unit/widget | **Goldens + coverage gate + example integration test.** | §8. |

Defaults chosen without asking (they follow convention or the user's earlier answers):

- **Governing guidance.** FamilyAssistant's `command-writing`, `query-writing`, `model-writing` and `view-model-writing` skills describe the app's HTTP and Riverpod layers. The package has neither (D-2, D-4), so they don't apply. **`frontend-design` governs every widget** in §5.4–§5.6. Its rules applied here: no full-screen dialogs (the editor is a real page), a source sheet that adapts (bottom sheet under 650 px, a 480 px dialog above), content constrained on wide screens, and quiet visual grouping.
- **Theming.** Nothing is hard-coded: colours come from `ColorScheme`, text from `TextTheme`, and no fonts are bundled. An optional `PhotoToolsTheme` `ThemeExtension` overrides stage scrim, guide colour, stage radius and badge colours.
- **Lints.** `flutter_lints` plus stricter rules: `public_member_api_docs`, `prefer_final_locals`, `always_declare_return_types`, `avoid_print`, `unawaited_futures`, `require_trailing_commas` off. `strict-casts`, `strict-inference` and `strict-raw-types` on.
- **Default validation:** JPEG/PNG/WebP, `maxBytes: null` (no limit). FamilyAssistant would pass 5 MB.

## 4. Package architecture

Five layers. Each one depends only on the layers above it in this list.

```
core      (pure Dart + dart:ui, no widgets)  framing, geometry, validation, rendering, EditedImage
picking   (plugins)                          PhotoSourcePicker, file_picker / image_picker
theme     (inherited config)                 PhotoToolsScope, PhotoToolsStrings, PhotoToolsTheme
editor    (controller + widgets)             PhotoEditorController, PhotoEditor, PhotoEditorPage
flow/ui   (composition)                      source sheet, PhotoFlow, ChangePhotoBadge, PhotoAvatar,
                                             PhotoPreviewStrip, VersionedImageLoader
```

- **`core` has no Flutter widget dependency.** It can be unit-tested fast and used headless (e.g. to re-crop server-side thumbnails in a Flutter tool).
- **Everything a plugin touches sits behind `PhotoSourcePicker`.** Widget tests and app tests never hit a plugin; `testing.dart` ships the fake.
- **One public library plus one testing library.** `lib/scobro_flutter_photo_tools.dart` exports the public API with explicit `show` lists; `lib/testing.dart` exports the fakes and test-image builders. Everything else is in `lib/src/` and private.

## 5. Public API sketch

Signatures are indicative; exact names are settled in the build, and any change is recorded in §12.

### 5.1 Core

```dart
enum ImageFormat { jpeg, png, webp }                     // sniffed from magic bytes
ImageFormat? detectImageFormat(Uint8List bytes);

sealed class ImageValidationError { }                    // empty, unsupportedFormat(ImageFormat? found), tooLarge(int bytes, int max)
class ValidationRules { const ValidationRules({this.allowedFormats = ImageFormat.values, this.maxBytes}); }
abstract final class ImageValidator { static ImageValidationError? check(Uint8List bytes, [ValidationRules rules]); }

@immutable class PhotoFraming {                          // quarterTurns 0–3, zoom 1..maxZoom, offsetX/Y −1..1
  const PhotoFraming({this.quarterTurns = 0, this.zoom = 1, this.offsetX = 0, this.offsetY = 0});
  PhotoFraming copyWith(...); PhotoFraming rotatedClockwise(); // ==, hashCode
}
abstract final class FramingGeometry {
  static Size rotatedSize(Size source, int quarterTurns);
  static Rect cropRect(Size source, PhotoFraming framing, {required double aspectRatio, double maxZoom = 4});
}

sealed class OutputFormat { const factory OutputFormat.jpeg({int quality, int background}); const factory OutputFormat.png(); }
class RenderOptions { const RenderOptions({this.aspectRatio = 1, this.outputLongEdge = 1024, this.format = const OutputFormat.jpeg(), this.maxZoom = 4}); }

class PhotoRenderer {                                    // package:image inside compute()
  const PhotoRenderer();
  Future<Size> sizeOf(Uint8List source);                 // after EXIF orientation
  Future<EditedImage> render(Uint8List source, PhotoFraming framing, RenderOptions options);
}

@immutable class EditedImage {                           // what every API hands back
  final Uint8List bytes; final int width, height; final ImageFormat format;
  final PhotoFraming framing; String get mimeType; String get fileExtension; String suggestedFileName([String stem = 'photo']);
}
```

### 5.2 Picking

```dart
sealed class PickResult { }                              // Picked(PickedImage), PickCancelled(), PickRefused(ImageValidationError), CameraDenied()
class PickedImage { final String name; final Uint8List bytes; final ImageFormat format; }
class PickerOptions { const PickerOptions({this.maxDimension = 4096, this.validation = const ValidationRules()}); }

abstract interface class PhotoSourcePicker {
  bool get canTakePhoto;                                 // false on Windows/macOS/Linux apps
  Future<PickResult> pickFromDevice([PickerOptions options]);
  Future<PickResult> takePhoto([PickerOptions options]);
}
class PluginPhotoSourcePicker implements PhotoSourcePicker { const PluginPhotoSourcePicker(); }
  // Android/iOS device → image_picker gallery (JPEG, requestFullMetadata: false, maxWidth/Height)
  // web/desktop device → file_picker (FileType.image, withData: true)
  // camera → image_picker; PlatformException 'camera_access_denied' → CameraDenied
// testing.dart: class FakePhotoSourcePicker implements PhotoSourcePicker { devicePick, cameraPick, call counts }
```

### 5.3 Theme, strings, scope

```dart
class PhotoToolsStrings {                                // every user-visible string; English defaults
  const PhotoToolsStrings({this.editorTitle = 'Frame photo', this.save = 'Save photo', this.cancel = 'Cancel',
    this.rotate = 'Rotate', this.discardTitle = 'Discard this photo?', ..., this.cameraDenied = '…'});
  String validationMessage(ImageValidationError e);     // overridable
  PhotoToolsStrings copyWith(...);
}
class PhotoToolsTheme extends ThemeExtension<PhotoToolsTheme> { stageScrim, guideColor, stageRadius, badgeBackground, badgeForeground, ... }
class PhotoToolsScope extends InheritedWidget {          // optional; set once above MaterialApp's home
  const PhotoToolsScope({this.strings, this.picker, this.renderer, this.loader, required super.child});
  static PhotoToolsScopeData of(BuildContext context);   // falls back to defaults when absent
}
```

### 5.4 Editor

```dart
class PhotoEditorController extends ChangeNotifier {
  PhotoEditorController({this.options = const RenderOptions(), PhotoRenderer? renderer});
  Future<void> load(Uint8List source);                   // status: loading → ready | failed
  PhotoEditorStatus get status; PhotoFraming get framing; ui.Image? get image; bool get isEdited; String? get error;
  void rotateClockwise(); void setZoom(double zoom); void panBy(Offset stageFraction); void reset();
  Future<EditedImage?> render();                          // status: rendering
}

class PhotoEditor extends StatefulWidget {               // stage + zoom/rotate row + optional preview strip
  const PhotoEditor({required this.controller, this.guideShape = CropGuideShape.circle,
    this.previews = const [], this.strings});            // previews: List<PhotoPreviewSpec(size, caption, builder?)>
}
class PhotoEditorPage extends StatefulWidget {           // scaffold, close button, title, PopScope discard prompt, Cancel / Save action bar
  const PhotoEditorPage({required this.source, this.options, this.guideShape, this.title, this.previews, this.strings});
}
Future<EditedImage?> showPhotoEditor(BuildContext context, {required Uint8List source, ...}); // Navigator.push(MaterialPageRoute)

class FramedImage extends StatelessWidget { const FramedImage({required this.image, required this.framing, required this.aspectRatio}); }
void paintFramedImage(Canvas canvas, ui.Image image, PhotoFraming framing, Rect target, {required double aspectRatio});
enum CropGuideShape { circle, roundedRect, rect }
```

Editor UX carried over from FamilyAssistant (DD-1.1, IA-13, IA-14): drag pans; pinch and the mouse wheel zoom; the picture can never leave the crop box; one Rotate button turns it clockwise. Loading shows a spinner in the stage. An unreadable picture shows "Choose another", and a failed render shows "Try again". When the framing has changed, leaving asks before discarding. Layout: full width under 650 px; a centred 560 px column at 650–1099 px; at 1100 px and up, the stage sits on the left with controls and previews in a column on the right.

### 5.5 Source sheet and flow

```dart
class CustomPhotoSource { const CustomPhotoSource({required this.id, required this.icon, required this.label, required this.load}); final Future<Uint8List?> Function() load; }
sealed class PhotoSourceChoice { }                       // device, camera, custom(CustomPhotoSource), remove
Future<PhotoSourceChoice?> showPhotoSourceSheet(BuildContext context, {String? title, bool allowCamera = true,
  List<CustomPhotoSource> customSources = const [], bool showRemove = false, String? removeConfirmName});

sealed class PhotoFlowResult<T> { }                      // PhotoSaved<T>(EditedImage image, T? uploadResult), PhotoRemoved, PhotoCancelled, PhotoFailed(String message, Object? error)
abstract final class PhotoFlow {
  static Future<PhotoFlowResult<T>> run<T>(BuildContext context, {
    RenderOptions options, CropGuideShape guideShape, PickerOptions pickerOptions,
    List<CustomPhotoSource> customSources, Future<void> Function()? onRemove,
    Future<T> Function(EditedImage image)? upload,       // null → "staged" mode: returns the image, uploads nothing
    void Function(bool busy)? onBusy, String Function(Object error)? errorMessage,
    String? sheetTitle, String? editorTitle, List<PhotoPreviewSpec> previews});
}
```

`run` covers both of FamilyAssistant's flows: `changeSavedMemberPhoto` (upload set) and `chooseStagedMemberPhoto` (upload null). It never shows snack bars itself. It returns `PhotoFailed`, and the caller decides how to show it (IA-11: a snack bar can hide behind a sheet).

### 5.6 Display widgets

```dart
class ChangePhotoBadge extends StatelessWidget {         // camera badge bottom-right, Semantics button, busy ring
  const ChangePhotoBadge({required this.child, required this.size, required this.onTap, this.enabled = true, this.busy = false, this.semanticLabel});
}
class PhotoAvatar extends StatelessWidget {              // circle; photo or initials; optional ring; 150 ms fade
  const PhotoAvatar({required this.name, required this.size, this.color, this.ringColor, this.ringWidth,
    this.image, this.photoChild, this.photoId, this.photoVersion, this.loader, this.semanticLabel});
  static String initialsFor(String name);
}
class PhotoPreviewSpec { const PhotoPreviewSpec({required this.size, this.caption}); }
class PhotoPreviewStrip extends StatelessWidget { const PhotoPreviewStrip({required this.specs, required this.builder, this.title}); }
```

### 5.7 Versioned image loader

```dart
typedef PhotoBytesFetcher = Future<Uint8List?> Function(String id, String version);
class VersionedImageLoader {
  VersionedImageLoader({required this.fetch, this.maxEntries = 100});
  Future<Uint8List?> load(String id, String version);    // LRU cache + de-duplicates in-flight requests; a new version is a new key
  void evict(String id); void clear();
}
class VersionedMemoryImage extends ImageProvider<VersionedMemoryImage> { const VersionedMemoryImage(this.loader, this.id, this.version); }
```

This is for photos behind cookie or token auth, which `Image.network` can't send on Android/iOS (FamilyAssistant design note §1.3). Null bytes (404 / failure) make `PhotoAvatar` show initials.

## 6. Repository layout

```
src/                                   ← git root = package root (D-9)
├─ .github/
│  ├─ workflows/ci.yml                 format, analyze, test+coverage, goldens, downgrade, pana, dry-run, example builds
│  ├─ workflows/integration.yml        example integration test (web + Linux)
│  ├─ workflows/publish.yml            on tag v*: OIDC publish to pub.dev
│  ├─ workflows/update-goldens.yml     workflow_dispatch: regenerate goldens on Linux, upload as artifact / PR
│  ├─ ISSUE_TEMPLATE/{bug_report.yml,feature_request.yml}
│  ├─ PULL_REQUEST_TEMPLATE.md
│  └─ dependabot.yml                   pub + github-actions
├─ .planning/PLAN.md                   this file (pubignored)
├─ doc/
│  ├─ platform-setup.md                iOS plist keys, macOS entitlement, web notes
│  ├─ upload-recipes.md                Dio, http, Firebase Storage, presigned URL callbacks
│  └─ screenshots/                     editor, sheet, avatars (light + dark), referenced from pubspec `screenshots:`
├─ example/                            `flutter create` for all 6 platforms
│  ├─ lib/main.dart                    gallery: avatar flow (upload to a fake server), 16:9 banner (staged), loader demo
│  ├─ integration_test/photo_flow_test.dart
│  └─ pubspec.yaml                     path: ../
├─ lib/
│  ├─ scobro_flutter_photo_tools.dart  public exports (explicit `show`)
│  ├─ testing.dart                     FakePhotoSourcePicker, TestImages
│  └─ src/
│     ├─ core/        image_format.dart, image_validator.dart, photo_framing.dart, framing_geometry.dart,
│     │               render_options.dart, photo_renderer.dart, edited_image.dart
│     ├─ picking/     photo_source_picker.dart, plugin_photo_source_picker.dart, pick_result.dart, picker_options.dart
│     ├─ theme/       photo_tools_scope.dart, photo_tools_strings.dart, photo_tools_theme.dart
│     ├─ editor/      photo_editor_controller.dart, photo_editor.dart, photo_editor_page.dart, framed_image.dart,
│     │               stage_painter.dart, crop_guide_shape.dart, zoom_rotate_bar.dart
│     ├─ sources/     photo_source_sheet.dart, custom_photo_source.dart, adaptive_sheet.dart
│     ├─ flow/        photo_flow.dart, photo_flow_result.dart
│     ├─ widgets/     change_photo_badge.dart, photo_avatar.dart, photo_preview_strip.dart
│     └─ loading/     versioned_image_loader.dart, versioned_memory_image.dart
├─ test/                               mirrors lib/src/; goldens under test/goldens/; fixtures under test/fixtures/
│  ├─ flutter_test_config.dart         loads a bundled test font so goldens are stable
│  └─ fixtures/exif_orientation_6.jpg
├─ tool/coverage_gate.dart             fails under the threshold (pubignored)
├─ .pubignore   .gitignore   analysis_options.yaml   dart_test.yaml (golden tag)
├─ CHANGELOG.md   CONTRIBUTING.md   CODE_OF_CONDUCT.md   SECURITY.md   LICENSE (MIT)
├─ README.md
└─ pubspec.yaml
```

## 7. pub.dev readiness checklist

**pubspec.yaml**

- `name: scobro_flutter_photo_tools`, `version: 0.1.0`
- `description:` 60–180 characters. For example: "Pick, crop, rotate and zoom photos to any aspect ratio, then hand the result to your own uploader. Themeable editor, avatars and caching."
- `homepage`, `repository`, `issue_tracker` → the GitHub repo (D-17); `documentation:` is omitted (pub.dev hosts the dartdoc).
- `topics:` (max 5) `image`, `crop`, `avatar`, `image-picker`, `photo`
- `platforms:` android, ios, web, windows, macos, linux
- `screenshots:` 3–4 entries from `doc/screenshots/` (PNG/WebP, under 4 MB each)
- `environment: sdk: ^3.6.0, flutter: ">=3.27.0"` (D-19)
- `dependencies:` `flutter`, `file_picker`, `image_picker`, `image` (no `dio`, `http`, Riverpod or go_router)
- `dev_dependencies:` `flutter_test`, `flutter_lints`

**Files and content**

- `LICENSE` (MIT, "Copyright (c) 2026 Scott Brown")
- `README.md`:
  - badges (pub version, CI, coverage, license)
  - one-paragraph pitch and screenshots
  - features list and platform table
  - install, plus per-platform setup (iOS plist keys, macOS entitlement)
  - 30-second quick start (`PhotoFlow.run` with an upload callback)
  - recipes: staged mode, custom 16:9 banner, custom source, versioned loader, theming, strings/l10n, testing with `FakePhotoSourcePicker`
  - limitations (web main-thread rendering, no HEIC outside mobile gallery)
  - contributing
- `CHANGELOG.md` with a `## 0.1.0` entry
- `example/` with a runnable `lib/main.dart` (pana awards points for an example)
- Dartdoc on 100% of the public API (`public_member_api_docs` lint enforces it); library-level doc comment with a code sample
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, issue and PR templates (GitHub community health; not scored by pana, but expected)

**Checks before publishing (all in CI)**

- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze --fatal-infos` (package and example)
- `flutter test --coverage` plus a coverage gate
- `pana --exit-code-threshold 0` (any lost point fails the build: conventions, docs, platforms, analysis, up-to-date deps, WASM-ready web)
- `flutter pub publish --dry-run` (0 warnings)
- `flutter pub downgrade && flutter analyze && flutter test` (proves the lower bounds, D-19)

**Publishing**

1. **The first release (0.1.0) is published by hand** from your machine: `flutter pub publish`, signed in with your Google account. pub.dev requires a package to exist before automated publishing can be turned on.
2. On pub.dev → package Admin → Automated publishing: enable GitHub Actions for `scottpaulbrown/scobro_flutter_photo_tools`, tag pattern `v{{version}}`, and require the `pub.dev` GitHub environment.
3. From then on: bump `version` + `CHANGELOG.md`, merge, push tag `vX.Y.Z` → `publish.yml` publishes through OIDC (no stored secrets).

## 8. Testing strategy

| Layer | Tests | Ported from FamilyAssistant |
|-------|-------|-----------------------------|
| core | Format sniffing (JPEG/PNG/WebP/HEIC/PDF/empty). Size limit edges (max accepted, max+1 refused, null means no limit). `cropRect` for landscape, portrait, 1:1, 4:3, 16:9 and 9:16, at zoom 1 and max, offsets clamped, rotation swapping axes, four turns restoring the original. Renderer: output dimensions per ratio, zoom keeps less area, each quarter turn moves a marker corner, the combined case matches the geometry, JPEG flattens alpha onto the background, PNG keeps alpha, the EXIF-6 fixture renders upright. | `photo_framing_test`, `member_photo_renderer_test`, `member_photo_validator_test`, `test_images.dart` |
| picking | Plugin picker through mocked platform channels / plugin platform interfaces: cancel, refused, camera denied, mobile-vs-desktop branch, `maxDimension` passed through. `FakePhotoSourcePicker` call counting. | `member_photo_picker_test` |
| editor | Controller: default framing, rotate ×4, zoom and pan clamped, `isEdited`, render success and failure, a failed load. Widget: drag pans, slider zooms, Rotate turns, wheel zooms, Save returns an `EditedImage`, Cancel/back return null, the discard prompt only after edits, error cards, three breakpoints laid out. | `member_photo_framing_test`, `member_photo_framing_screen_test` |
| sources / flow | The sheet's rows depend on `allowCamera`, custom sources and `showRemove`; Remove confirms first; bottom sheet under 650 px, dialog above. Flow: device → edit → upload returns `PhotoSaved` with the upload result; staged mode returns the image with no upload; cancel at each step; an upload throw gives `PhotoFailed` with the `errorMessage` text; a refused file and camera denied give `PhotoFailed` with the strings' text; `onBusy` toggles. | `member_photo_actions_sheet_test`, `member_editor_sheet_photo_test` |
| widgets / loading | Avatar: initials on colour, neutral without colour, photo clipped to a circle, fade, loader-backed photo, null bytes keep initials. Badge: semantics, busy ring, disabled. Loader: one fetch per `(id, version)`, a new version refetches, concurrent calls share one future, LRU eviction, `evict`. | `household_member_avatar_test`, `member_photo_bytes_test`, `own_photo_badge_test` |
| **Goldens** (D-20) | Editor (mobile + desktop width), source sheet, avatar sizes, badge busy state, each in light and dark themes and with a custom `PhotoToolsTheme`. Tagged `golden`, run on `ubuntu-latest` only. They use a bundled test font (`flutter_test_config.dart`), so Windows runs skip them. `update-goldens.yml` regenerates them on Linux. | New |
| **Coverage gate** (D-20) | `tool/coverage_gate.dart` reads `coverage/lcov.info` (generated `.g.dart` excluded) and fails under **90% of `lib/`**. Coverage is uploaded to Codecov for the README badge. | New |
| **Integration** (D-20) | `example/integration_test/photo_flow_test.dart`: the example app is started with `FakePhotoSourcePicker` (through `PhotoToolsScope`), then picks → zooms → rotates → saves → asserts the fake upload received a correctly sized JPEG; then staged mode; then cancel. Runs on Chrome (`flutter drive -d web-server` + chromedriver) and Linux (`xvfb-run flutter test integration_test -d linux`) in `integration.yml`. | New |

## 9. CI design (`.github/workflows`)

- **ci.yml** (push + PR to `main`):
  - `analyze-test` job on `ubuntu-latest`, matrix with Flutter `stable` and `3.27.x`: `pub get` → format → analyze (package + example) → `flutter test --coverage --exclude-tags golden` → coverage gate → Codecov.
  - `goldens` job: `flutter test --tags golden`; failure diffs uploaded as an artifact.
  - `downgrade` job: `flutter pub downgrade` → analyze → test.
  - `pana` job: `dart pub global activate pana` → `pana --exit-code-threshold 0 --no-warning`.
  - `publish-dry-run` job.
  - `example-builds` matrix: `flutter build web` (Ubuntu), `flutter build linux` (Ubuntu), `flutter build apk --debug` (Ubuntu), `flutter build windows` (Windows), `flutter build macos` + `flutter build ios --no-codesign` (macOS).
- **integration.yml** (push to `main` + nightly): web and Linux integration tests (§8).
- **publish.yml** (tag `v*`): `environment: pub.dev`, `permissions: id-token: write`. Steps: `dart-lang/setup-dart` (for the OIDC token), `subosito/flutter-action`, `flutter pub get`, `flutter pub publish --force`.
- **dependabot.yml**: weekly for `pub` (root and `example/`) and `github-actions`.

## 10. Build order

Each phase ends with format, analyze and tests green.

| Phase | Work | Done when |
|-------|------|-----------|
| P0 Scaffold | `flutter create --template=package --project-name scobro_flutter_photo_tools .` in `src`; `git init -b main`; LICENSE, `.gitignore`, `.pubignore`, `analysis_options.yaml`, `dart_test.yaml`, empty README/CHANGELOG; `flutter create --platforms=android,ios,web,windows,macos,linux example`; create the public GitHub repo and push | `flutter analyze` clean on an empty library; repo on GitHub |
| P1 Core | `image_format`, `image_validator`, `photo_framing`, `framing_geometry` (aspect ratio), `render_options`, `photo_renderer`, `edited_image`; port and extend tests; EXIF-6 fixture test | Core tests green, 100% coverage of `core/` |
| P2 Picking | `PhotoSourcePicker`, `PluginPhotoSourcePicker` (mobile = `image_picker` gallery, web/desktop = `file_picker`), `PickerOptions`, `FakePhotoSourcePicker`; settle the `file_picker` upper bound (D-19) | Picker tests green; example picks on web and Windows by hand |
| P3 Theme & strings | `PhotoToolsStrings`, `PhotoToolsTheme`, `PhotoToolsScope` | Widgets later in the build can read defaults with no scope present |
| P4 Editor | `PhotoEditorController`, stage painter (guide shapes, aspect ratio), `PhotoEditor`, `PhotoEditorPage`, `showPhotoEditor`, `FramedImage`; responsive layouts; goldens | Editor tests and goldens green; preview matches renderer output (TC-021 equivalent) |
| P5 Sources & flow | `showPhotoSourceSheet` (adaptive), `CustomPhotoSource`, Remove confirmation, `PhotoFlow.run` (upload + staged) | Flow tests green |
| P6 Display & loading | `ChangePhotoBadge`, `PhotoAvatar`, `PhotoPreviewStrip` (wired into the editor), `VersionedImageLoader`, `VersionedMemoryImage` | Widget, loader and golden tests green |
| P7 Example | Gallery app with three demos and a fake upload server (delay, random failure toggle); integration test | Integration test green on web and Linux |
| P8 Docs | README, `doc/platform-setup.md`, `doc/upload-recipes.md`, dartdoc pass, screenshots, CHANGELOG, community files | `dart doc` with no warnings; pana 160/160 locally |
| P9 CI & release | All workflows; branch protection on `main` (CI required); manual `flutter pub publish` of 0.1.0; enable OIDC publishing; tag `v0.1.0` | 0.1.0 live on pub.dev; tag-publish path tested with 0.1.1 (or kept for the next real change) |

## 11. Follow-ups (out of this plan)

- **Move FamilyAssistant onto the package** (D-5). Separate plan: replace `member_photo_*` services, framing screen, actions sheet, change avatar and bytes provider with the package. Keep the app's household client and commands as the upload/fetch callbacks, the 5 MB `ValidationRules`, "Use Google picture" as a `CustomPhotoSource`, and `PhotoAvatar` inside `HouseholdMemberAvatar`. Re-run the TC-001–TC-033 tests.
- **Later package versions** (D-15): upload progress (`ProgressReporter` passed to the upload callback, determinate ring on the badge), drag-drop and paste on web/desktop, horizontal flip and ±45° straighten, free-form crop.
- **Move to 1.0.0** once a second app uses the package (D-16).

## 12. Open questions

- None blocking. Two are checked during the build and recorded here:
  - **P2:** is `file_picker`'s pick API the same across 11.x–13.x, so the upper bound can be `<14.0.0`?
  - **P1:** does `ui.instantiateImageCodec` respect EXIF orientation on every platform? If not, the controller decodes from orientation-baked bytes.

---

## Implementation Progress

Tracked by the implementing run (`sb-flutter-implement-plan`). One entry per build phase in §10.

### P0 Scaffold
**Implementation Status:** Complete

### P1 Core
**Implementation Status:** Complete

### P2 Picking
**Implementation Status:** Complete

### P3 Theme & strings
**Implementation Status:** Complete

### P4 Editor
**Implementation Status:** Complete

### P5 Sources & flow
**Implementation Status:** Complete

### P6 Display & loading
**Implementation Status:** Complete

### P7 Example
**Implementation Status:** Complete

### P8 Docs
**Implementation Status:** Complete
**Implementation Notes:** `dart doc` reports 0 warnings, `flutter pub publish --dry-run` 0 warnings, analysis clean with `--fatal-infos`. The "pana 160/160 locally" target was **not** reached: local pana 0.23.12 scored 130/160. Lost: (a) documentation 0/20, because pana's bundled dartdoc 9.0.5 crashed inside `_stripDocImports` while precaching the whole SDK + dependency graph, and the screenshot check needs the WebP tools (`cwebp`, `webpinfo`), which aren't installed here; both look environmental, since the SDK's `dart doc` succeeds. (b) Platform support 10/20: not WASM-compatible, because `file_picker` 11.x's web implementation imports `dart:io` (fixed upstream in 12.1.2). On pub.dev, `file_picker: ^11.0.0` will probably also lose 10 of the "up-to-date dependencies" points, since 13.2.0 is outside the range (it passed locally only because this SDK can't resolve 13.x). Getting those 20 points back needs a change to D-12/D-19: either raise the floor to Flutter 3.38 and move to `file_picker ^13`, or drop `file_picker` and use `image_picker` on web/desktop too. That is for the user to decide.

### P9 CI & release
**Implementation Status:** Complete
**Implementation Notes:** All workflow, template and Dependabot files are written and parse as valid YAML. These release steps were **not** done, because they are external or irreversible and belong to the user: creating and pushing the GitHub repo, branch protection on `main`, the manual `flutter pub publish` of 0.1.0, enabling OIDC automated publishing on pub.dev, and tagging `v0.1.0`. On the first CI run, expect the `goldens` job to fail until `update-goldens.yml` regenerates the goldens on Linux, and the `pana` job (threshold 0) to fail on the `file_picker` points described under P8. Codecov needs a `CODECOV_TOKEN` secret.

## Implementation Assumptions

- **Plan format** — This plan is organised by build phase (§10 P0–P9), not by the standard Models → App wiring sections. Each phase is treated as one implementation section, with its status tracked under Implementation Progress above.
- **Baseline** — No Flutter project existed before this run (only `.planning/`) and the workspace was not a git repo, so the analysis/test baseline is empty and there were no pre-existing dirty files.
- **Governing skills** — The plan has no Section 0. Per §3 "Governing guidance", only `frontend-design` applies (for every widget); the app-layer `sb-flutter-*` skills don't, since the package has no HTTP or Riverpod layer.
- **§12 / D-19 file_picker bound** — Not the same API across 11–13: 12.0 deprecated and 13.0 removed `withData` on `pickFiles()` (replaced by `pickFile()` + `PlatformFile.readAsBytes()`, which 11.x lacks), and 13.x needs Flutter ≥3.38. Following D-19's fallback, the constraint is `file_picker: ^11.0.0`. Side effect: pana's "up-to-date dependencies" check will likely deduct points because 13.x is outside the range (see P8 notes).
- **Machine limits** — This machine has no Visual Studio C++ workload (no Windows desktop builds) and no Linux/macOS, so anything that needs those (Windows/Linux integration runs, desktop example builds) is left to CI.
- **P0 GitHub repo** — "Create the public GitHub repo and push" was not done: creating a public repo and pushing are external, hard-to-undo actions that this run leaves to the user (it also never pushes). `git init -b main` was done in `src`.
- **P0 example project** — Created with `--project-name scobro_flutter_photo_tools_example --org io.github.scottpaulbrown` so the example's package name is distinct from the library and the bundle ids follow the GitHub owner. The generated `.idea/` and `*.iml` files were removed (already gitignored).
- **P0 lints** — `flutter_lints: ">=5.0.0 <7.0.0"`: 6.x needs Dart 3.8, which would break the Flutter 3.27 (Dart 3.6) CI leg and the downgrade job, so 5.x is allowed too.
- **P0 goldens on non-Linux** — `dart_test.yaml` skips the `golden` tag on Windows/macOS via `on_os`, and adds a `screenshot` tag that is skipped unless run with `--run-skipped` (used to refresh `doc/screenshots`).
- **P1 errors** — `ImageValidationError` is a sealed class with factory constructors `.empty()`, `.unsupportedFormat(found)`, `.tooLarge(bytes, maxBytes)` backed by public subclasses `EmptyImageError`, `UnsupportedImageFormatError`, `ImageTooLargeError`, so callers can `switch` on them.
- **P1 geometry** — Added `FramingGeometry.largestFit(size, ratio)` and `FramingGeometry.pan(source, framing, stageFraction, ...)` (the drag maths, moved out of the old view model) so the controller, painter and tests share one implementation. Pan deltas are fractions of the crop box's width/height.
- **P1 maxZoom** — `PhotoFraming.maxZoom` (a static in the source) moved to `RenderOptions.maxZoom` / the `maxZoom:` parameter of the geometry, as the plan's API sketch implies.
- **P1 renderer extras** — The output never carries EXIF (no location/camera data leaks into uploads). Palette PNGs are expanded before processing. Upscaling uses linear interpolation, downscaling average. Added `PhotoRenderer.bakeOrientation(source)` (upright PNG) for the editor's EXIF fallback (see P4).
- **P1 EXIF fixture** — `test/fixtures/exif_orientation_6.jpg` is generated from `TestImages.exifJpeg()` (80×40 stored, red block top-left, orientation 6). `package:image` applies the orientation, and the renderer test proves the output is upright (40×80, marker top-right).
- **P1 TestImages** — `lib/testing.dart` exports `TestImages` (`asymmetricPng/Jpeg`, `plainJpeg`, `transparentPng`, `exifJpeg`, `brokenJpeg`), ported from the app's `test_images.dart` and extended.
- **P1 coverage tool** — `tool/coverage_gate.dart` (planned for §8) was written now so core coverage could be checked: 100% of `lib/src/core`.
- **P2 file_picker bound** — Settled as `^11.0.0` (see the §12 entry above). `image_picker_platform_interface` and `plugin_platform_interface` were added as dev dependencies so the plugin picker is tested against fake platform interfaces; `file_picker` 11's interface isn't exported, so its test imports it from `src/` with an `implementation_imports` ignore.
- **P2 maxDimension scope** — `PickerOptions.maxDimension` is passed to `image_picker` (camera and the Android/iOS gallery). `file_picker` (web/desktop) has no resize option, so those picks arrive at original size; documented on the field.
- **P2 camera on desktop** — `PluginPhotoSourcePicker.takePhoto()` throws `UnsupportedError` where `canTakePhoto` is false (the sheet never offers it there). Other `PlatformException`s (e.g. `photo_access_denied`) are rethrown and surface through `PhotoFlow` as `PhotoFailed`.
- **P2 web branch in tests** — `PluginPhotoSourcePicker.debugIsWebOverride` (`@visibleForTesting`) lets VM tests take the web path.
- **P2 FakePhotoSourcePicker** — Besides canned picks and call counts, it records `lastOptions` and has a `FakePhotoSourcePicker.withImage()` factory (both sources pick a generated JPEG), which the example's integration test uses.
- **P2 manual check** — "Example picks on web and Windows by hand" can't be done in an unattended run (and Windows builds aren't possible on this machine). Left for the user.
- **P3 strings** — `PhotoToolsStrings` has 30 plain texts (constructor + `copyWith`) and four overridable methods for value-dependent text: `validationMessage`, `megabytes`, `zoomValue`, `removeConfirmTitle(name)`. Localising means subclassing (documented with an example).
- **P3 theme** — `PhotoToolsTheme` fields: `stageBackground`, `stageScrim`, `guideColor`, `guideWidth`, `stageRadius`, `badgeBackground`, `badgeForeground`, `previewBackground`. `PhotoToolsTheme.of(context)` resolves the app's extension over `PhotoToolsTheme.fallback(colorScheme)`, so every value is non-null.
- **P3 scope** — `PhotoToolsScope.of` returns a `PhotoToolsScopeData` with defaults filled in. A nested scope replaces an outer one completely (no merging), which keeps it a plain `InheritedWidget` as planned. The `loader` slot is added in P6, when `VersionedImageLoader` exists.
- **§12 / P1 EXIF on the preview path** — Answered: on the test engine (Skia, Windows host) `ui.instantiateImageCodec` applies EXIF orientation; `test/editor/exif_preview_test.dart` proves the preview and the rendered output agree on the orientation-6 fixture. As a safety net for other platforms, `PhotoEditorController.load` compares the codec's size with `PhotoRenderer.sizeOf`; if they differ it decodes from `PhotoRenderer.bakeOrientation` (upright PNG). This catches orientations 5–8 (the swapped ones, which phone cameras produce); 2–4 would go undetected on a codec that ignores EXIF.
- **P4 controller errors** — `PhotoEditorController.error` is `Object?` (the caught exception), not `String?`, so the controller holds no English text. The widget shows `strings.unreadable` when `status == failed` and `strings.renderFailed` when a render failed (`status == ready && error != null`). Added `idle` to the statuses and `isReady`, `source`, `imageSize` getters.
- **P4 visual direction (frontend-design)** — The package can't impose fonts or a palette, so the direction is "quiet darkroom": everything from `ColorScheme`/`TextTheme`, a dark framing area, half-transparent scrim outside the guide, a white guide line and a dashed outline of the saved rectangle (when the guide isn't a plain rect). Distinctive touch: a rule-of-thirds grid that fades in (180 ms) only while dragging or pinching.
- **P4 stage sizing** — The framing area spans the editor's width; the crop box is the largest box of the aspect ratio inside it with a 6% (12–32 px) margin, capped at 62% of the screen height when the editor sits in a scroll view (or the available height when bounded). The picture outside the crop stays visible under the scrim for context.
- **P4 layout** — Breakpoints are measured on the editor's own width (so it works embedded): <650 full width, 650–1099 a centred 560 column, ≥1100 framing area left + 360 px controls/previews column right, capped at 1280 px and centred. The page's action bar (Cancel + Save, hairline top border) follows the same widths; on phones the two buttons split the width with Save twice as wide.
- **P4 extra controls** — Zoom-out/zoom-in icon buttons at the slider's ends (step = 1/6 of the range) and keyboard support on the focused framing area (arrows move the picture, `+`/`-` zoom), with a focus ring. Scroll-wheel zoom uses `pointerSignalResolver` so it doesn't also scroll the page.
- **P4 PhotoToolsKeys** — Added a public `PhotoToolsKeys` class (stage, slider, zoom buttons, rotate, close, cancel, save, previews, source-sheet rows, change-photo badge) so app and integration tests can find the package's controls.
- **P4 previews built early** — `PhotoPreviewSpec`/`PhotoPreviewStrip` were written in P4 because the editor's `previews` parameter needs them; `PhotoPreviewSpec` has `size` (long edge), `caption` and an optional `builder(context, framed)` to wrap the framed picture (e.g. in the app's avatar). P6 adds the strip's standalone tests/goldens.
- **P4 Choose another** — "Choose another" pops the page with null (as in the source app), so `PhotoFlow` treats it as a cancel.
- **P4 circle guide at other ratios** — Drawn as an oval inscribed in the crop box; documented on `CropGuideShape.circle` and `PhotoEditor.guideShape` and covered by a test (no runtime assert, since an oval is a valid choice).
- **P4 goldens** — Seven goldens (phone/desktop × light/dark/custom theme, plus a tablet 16:9 banner). They were generated on Windows with `--run-skipped --update-goldens`, so the Linux CI golden job will likely need one run of `update-goldens.yml` before it passes. Test fonts (Roboto, Material Icons) are copied from the Flutter SDK into `test/fonts` with their licences.
- **P5 choice types** — `PhotoSourceChoice` is sealed with `DeviceSourceChoice`, `CameraSourceChoice`, `CustomSourceChoice(source)`, `RemoveSourceChoice`, plus `PhotoSourceChoice.device/camera/remove` constants.
- **P5 sheet extras** — `showPhotoSourceSheet` also takes `strings` and `picker` (both default to the scope); the camera row needs `allowCamera` *and* `picker.canTakePhoto`. Rows are 56 px tonal tiles with hairline borders (from the source app), Remove is set apart by extra spacing and the error colour. Generic remove prompt: "Remove this photo?" / "Remove {name}'s photo?" + "The current photo will be removed."
- **P5 flow extras** — `PhotoFlow.run` also takes `removeConfirmName`, `allowCamera`, `picker`, `renderer` and `strings`. `onBusy` is reported around custom-source loading, upload and remove (not around the platform picker, which shows its own UI). Errors map as: upload → `errorMessage(e)` ?? `strings.uploadFailed`; remove → `errorMessage(e)` ?? new `strings.removeFailed`; custom-source/picker exceptions → `errorMessage(e)` ?? `strings.sourceFailed`; refused files → `strings.validationMessage`; camera denied → `strings.cameraDenied`. Custom-source bytes are validated with `pickerOptions.validation`. If the calling context unmounts mid-flow, the result is `PhotoCancelled`.
- **P5 removeFailed string** — Added `PhotoToolsStrings.removeFailed` ("The photo could not be removed. Please try again."), since "could not be saved" reads wrong for a failed removal.
- **P6 loader details** — `VersionedImageLoader` caches `null` ("no photo") but not failures (a throwing fetch returns null and is retried next time). Added `contains`, `peek` and `length`. In-flight de-duplication is cleaned up via `whenComplete`, so a fetcher that throws synchronously can't get stuck in the in-flight map.
- **P6 PhotoAvatar** — `initialsFor` gives up to two initials (first + last word); text colour on a custom `color` is picked by `ThemeData.estimateBrightnessForColor`. The ring is drawn only when `ringColor` is set (`ringWidth` defaults by size: 3/2/1.5). Loader-backed photos use `VersionedMemoryImage` in an `Image` with a 150 ms fade over the initials and `errorBuilder` falling back to the initials (null bytes). `semanticLabel` null makes the avatar decorative.
- **P6 scope loader** — `PhotoToolsScope`/`PhotoToolsScopeData` gained `loader` (nullable; no default loader, since fetching is app-specific).
- **P6 goldens** — Avatars at six sizes + badges (normal, busy, small) and the source sheet, each in light/dark/custom theme (6 goldens). Same Windows-generated caveat as P4.
- **P7 example structure** — `example/lib/main.dart` just runs `GalleryApp`; the demos live in `example/lib/src/` (`gallery_app.dart`, `avatar_demo.dart`, `banner_demo.dart`, `loader_demo.dart`, `fake_photo_server.dart`). Navigation follows frontend-design: bottom bar under 650, labelled rail 650–1099, extended rail from 1100; content capped at 720 px.
- **P7 example look (frontend-design)** — "Warm editorial": terracotta seed on a paper-coloured surface (warm dark in dark mode), heavy tight display titles with small tracked eyebrows, quiet tonal panels with hairline borders. No bundled fonts (keeps the example dependency-free). A "Use a sample picture" custom source draws a generated landscape with `dart:ui`, so the custom-source path works without network or files.
- **P7 fake server** — `FakePhotoServer` (latency, "Make uploads fail" toggle, version per upload, `fetchCount`, `seed`, `bumpVersions`) backs the avatar upload and the loader demo.
- **P7 integration test** — The flows live in `example/integration_test/photo_flow_steps.dart`; `photo_flow_test.dart` runs them on a device and `example/test/photo_flow_widget_test.dart` runs the same steps on the VM, which is how they were verified here (all pass: upload 512 px JPEG after rotate + zoom, failing upload message, staged 1600×900 banner, cancel). Running them on Chrome/Linux (`integration.yml`) is left to CI: no chromedriver, Linux or Windows desktop toolchain on this machine. `flutter build web` and `flutter build web --wasm` of the example both succeed.
- **P7 example deps** — Added `cupertino_icons` to the example to silence a font warning from a dependency's icon use.
- **P8 screenshots** — `doc/screenshots/*.png` (editor phone, editor desktop dark 16:9, source sheet, avatars light/dark) are written at 2× by `test/screenshots/screenshots_test.dart` (tag `screenshot`, skipped by default) using a generated landscape picture. Four are listed under `screenshots:` in `pubspec.yaml`; the README links them through raw.githubusercontent URLs on `main`, so they show only once the repo is pushed.
- **P8 publish size** — `.pubignore` also excludes `test/fonts/` and `test/goldens/` (about 2 MB). `flutter_test_config.dart` skips fonts that are missing, so published tests still run. Archive: 541 KB.
- **P8 example permissions** — Added `NSPhotoLibraryUsageDescription`/`NSCameraUsageDescription` to the example's `Info.plist` and the `files.user-selected.read-only` entitlement to its macOS entitlements, matching `doc/platform-setup.md`.
- **P8 community files** — `CODE_OF_CONDUCT.md` is a condensed Contributor Covenant 2.1 with attribution; reports go to the maintainer through GitHub, since no contact email is given in the plan. `SECURITY.md` points to GitHub private vulnerability reporting. The issue and PR templates are written in P9 with the rest of `.github/`.
- **P9 CI matrix** — `analyze-test` runs on stable and 3.27.x. Formatting and `--fatal-infos` analysis run on stable only, because formatter output and deprecation infos differ between SDK versions; 3.27.x runs plain `flutter analyze`. Example tests (`example/test`, which include the integration flows on the VM) run in both legs. The `downgrade` job uses Flutter 3.27.x, the true floor.
- **P9 lower bounds checked locally** — `flutter pub downgrade` (file_picker 11.0.0, image_picker 1.2.0, image 4.5.0) followed by analyze + tests passed on this machine (Flutter 3.35.4); dependencies were then upgraded back.
- **P9 integration on web** — Added `example/test_driver/integration_test.dart` for `flutter drive -d web-server`; chromedriver comes from `browser-actions/setup-chrome`.
- **P9 update-goldens** — Uploads the regenerated goldens as an artifact and opens a PR against the branch it ran on (`peter-evans/create-pull-request`).
- **P9 .gitattributes** — Added `* text=auto eol=lf` (binaries marked binary), because `flutter create` on Windows wrote CRLF files.
- **Commit scope** — `.planning/PLAN.md` existed before this run (untracked, no repo yet). It is committed with the rest because §6 places it in the repo and it holds this run's status and assumptions.
- **P9 GitHub repo (follow-up, 2026-10-26, at the user's request)** — Created the public repo `scottpaulbrown/scobro_flutter_photo_tools`, pushed `main`, and set: description, homepage (the pub.dev page), topics, wiki and discussions off, private vulnerability reporting on, a `pub.dev` environment that only `v*` tags can deploy to, and permission for workflows to open PRs. The bot's "Update golden images" PR (#6) was merged, replacing the Windows goldens with Linux ones. CI fixes for current stable (Flutter 3.47.8): parameter rename for Flutter 3.27's analyzer, the example's Gradle 8.14.3 / AGP 8.11.1 / Kotlin 2.2.20, the analyzer excludes newer Flutter writes into the example's `analysis_options.yaml`, `example/pubspec.lock` untracked, and a chromedriver that matches the runner's Chrome. Every CI and integration job passes except `pana score`: 140/160 on CI, losing only the two `file_picker` checks from P8 (docs and screenshots get full marks on Linux). Branch protection on `main` requires every CI job except pana; admins can still push directly. Still left for the user: the first `flutter pub publish`, enabling automated publishing on pub.dev, tagging `v0.1.0`, the `CODECOV_TOKEN` secret, and the five Dependabot PRs that bump GitHub Actions versions.
