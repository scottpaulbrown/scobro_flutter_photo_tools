# scobro_flutter_photo_tools

[![pub package](https://img.shields.io/pub/v/scobro_flutter_photo_tools.svg)](https://pub.dev/packages/scobro_flutter_photo_tools)
[![CI](https://github.com/scottpaulbrown/scobro_flutter_photo_tools/actions/workflows/ci.yml/badge.svg)](https://github.com/scottpaulbrown/scobro_flutter_photo_tools/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/scottpaulbrown/scobro_flutter_photo_tools/branch/main/graph/badge.svg)](https://codecov.io/gh/scottpaulbrown/scobro_flutter_photo_tools)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Pick a photo, let the user crop, rotate and zoom it to any aspect ratio, and
get back a ready-to-upload JPEG or PNG. The package hands the result to **your**
upload code, so it works with any backend, HTTP client, state management,
router or design system.

| Editor | Source sheet | Avatars |
|---|---|---|
| ![The framing editor on a phone](https://raw.githubusercontent.com/scottpaulbrown/scobro_flutter_photo_tools/main/doc/screenshots/editor_phone.png) | ![The photo source sheet](https://raw.githubusercontent.com/scottpaulbrown/scobro_flutter_photo_tools/main/doc/screenshots/source_sheet.png) | ![Avatars and change-photo badges](https://raw.githubusercontent.com/scottpaulbrown/scobro_flutter_photo_tools/main/doc/screenshots/avatars_light.png) |

## Features

- **One-call flow.** `PhotoFlow.run` shows the source sheet, picks, opens the
  editor and calls your upload callback, then tells you how it ended.
- **Framing editor** with drag, pinch, mouse-wheel and keyboard zoom, a
  Rotate button, a live preview strip, and a "discard changes?" prompt. Use the
  ready-made page or embed the `PhotoEditor` widget.
- **Any aspect ratio** (avatars, 16:9 banners, 3:4 cards) with a circle,
  rounded-rectangle or rectangle guide.
- **Correct output.** EXIF orientation applied, location data stripped,
  resized to the size you ask for, JPEG or PNG. The preview and the saved file
  come from the same geometry.
- **Display widgets.** `PhotoAvatar` (photo or initials), `ChangePhotoBadge`
  (camera badge with a busy ring), and `VersionedImageLoader` for photos
  behind cookie or token auth.
- **Fits your app.** Colours come from your `ColorScheme`, every string can be
  replaced, and `PhotoToolsTheme` adjusts the details. No Riverpod, no Dio, no
  go_router.
- **Testable.** `FakePhotoSourcePicker` and `TestImages` in `testing.dart`.

## Platform support

| | Android | iOS | Web | Windows | macOS | Linux |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| Pick from device | ✅ gallery | ✅ gallery (HEIC → JPEG) | ✅ | ✅ | ✅ | ✅ |
| Take a photo | ✅ | ✅ | ✅ | — | — | — |
| Edit and render | ✅ | ✅ | ✅ ¹ | ✅ | ✅ | ✅ |

¹ Web has no background isolates, so the browser does the decoding, scaling
and JPEG encoding natively. A 12-megapixel photo opens and saves in well under
a second.

## Install

```sh
flutter pub add scobro_flutter_photo_tools
```

Then follow [platform setup](doc/platform-setup.md): iOS needs two
`Info.plist` keys and macOS one entitlement.

## Quick start

```dart
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';

Future<void> changePhoto(BuildContext context) async {
  final result = await PhotoFlow.run<String>(
    context,
    options: const RenderOptions(outputLongEdge: 512), // 512 x 512 JPEG
    upload: (image) => api.uploadAvatar(
      image.bytes,
      contentType: image.mimeType,
      fileName: image.suggestedFileName('avatar'),
    ),
  );
  switch (result) {
    case PhotoSaved(:final uploadResult):
      print('Uploaded, new version $uploadResult');
    case PhotoFailed(:final message):
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    case PhotoRemoved() || PhotoCancelled():
      break;
  }
}
```

See [upload recipes](doc/upload-recipes.md) for Dio, `http`, Firebase
Storage and presigned-URL versions of `upload`.

## Recipes

### Staged mode (no upload yet)

Leave out `upload` and the flow returns the framed picture, for example to
hold until a new record is saved:

```dart
final result = await PhotoFlow.run<void>(context);
if (result case PhotoSaved(:final image)) {
  setState(() => _pendingPhoto = image.bytes);
}
```

### A 16:9 banner

```dart
await PhotoFlow.run<void>(
  context,
  options: const RenderOptions(aspectRatio: 16 / 9, outputLongEdge: 1600),
  guideShape: CropGuideShape.roundedRect,
);
```

### Only the editor

Already have the bytes? Open the editor page directly, or embed
`PhotoEditor` with your own `PhotoEditorController`:

```dart
final edited = await showPhotoEditor(context, source: bytes);
```

### Remove and custom sources

```dart
await PhotoFlow.run<String>(
  context,
  onRemove: () => api.deleteAvatar(),       // adds "Remove photo" (confirmed)
  removeConfirmName: user.firstName,        // "Remove Sam's photo?"
  customSources: [
    CustomPhotoSource(
      id: 'google',
      icon: Icons.account_circle_outlined,
      label: 'Use Google picture',
      load: () => api.fetchGooglePicture(), // null = cancelled
    ),
  ],
  upload: (image) => api.uploadAvatar(image.bytes),
);
```

### Avatars and the change-photo badge

```dart
ChangePhotoBadge(
  size: 96,
  busy: _uploading,                 // from PhotoFlow.run(onBusy: ...)
  onTap: () => changePhoto(context),
  child: PhotoAvatar(
    name: user.name,                // initials when there's no photo
    size: 96,
    color: user.color,
    photoId: user.id,
    photoVersion: user.photoVersion, // null = no photo
  ),
)
```

### Photos behind auth: `VersionedImageLoader`

`Image.network` can't send your cookies or tokens on every platform. Fetch
with your own client and let the loader cache by id **and** version, so a
changed photo is fetched again and an unchanged one comes from memory:

```dart
final loader = VersionedImageLoader(
  fetch: (id, version) async {
    final response = await dio.get<List<int>>(
      '/users/$id/photo',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.statusCode == 200
        ? Uint8List.fromList(response.data!)
        : null;
  },
);

PhotoToolsScope(loader: loader, child: MaterialApp(...));
```

### Theming

Colours follow your `ColorScheme`. To change details, add a
`PhotoToolsTheme`:

```dart
ThemeData(
  extensions: const [
    PhotoToolsTheme(guideColor: Colors.amber, stageRadius: 8),
  ],
)
```

### Strings and localisation

Every string is in `PhotoToolsStrings`. Replace some with `copyWith`, or
subclass it for a full translation, and set it once:

```dart
PhotoToolsScope(
  strings: const PhotoToolsStrings(save: 'Enregistrer', cancel: 'Annuler'),
  child: MaterialApp(...),
);
```

### Testing

Swap the platform picker for a fake, so widget and integration tests never
touch a plugin:

```dart
import 'package:scobro_flutter_photo_tools/testing.dart';

await tester.pumpWidget(
  PhotoToolsScope(
    picker: FakePhotoSourcePicker.withImage(),
    child: const MyApp(),
  ),
);
await tester.tap(find.byKey(PhotoToolsKeys.changePhoto));
```

`PhotoToolsKeys` has keys for the editor's controls and the sheet's rows.

## Limitations

- **HEIC** is only supported through the Android/iOS photo gallery, which
  converts it to JPEG. Elsewhere a HEIC file is refused as unsupported.
- **No free-form crop, upload progress, drag-and-drop or flip** yet. They're
  on the roadmap.

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
