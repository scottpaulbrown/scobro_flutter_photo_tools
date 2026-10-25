import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';

void main() {
  test('carries what an upload needs', () {
    final image = EditedImage(
      bytes: Uint8List.fromList([1, 2, 3]),
      width: 40,
      height: 30,
      format: ImageFormat.jpeg,
    );
    expect(image.mimeType, 'image/jpeg');
    expect(image.fileExtension, 'jpg');
    expect(image.suggestedFileName(), 'photo.jpg');
    expect(image.suggestedFileName('avatar'), 'avatar.jpg');
    expect(image.framing, const PhotoFraming());
    expect(image.toString(), contains('40x30'));
    expect(image.toString(), contains('3 bytes'));
  });

  test('PNG', () {
    final image = EditedImage(
      bytes: Uint8List(0),
      width: 1,
      height: 1,
      format: ImageFormat.png,
      framing: const PhotoFraming(quarterTurns: 2),
    );
    expect(image.mimeType, 'image/png');
    expect(image.suggestedFileName('banner'), 'banner.png');
    expect(image.framing.quarterTurns, 2);
  });
}
