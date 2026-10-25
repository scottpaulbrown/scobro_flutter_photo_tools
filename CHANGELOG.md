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
