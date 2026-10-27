# Platform setup

`scobro_flutter_photo_tools` picks pictures with
[`image_picker`](https://pub.dev/packages/image_picker) (camera, and the
Android/iOS photo gallery) and [`file_picker`](https://pub.dev/packages/file_picker)
(web and desktop). Those plugins need a little setup on some platforms.

## iOS

Add these keys to `ios/Runner/Info.plist`. The text is shown to the user in
the permission prompt, so write it for your app:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Choose a photo for your profile.</string>
<key>NSCameraUsageDescription</key>
<string>Take a photo for your profile.</string>
```

Pictures in HEIC format are returned as JPEG by the gallery picker.

## Android

Nothing to add. The gallery uses the system Photo Picker, which needs no
permission. If your app declares the `CAMERA` permission for another reason,
Android requires it to be granted before the camera can be used; a denial
comes back as `PhotoFailed` with `PhotoToolsStrings.cameraDenied`.

## macOS

`file_picker` needs read access to files the user chooses. Add this to both
`macos/Runner/DebugProfile.entitlements` and
`macos/Runner/Release.entitlements`:

```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

## Web

Nothing to add. Two things to know:

- Web has no background isolates, so the renderer hands the work to the
  browser: Flutter's image codec decodes, the canvas crops and scales, and
  the browser's encoder writes the JPEG. Large photos stay quick.
- Browsers' file dialogs return files as they are: there is no downscaling
  before editing, and HEIC files are refused as unsupported.

## Windows

Nothing to add. The camera isn't offered on desktop.

## Linux

`file_picker` shows the dialog through the XDG desktop portal, falling back
to `zenity` or `kdialog`. Most desktops have one of them already; on a bare
system install `zenity`.
