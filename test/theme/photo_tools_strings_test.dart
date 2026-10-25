import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';

class _Shouty extends PhotoToolsStrings {
  const _Shouty() : super(save: 'SAVE');

  @override
  String zoomValue(double zoom) => 'ZOOM $zoom';
}

void main() {
  const strings = PhotoToolsStrings();

  test('English defaults', () {
    // ignore: prefer_const_constructors
    expect(PhotoToolsStrings().close, 'Close');
    expect(strings.editorTitle, 'Frame photo');
    expect(strings.save, 'Save photo');
    expect(strings.cancel, 'Cancel');
    expect(strings.rotate, 'Rotate');
    expect(strings.discardTitle, 'Discard this photo?');
    expect(strings.fromDevice, 'From this device');
    expect(strings.takePhoto, 'Take a photo');
    expect(strings.cameraDenied, contains('Camera access is turned off'));
  });

  test('validation messages', () {
    expect(
      strings.validationMessage(const ImageValidationError.empty()),
      strings.emptyFile,
    );
    expect(
      strings.validationMessage(
        const ImageValidationError.unsupportedFormat(null),
      ),
      contains('JPEG, PNG or WebP'),
    );
    expect(
      strings.validationMessage(
        const ImageValidationError.tooLarge(6000000, 5242880),
      ),
      'That picture is larger than 5 MB.',
    );
    expect(
      strings.validationMessage(
        const ImageValidationError.tooLarge(3000000, 2621440),
      ),
      'That picture is larger than 2.5 MB.',
    );
  });

  test('value-dependent texts', () {
    expect(strings.zoomValue(1.25), 'Zoom 1.3 times');
    expect(strings.removeConfirmTitle(null), 'Remove this photo?');
    expect(strings.removeConfirmTitle('Sam'), "Remove Sam's photo?");
  });

  test('copyWith replaces only what is given', () {
    final all = strings.copyWith(
      editorTitle: '1',
      save: '2',
      cancel: '3',
      close: '4',
      rotate: '5',
      zoomIn: '6',
      zoomOut: '7',
      stageHint: '8',
      loading: '9',
      previewsTitle: '10',
      unreadable: '11',
      chooseAnother: '12',
      renderFailed: '13',
      tryAgain: '14',
      discardTitle: '15',
      discardMessage: '16',
      keepEditing: '17',
      discard: '18',
      sourceSheetTitle: '19',
      fromDevice: '20',
      takePhoto: '21',
      removePhoto: '22',
      removeMessage: '23',
      remove: '24',
      cameraDenied: '25',
      emptyFile: '26',
      unsupportedFormat: '27',
      sourceFailed: '28',
      uploadFailed: '29',
      changePhoto: '30',
      removeFailed: '31',
    );
    expect(
      [
        all.editorTitle,
        all.save,
        all.cancel,
        all.close,
        all.rotate,
        all.zoomIn,
        all.zoomOut,
        all.stageHint,
        all.loading,
        all.previewsTitle,
        all.unreadable,
        all.chooseAnother,
        all.renderFailed,
        all.tryAgain,
        all.discardTitle,
        all.discardMessage,
        all.keepEditing,
        all.discard,
        all.sourceSheetTitle,
        all.fromDevice,
        all.takePhoto,
        all.removePhoto,
        all.removeMessage,
        all.remove,
        all.cameraDenied,
        all.emptyFile,
        all.unsupportedFormat,
        all.sourceFailed,
        all.uploadFailed,
        all.changePhoto,
        all.removeFailed,
      ],
      [for (var i = 1; i <= 31; i++) '$i'],
    );
    final one = strings.copyWith(save: 'Keep');
    expect(one.save, 'Keep');
    expect(one.cancel, strings.cancel);
  });

  test('subclasses override value-dependent texts', () {
    const s = _Shouty();
    expect(s.save, 'SAVE');
    expect(s.zoomValue(2), 'ZOOM 2.0');
    expect(s.cancel, 'Cancel');
  });
}
