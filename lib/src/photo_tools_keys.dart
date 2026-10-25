import 'package:flutter/widgets.dart';

/// Keys on the package's interactive widgets, for widget and integration
/// tests: `find.byKey(PhotoToolsKeys.save)`.
abstract final class PhotoToolsKeys {
  /// The editor's framing area (drag, pinch and scroll here).
  static const stage = ValueKey<String>('photo-tools-stage');

  /// The editor's zoom slider.
  static const zoomSlider = ValueKey<String>('photo-tools-zoom');

  /// The editor's zoom-out button.
  static const zoomOut = ValueKey<String>('photo-tools-zoom-out');

  /// The editor's zoom-in button.
  static const zoomIn = ValueKey<String>('photo-tools-zoom-in');

  /// The editor's rotate button.
  static const rotate = ValueKey<String>('photo-tools-rotate');

  /// The editor page's close button.
  static const close = ValueKey<String>('photo-tools-close');

  /// The editor page's Cancel button.
  static const cancel = ValueKey<String>('photo-tools-cancel');

  /// The editor page's Save button.
  static const save = ValueKey<String>('photo-tools-save');

  /// The editor's previews.
  static const previews = ValueKey<String>('photo-tools-previews');

  /// The source sheet's "From this device" row.
  static const sourceDevice = ValueKey<String>('photo-tools-source-device');

  /// The source sheet's "Take a photo" row.
  static const sourceCamera = ValueKey<String>('photo-tools-source-camera');

  /// The source sheet's "Remove photo" row.
  static const sourceRemove = ValueKey<String>('photo-tools-source-remove');

  /// The source sheet's row for the custom source with [id].
  static ValueKey<String> sourceCustom(String id) =>
      ValueKey<String>('photo-tools-source-custom-$id');

  /// `ChangePhotoBadge`'s tap target.
  static const changePhoto = ValueKey<String>('photo-tools-change-photo');
}
