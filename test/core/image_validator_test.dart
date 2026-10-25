import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

void main() {
  final jpeg = TestImages.plainJpeg();
  final pdf = Uint8List.fromList('%PDF-1.7 and more bytes'.codeUnits);

  test('JPEG and PNG pass the default rules', () {
    expect(ImageValidator.check(jpeg), isNull);
    expect(ImageValidator.check(TestImages.asymmetricPng()), isNull);
  });

  test('empty bytes are refused first', () {
    expect(
      ImageValidator.check(Uint8List(0)),
      const ImageValidationError.empty(),
    );
  });

  test('an unreadable format is refused with no format found', () {
    expect(
      ImageValidator.check(pdf),
      const ImageValidationError.unsupportedFormat(null),
    );
  });

  test('a readable format the rules exclude is refused with its format', () {
    const rules = ValidationRules(allowedFormats: [ImageFormat.jpeg]);
    final error = ImageValidator.check(TestImages.asymmetricPng(), rules);
    expect(error, isA<UnsupportedImageFormatError>());
    expect((error! as UnsupportedImageFormatError).found, ImageFormat.png);
    expect(ImageValidator.check(jpeg, rules), isNull);
  });

  group('size limit', () {
    test('exactly the limit is accepted', () {
      expect(
        ImageValidator.check(jpeg, ValidationRules(maxBytes: jpeg.length)),
        isNull,
      );
    });

    test('one byte over is refused', () {
      final rules = ValidationRules(maxBytes: jpeg.length - 1);
      expect(
        ImageValidator.check(jpeg, rules),
        ImageValidationError.tooLarge(jpeg.length, jpeg.length - 1),
      );
    });

    test('null means no limit', () {
      final big = Uint8List(20 * 1024 * 1024)..setAll(0, [0xFF, 0xD8, 0xFF]);
      expect(ImageValidator.check(big), isNull);
    });

    test('format is checked before size', () {
      expect(
        ImageValidator.check(pdf, const ValidationRules(maxBytes: 1)),
        isA<UnsupportedImageFormatError>(),
      );
    });
  });

  test('errors compare by value and describe themselves', () {
    expect(const EmptyImageError(), const EmptyImageError());
    expect(const EmptyImageError().hashCode, const EmptyImageError().hashCode);
    expect(const EmptyImageError().toString(), contains('empty'));

    expect(
      const UnsupportedImageFormatError(ImageFormat.png),
      const UnsupportedImageFormatError(ImageFormat.png),
    );
    expect(
      const UnsupportedImageFormatError(ImageFormat.png),
      isNot(const UnsupportedImageFormatError(null)),
    );
    expect(
      const UnsupportedImageFormatError(null).hashCode,
      const UnsupportedImageFormatError(null).hashCode,
    );
    expect(
      const UnsupportedImageFormatError(ImageFormat.png).toString(),
      contains('png'),
    );

    expect(const ImageTooLargeError(5, 4), const ImageTooLargeError(5, 4));
    expect(
      const ImageTooLargeError(5, 4),
      isNot(const ImageTooLargeError(6, 4)),
    );
    expect(
      const ImageTooLargeError(5, 4).hashCode,
      const ImageTooLargeError(5, 4).hashCode,
    );
    expect(const ImageTooLargeError(5, 4).toString(), contains('5, 4'));
  });

  test('rules compare by value', () {
    expect(const ValidationRules(), const ValidationRules());
    expect(const ValidationRules().hashCode, const ValidationRules().hashCode);
    expect(const ValidationRules(maxBytes: 1), isNot(const ValidationRules()));
    expect(
      const ValidationRules(allowedFormats: [ImageFormat.png]),
      isNot(const ValidationRules()),
    );
  });
}
