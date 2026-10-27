## 0.1.1

- Web: much faster editing and saving. `PhotoRenderer` now uses the
  browser's image codec, canvas and JPEG encoder on the web instead of
  decoding in Dart on the main thread. On a 12-megapixel photo in Chrome
  (debug build), opening the editor drops from about 16 s to under 0.1 s and
  saving from about 21 s to under 0.5 s; the page no longer freezes.
  Output and EXIF handling are unchanged.

## 0.1.0

First release.

- `PhotoFlow.run`: source sheet, pick, frame, then hand the result to an
  upload callback (or return it, in staged mode). Results: `PhotoSaved`,
  `PhotoRemoved`, `PhotoCancelled`, `PhotoFailed`.
- Framing editor: `PhotoEditorPage`, `showPhotoEditor` and the embeddable
  `PhotoEditor` with `PhotoEditorController`. Drag, pinch, mouse-wheel and
  keyboard zoom; rotate; live previews; discard prompt; layouts for phone,
  tablet and desktop.
- Any aspect ratio with circle, rounded-rectangle or rectangle guides.
- `PhotoRenderer`: EXIF orientation, rotate, crop, resize, JPEG (with a
  background for transparency) or PNG; EXIF stripped from the output.
- `ImageValidator` with typed `ImageValidationError`s and `ValidationRules`.
- `PhotoSourcePicker` with `PluginPhotoSourcePicker` (`image_picker` +
  `file_picker`) and `FakePhotoSourcePicker` in `testing.dart`.
- `showPhotoSourceSheet` with custom sources and a confirmed Remove row.
- `PhotoAvatar`, `ChangePhotoBadge`, `PhotoPreviewStrip`.
- `VersionedImageLoader` and `VersionedMemoryImage` for photos behind auth.
- `PhotoToolsScope`, `PhotoToolsStrings` and `PhotoToolsTheme` for strings,
  services and theming; `PhotoToolsKeys` for tests.
