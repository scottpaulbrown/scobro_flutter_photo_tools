import 'package:file_picker/file_picker.dart';
// The file_picker 11 platform interface isn't exported; tests swap it out.
// ignore: implementation_imports
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

class _FakeImagePicker extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  XFile? answer;
  Object? error;
  final calls = <(ImageSource, ImagePickerOptions)>[];

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    calls.add((source, options));
    if (error != null) throw error!;
    return answer;
  }
}

class _FakeFilePicker extends FilePickerPlatform {
  FilePickerResult? answer;
  final calls = <({FileType type, bool withData})>[];

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    // Matches the interface, which leaves the return type out.
    // ignore: inference_failure_on_function_return_type
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
  }) async {
    calls.add((type: type, withData: withData));
    return answer;
  }
}

void main() {
  const picker = PluginPhotoSourcePicker();
  late _FakeImagePicker images;
  late _FakeFilePicker files;
  final jpeg = TestImages.plainJpeg();

  setUp(() {
    images = _FakeImagePicker();
    files = _FakeFilePicker();
    ImagePickerPlatform.instance = images;
    FilePickerPlatform.instance = files;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    PluginPhotoSourcePicker.debugIsWebOverride = null;
  });

  group('canTakePhoto', () {
    test('true on Android, iOS and web', () {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(picker.canTakePhoto, isTrue);
      }
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      PluginPhotoSourcePicker.debugIsWebOverride = true;
      expect(picker.canTakePhoto, isTrue);
    });

    test('false in desktop apps', () {
      for (final platform in [
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(picker.canTakePhoto, isFalse);
      }
    });
  });

  group('pickFromDevice on Android and iOS uses the image_picker gallery', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);

    test('passes maxDimension and skips full metadata', () async {
      images.answer =
          XFile.fromData(jpeg, name: 'IMG_1.jpg', path: 'IMG_1.jpg');
      final result =
          await picker.pickFromDevice(const PickerOptions(maxDimension: 2000));

      expect(result, isA<Picked>());
      final image = (result as Picked).image;
      expect(image.name, 'IMG_1.jpg');
      expect(image.format, ImageFormat.jpeg);
      expect(image.bytes, jpeg);
      expect(files.calls, isEmpty);
      final (source, options) = images.calls.single;
      expect(source, ImageSource.gallery);
      expect(options.maxWidth, 2000);
      expect(options.maxHeight, 2000);
      expect(options.requestFullMetadata, isFalse);
    });

    test('the default maxDimension is 4096; null keeps full size', () async {
      images.answer = XFile.fromData(jpeg, name: 'a.jpg', path: 'a.jpg');
      await picker.pickFromDevice();
      expect(images.calls.last.$2.maxWidth, 4096);
      await picker.pickFromDevice(const PickerOptions(maxDimension: null));
      expect(images.calls.last.$2.maxWidth, isNull);
    });

    test('backing out is a cancel', () async {
      expect(await picker.pickFromDevice(), const PickCancelled());
    });

    test('a file the rules refuse is refused', () async {
      images.answer = XFile.fromData(jpeg, name: 'a.jpg', path: 'a.jpg');
      final result = await picker.pickFromDevice(
        PickerOptions(validation: ValidationRules(maxBytes: jpeg.length - 1)),
      );
      expect(
        result,
        PickRefused(
            ImageValidationError.tooLarge(jpeg.length, jpeg.length - 1)),
      );
    });

    test('other platform errors are rethrown', () async {
      images.error = PlatformException(code: 'photo_access_denied');
      await expectLater(
        picker.pickFromDevice(),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('pickFromDevice on web and desktop uses file_picker', () {
    for (final (label, web, platform) in [
      ('Windows', false, TargetPlatform.windows),
      ('macOS', false, TargetPlatform.macOS),
      ('Linux', false, TargetPlatform.linux),
      ('web', true, TargetPlatform.android),
    ]) {
      test('$label: images only, with data', () async {
        debugDefaultTargetPlatformOverride = platform;
        PluginPhotoSourcePicker.debugIsWebOverride = web;
        files.answer = FilePickerResult([
          PlatformFile(
              name: 'cat.png', size: 3, bytes: TestImages.asymmetricPng()),
        ]);

        final result = await picker.pickFromDevice();

        expect((result as Picked).image.name, 'cat.png');
        expect(result.image.format, ImageFormat.png);
        expect(files.calls.single, (type: FileType.image, withData: true));
        expect(images.calls, isEmpty);
      });
    }

    test('backing out is a cancel', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(await picker.pickFromDevice(), const PickCancelled());
      files.answer = FilePickerResult(const []);
      expect(await picker.pickFromDevice(), const PickCancelled());
    });

    test('a file without data is refused as empty', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      files.answer = FilePickerResult([PlatformFile(name: 'x.jpg', size: 0)]);
      expect(
        await picker.pickFromDevice(),
        const PickRefused(ImageValidationError.empty()),
      );
    });

    test('a HEIC file is refused as unsupported', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final heic = Uint8List.fromList(
          [0, 0, 0, 0x18, ...'ftypheic'.codeUnits, 0, 0, 0, 0]);
      files.answer = FilePickerResult(
          [PlatformFile(name: 'x.heic', size: 16, bytes: heic)]);
      expect(
        await picker.pickFromDevice(),
        const PickRefused(ImageValidationError.unsupportedFormat(null)),
      );
    });
  });

  group('takePhoto', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

    test('uses the image_picker camera with maxDimension', () async {
      images.answer = XFile.fromData(jpeg, name: 'shot.jpg', path: 'shot.jpg');
      final result = await picker.takePhoto();
      expect((result as Picked).image.name, 'shot.jpg');
      final (source, options) = images.calls.single;
      expect(source, ImageSource.camera);
      expect(options.maxWidth, 4096);
    });

    test('a denied camera is CameraDenied', () async {
      images.error = PlatformException(code: 'camera_access_denied');
      expect(await picker.takePhoto(), const CameraDenied());
    });

    test('backing out is a cancel', () async {
      expect(await picker.takePhoto(), const PickCancelled());
    });

    test('desktop apps have no camera', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(() => picker.takePhoto(), throwsUnsupportedError);
    });
  });
}
