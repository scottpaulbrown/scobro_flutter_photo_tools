import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

import '../helpers.dart';

void main() {
  late FakePhotoSourcePicker picker;
  PhotoFlowResult<String>? result;
  late List<bool> busy;

  setUp(() {
    picker = FakePhotoSourcePicker.withImage();
    result = null;
    busy = [];
  });

  Future<void> start(
    WidgetTester tester, {
    Future<String> Function(EditedImage image)? upload,
    Future<void> Function()? onRemove,
    List<CustomPhotoSource> customSources = const [],
    String Function(Object error)? errorMessage,
    PickerOptions pickerOptions = const PickerOptions(),
    RenderOptions options = const RenderOptions(outputLongEdge: 128),
  }) async {
    useSurface(tester, Surfaces.phone);
    await tester.pumpWidget(
      PhotoToolsScope(
        picker: picker,
        child: app(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await PhotoFlow.run<String>(
                      context,
                      options: options,
                      pickerOptions: pickerOptions,
                      upload: upload,
                      onRemove: onRemove,
                      customSources: customSources,
                      onBusy: busy.add,
                      errorMessage: errorMessage,
                    );
                  },
                  child: const Text('Change photo'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Change photo'));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, Key row) async {
    await tester.tap(find.byKey(row));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> waitForEditor(WidgetTester tester) =>
      waitFor(tester, () => stagePainter(tester) != null);

  Future<void> saveAndFinish(WidgetTester tester) async {
    await tester.tap(find.byKey(PhotoToolsKeys.save));
    await tester.pump();
    await waitFor(tester, () => result != null);
    await tester.pumpAndSettle();
  }

  testWidgets('device, frame, upload: PhotoSaved with the upload result',
      (tester) async {
    EditedImage? uploaded;
    await start(
      tester,
      upload: (image) async {
        uploaded = image;
        return 'photo-v2';
      },
    );
    await choose(tester, PhotoToolsKeys.sourceDevice);
    await waitForEditor(tester);
    await tester.tap(find.byKey(PhotoToolsKeys.rotate));
    await tester.pump();
    await saveAndFinish(tester);

    final saved = result! as PhotoSaved<String>;
    expect(saved.uploadResult, 'photo-v2');
    expect(saved.image, same(uploaded));
    expect(saved.image.framing.quarterTurns, 1);
    expect(img.decodeJpg(saved.image.bytes)!.width, 128);
    expect(busy, [true, false]);
    expect(picker.deviceCalls, 1);
  });

  testWidgets('staged mode returns the picture and uploads nothing',
      (tester) async {
    await start(tester);
    await choose(tester, PhotoToolsKeys.sourceCamera);
    await waitForEditor(tester);
    await saveAndFinish(tester);

    final saved = result! as PhotoSaved<String>;
    expect(saved.uploadResult, isNull);
    expect(saved.image.width, 128);
    expect(picker.cameraCalls, 1);
    expect(busy, isEmpty);
  });

  testWidgets('passes the picker options through', (tester) async {
    await start(tester, pickerOptions: const PickerOptions(maxDimension: 900));
    await choose(tester, PhotoToolsKeys.sourceDevice);
    expect(picker.lastOptions?.maxDimension, 900);
  });

  group('cancel at each step', () {
    testWidgets('the sheet', (tester) async {
      await start(tester, upload: (_) async => 'x');
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(result, const PhotoCancelled<String>());
    });

    testWidgets('the picker', (tester) async {
      picker.devicePick = const PickCancelled();
      await start(tester, upload: (_) async => 'x');
      await choose(tester, PhotoToolsKeys.sourceDevice);
      await tester.pumpAndSettle();
      expect(result, isA<PhotoCancelled<String>>());
    });

    testWidgets('the editor', (tester) async {
      var uploads = 0;
      await start(tester, upload: (_) async => '${uploads++}');
      await choose(tester, PhotoToolsKeys.sourceDevice);
      await waitForEditor(tester);
      await tester.tap(find.byKey(PhotoToolsKeys.cancel));
      await tester.pumpAndSettle();
      expect(result, isA<PhotoCancelled<String>>());
      expect(uploads, 0);
    });
  });

  testWidgets('an upload error gives PhotoFailed with errorMessage text',
      (tester) async {
    await start(
      tester,
      upload: (_) async => throw StateError('413'),
      errorMessage: (e) => 'Server said: $e',
    );
    await choose(tester, PhotoToolsKeys.sourceDevice);
    await waitForEditor(tester);
    await saveAndFinish(tester);

    final failed = result! as PhotoFailed<String>;
    expect(failed.message, 'Server said: Bad state: 413');
    expect(failed.error, isA<StateError>());
    expect(busy, [true, false]);
  });

  testWidgets('an upload error without errorMessage uses the strings',
      (tester) async {
    await start(tester, upload: (_) async => throw Exception('nope'));
    await choose(tester, PhotoToolsKeys.sourceDevice);
    await waitForEditor(tester);
    await saveAndFinish(tester);
    expect(
      (result! as PhotoFailed<String>).message,
      const PhotoToolsStrings().uploadFailed,
    );
  });

  testWidgets('a refused file gives PhotoFailed with the strings text',
      (tester) async {
    picker.devicePick = const PickRefused(ImageValidationError.tooLarge(9, 5));
    await start(tester, upload: (_) async => 'x');
    await choose(tester, PhotoToolsKeys.sourceDevice);
    await tester.pumpAndSettle();
    final failed = result! as PhotoFailed<String>;
    expect(failed.message, startsWith('That picture is larger than'));
    expect(failed.error, isA<ImageTooLargeError>());
  });

  testWidgets('camera denied gives PhotoFailed with the strings text',
      (tester) async {
    picker.cameraPick = const CameraDenied();
    await start(tester, upload: (_) async => 'x');
    await choose(tester, PhotoToolsKeys.sourceCamera);
    await tester.pumpAndSettle();
    expect(
      (result! as PhotoFailed<String>).message,
      const PhotoToolsStrings().cameraDenied,
    );
  });

  testWidgets('a picker that throws gives PhotoFailed', (tester) async {
    picker = _ThrowingPicker();
    await start(tester, upload: (_) async => 'x');
    await choose(tester, PhotoToolsKeys.sourceDevice);
    await tester.pumpAndSettle();
    expect(
      (result! as PhotoFailed<String>).message,
      const PhotoToolsStrings().sourceFailed,
    );
  });

  group('remove', () {
    testWidgets('confirmed remove calls onRemove: PhotoRemoved',
        (tester) async {
      var removed = 0;
      await start(tester, onRemove: () async => removed++);
      await tester.tap(find.byKey(PhotoToolsKeys.sourceRemove));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(removed, 1);
      expect(result, const PhotoRemoved<String>());
      expect(busy, [true, false]);
    });

    testWidgets('a failing remove gives PhotoFailed', (tester) async {
      await start(tester, onRemove: () async => throw Exception('x'));
      await tester.tap(find.byKey(PhotoToolsKeys.sourceRemove));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(
        (result! as PhotoFailed<String>).message,
        const PhotoToolsStrings().removeFailed,
      );
    });
  });

  group('custom sources', () {
    CustomPhotoSource source(Future<Uint8List?> Function() load) =>
        CustomPhotoSource(
          id: 'google',
          icon: Icons.cloud_outlined,
          label: 'Use Google picture',
          load: load,
        );

    testWidgets('loads, frames and uploads', (tester) async {
      await start(
        tester,
        customSources: [source(() async => TestImages.asymmetricPng())],
        upload: (_) async => 'ok',
      );
      await choose(tester, PhotoToolsKeys.sourceCustom('google'));
      await waitForEditor(tester);
      await saveAndFinish(tester);
      expect((result! as PhotoSaved<String>).uploadResult, 'ok');
      expect(busy, [true, false, true, false]);
    });

    testWidgets('null bytes are a cancel', (tester) async {
      await start(tester, customSources: [source(() async => null)]);
      await choose(tester, PhotoToolsKeys.sourceCustom('google'));
      await tester.pumpAndSettle();
      expect(result, isA<PhotoCancelled<String>>());
    });

    testWidgets('a load error gives PhotoFailed', (tester) async {
      await start(
        tester,
        customSources: [source(() async => throw Exception('offline'))],
      );
      await choose(tester, PhotoToolsKeys.sourceCustom('google'));
      await tester.pumpAndSettle();
      expect(
        (result! as PhotoFailed<String>).message,
        const PhotoToolsStrings().sourceFailed,
      );
    });

    testWidgets('bytes the rules refuse give PhotoFailed', (tester) async {
      await start(
        tester,
        customSources: [
          source(() async => Uint8List.fromList('%PDF'.codeUnits)),
        ],
      );
      await choose(tester, PhotoToolsKeys.sourceCustom('google'));
      await tester.pumpAndSettle();
      final failed = result! as PhotoFailed<String>;
      expect(failed.error, isA<UnsupportedImageFormatError>());
    });
  });

  test('results describe themselves', () {
    final image = EditedImage(
      bytes: Uint8List(1),
      width: 1,
      height: 1,
      format: ImageFormat.png,
    );
    expect(PhotoSaved<int>(image, 3).toString(), contains('3'));
    expect(const PhotoRemoved<int>().toString(), 'PhotoRemoved()');
    expect(
        const PhotoRemoved<int>().hashCode, const PhotoRemoved<int>().hashCode);
    expect(const PhotoCancelled<int>().toString(), 'PhotoCancelled()');
    expect(const PhotoCancelled<int>().hashCode,
        const PhotoCancelled<int>().hashCode);
    expect(const PhotoFailed<int>('m', 1).toString(), 'PhotoFailed(m, 1)');
  });
}

class _ThrowingPicker extends FakePhotoSourcePicker {
  @override
  Future<PickResult> pickFromDevice([
    PickerOptions options = const PickerOptions(),
  ]) =>
      throw Exception('plugin crashed');
}
