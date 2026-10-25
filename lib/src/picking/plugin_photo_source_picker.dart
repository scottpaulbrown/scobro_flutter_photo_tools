import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/image_format.dart';
import '../core/image_validator.dart';
import 'photo_source_picker.dart';
import 'pick_result.dart';
import 'picker_options.dart';

/// The default [PhotoSourcePicker], built on `image_picker` and `file_picker`.
///
/// - **Device, Android and iOS:** the `image_picker` photo gallery. iOS
///   returns HEIC pictures as JPEG, and `PickerOptions.maxDimension` is
///   passed through so huge pictures arrive downscaled.
/// - **Device, web and desktop:** the `file_picker` file dialog, limited to
///   images.
/// - **Camera:** `image_picker`, on Android, iOS and web. A denied camera
///   permission comes back as [CameraDenied].
///
/// See the package README for the iOS `Info.plist` keys and macOS
/// entitlements these plugins need.
class PluginPhotoSourcePicker implements PhotoSourcePicker {
  /// Creates a [PluginPhotoSourcePicker].
  const PluginPhotoSourcePicker();

  /// Overrides `kIsWeb` in tests, which always run on the VM.
  @visibleForTesting
  static bool? debugIsWebOverride;

  bool get _isWeb => debugIsWebOverride ?? kIsWeb;

  bool get _isMobile =>
      !_isWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  bool get canTakePhoto => _isWeb || _isMobile;

  @override
  Future<PickResult> pickFromDevice([
    PickerOptions options = const PickerOptions(),
  ]) async {
    if (_isMobile) return _pickWithImagePicker(ImageSource.gallery, options);
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file == null) return const PickCancelled();
    final bytes = file.bytes;
    if (bytes == null) {
      return const PickRefused(ImageValidationError.empty());
    }
    return _validated(file.name, bytes, options);
  }

  /// Throws an [UnsupportedError] where [canTakePhoto] is false.
  @override
  Future<PickResult> takePhoto([
    PickerOptions options = const PickerOptions(),
  ]) {
    if (!canTakePhoto) {
      throw UnsupportedError('This platform has no camera to offer.');
    }
    return _pickWithImagePicker(ImageSource.camera, options);
  }

  Future<PickResult> _pickWithImagePicker(
    ImageSource source,
    PickerOptions options,
  ) async {
    final max = options.maxDimension?.toDouble();
    try {
      final shot = await ImagePicker().pickImage(
        source: source,
        maxWidth: max,
        maxHeight: max,
        requestFullMetadata: false,
      );
      if (shot == null) return const PickCancelled();
      return _validated(shot.name, await shot.readAsBytes(), options);
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') return const CameraDenied();
      rethrow;
    }
  }

  PickResult _validated(String name, Uint8List bytes, PickerOptions options) {
    final error = ImageValidator.check(bytes, options.validation);
    if (error != null) return PickRefused(error);
    return Picked(
      PickedImage(name: name, bytes: bytes, format: detectImageFormat(bytes)!),
    );
  }
}
