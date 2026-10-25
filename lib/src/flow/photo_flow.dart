import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../core/edited_image.dart';
import '../core/image_validator.dart';
import '../core/photo_renderer.dart';
import '../core/render_options.dart';
import '../editor/crop_guide_shape.dart';
import '../editor/photo_editor_page.dart';
import '../picking/photo_source_picker.dart';
import '../picking/pick_result.dart';
import '../picking/picker_options.dart';
import '../sources/custom_photo_source.dart';
import '../sources/photo_source_sheet.dart';
import '../theme/photo_tools_scope.dart';
import '../theme/photo_tools_strings.dart';
import '../widgets/photo_preview_strip.dart';
import 'photo_flow_result.dart';

/// The whole "change photo" journey in one call: choose a source, pick,
/// frame, and hand the result to your uploader.
abstract final class PhotoFlow {
  /// Runs the flow and resolves to how it ended.
  ///
  /// 1. Shows the source sheet (`showPhotoSourceSheet`) with the device, the
  ///    camera (where available), [customSources] and, when [onRemove] is
  ///    given, Remove photo.
  /// 2. Picks with [picker] (default: `PhotoToolsScope`'s picker), checking
  ///    the file against [pickerOptions].
  /// 3. Opens the editor (`showPhotoEditor`) with [options] and [guideShape].
  /// 4. With [upload], calls it with the framed picture and returns
  ///    [PhotoSaved] with its result. Without [upload] ("staged" mode, for
  ///    example before the record exists), returns [PhotoSaved] with the
  ///    picture and uploads nothing.
  ///
  /// [onBusy] reports `true` while a custom source loads, the photo uploads
  /// or is removed, and `false` after; use it to show progress, for example
  /// on a `ChangePhotoBadge`. Errors come back as [PhotoFailed] with text from
  /// [errorMessage] (for your own exceptions) or [strings]. The flow never
  /// shows a snack bar or dialog for them.
  static Future<PhotoFlowResult<T>> run<T>(
    BuildContext context, {
    RenderOptions options = const RenderOptions(),
    CropGuideShape guideShape = CropGuideShape.circle,
    PickerOptions pickerOptions = const PickerOptions(),
    List<CustomPhotoSource> customSources = const [],
    Future<void> Function()? onRemove,
    Future<T> Function(EditedImage image)? upload,
    void Function(bool busy)? onBusy,
    String Function(Object error)? errorMessage,
    String? sheetTitle,
    String? editorTitle,
    String? removeConfirmName,
    bool allowCamera = true,
    List<PhotoPreviewSpec> previews = const [],
    PhotoSourcePicker? picker,
    PhotoRenderer? renderer,
    PhotoToolsStrings? strings,
  }) async {
    final scope = PhotoToolsScope.of(context);
    final s = strings ?? scope.strings;
    final p = picker ?? scope.picker;
    void busy(bool value) => onBusy?.call(value);
    PhotoFailed<T> failed(Object error, String fallback) =>
        PhotoFailed<T>(errorMessage?.call(error) ?? fallback, error);

    final choice = await showPhotoSourceSheet(
      context,
      title: sheetTitle,
      allowCamera: allowCamera,
      customSources: customSources,
      showRemove: onRemove != null,
      removeConfirmName: removeConfirmName,
      strings: s,
      picker: p,
    );
    if (choice == null || !context.mounted) return PhotoCancelled<T>();

    final Uint8List source;
    switch (choice) {
      case RemoveSourceChoice():
        busy(true);
        try {
          await onRemove!();
          return PhotoRemoved<T>();
        } catch (e) {
          return failed(e, s.removeFailed);
        } finally {
          busy(false);
        }
      case CustomSourceChoice(source: final custom):
        busy(true);
        final Uint8List? loaded;
        try {
          loaded = await custom.load();
        } catch (e) {
          return failed(e, s.sourceFailed);
        } finally {
          busy(false);
        }
        if (loaded == null) return PhotoCancelled<T>();
        final problem = ImageValidator.check(loaded, pickerOptions.validation);
        if (problem != null) {
          return PhotoFailed<T>(s.validationMessage(problem), problem);
        }
        source = loaded;
      case DeviceSourceChoice() || CameraSourceChoice():
        final PickResult pick;
        try {
          pick = choice is CameraSourceChoice
              ? await p.takePhoto(pickerOptions)
              : await p.pickFromDevice(pickerOptions);
        } catch (e) {
          return failed(e, s.sourceFailed);
        }
        switch (pick) {
          case Picked(:final image):
            source = image.bytes;
          case PickCancelled():
            return PhotoCancelled<T>();
          case PickRefused(:final error):
            return PhotoFailed<T>(s.validationMessage(error), error);
          case CameraDenied():
            return PhotoFailed<T>(s.cameraDenied, pick);
        }
    }
    if (!context.mounted) return PhotoCancelled<T>();

    final image = await showPhotoEditor(
      context,
      source: source,
      options: options,
      guideShape: guideShape,
      title: editorTitle,
      previews: previews,
      strings: s,
      renderer: renderer,
    );
    if (image == null) return PhotoCancelled<T>();
    if (upload == null) return PhotoSaved<T>(image);

    busy(true);
    try {
      return PhotoSaved<T>(image, await upload(image));
    } catch (e) {
      return failed(e, s.uploadFailed);
    } finally {
      busy(false);
    }
  }
}
