import '../core/image_format.dart';
import '../picking/photo_source_picker.dart';
import '../picking/pick_result.dart';
import '../picking/picker_options.dart';
import 'test_images.dart';

/// A [PhotoSourcePicker] that answers with canned results, for widget,
/// integration and app tests. Hand it to `PhotoToolsScope(picker: ...)` or to
/// `PhotoFlow.run`.
class FakePhotoSourcePicker implements PhotoSourcePicker {
  /// Creates a [FakePhotoSourcePicker]. Both sources cancel by default.
  FakePhotoSourcePicker({
    this.devicePick = const PickCancelled(),
    this.cameraPick = const PickCancelled(),
    this.canTakePhoto = true,
  });

  /// A fake whose device and camera both pick [TestImages.asymmetricJpeg]
  /// (80 x 40 unless [width] and [height] are given).
  factory FakePhotoSourcePicker.withImage({int width = 80, int height = 40}) {
    final pick = Picked(
      PickedImage(
        name: 'test.jpg',
        bytes: TestImages.asymmetricJpeg(width: width, height: height),
        format: ImageFormat.jpeg,
      ),
    );
    return FakePhotoSourcePicker(devicePick: pick, cameraPick: pick);
  }

  /// What [pickFromDevice] answers.
  PickResult devicePick;

  /// What [takePhoto] answers.
  PickResult cameraPick;

  @override
  bool canTakePhoto;

  /// How many times [pickFromDevice] was called.
  int deviceCalls = 0;

  /// How many times [takePhoto] was called.
  int cameraCalls = 0;

  /// The options passed to the most recent call.
  PickerOptions? lastOptions;

  @override
  Future<PickResult> pickFromDevice([
    PickerOptions options = const PickerOptions(),
  ]) async {
    deviceCalls++;
    lastOptions = options;
    return devicePick;
  }

  @override
  Future<PickResult> takePhoto([
    PickerOptions options = const PickerOptions(),
  ]) async {
    cameraCalls++;
    lastOptions = options;
    return cameraPick;
  }
}
