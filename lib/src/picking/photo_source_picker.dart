import 'pick_result.dart';
import 'picker_options.dart';

/// Chooses a picture from the device or the camera.
///
/// Everything that touches a platform plugin sits behind this interface, so
/// tests can swap in `FakePhotoSourcePicker` from `testing.dart`. The default
/// implementation is `PluginPhotoSourcePicker`.
abstract interface class PhotoSourcePicker {
  /// Whether [takePhoto] is available: true on Android, iOS and web, false in
  /// Windows, macOS and Linux apps.
  bool get canTakePhoto;

  /// Lets the user choose a picture stored on the device.
  Future<PickResult> pickFromDevice([PickerOptions options]);

  /// Lets the user take a picture with the camera.
  Future<PickResult> takePhoto([PickerOptions options]);
}
