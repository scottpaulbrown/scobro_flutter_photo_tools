import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Encodes straight (not premultiplied) RGBA pixels as a JPEG.
///
/// On the web this uses the browser's own encoder (`canvas.toBlob`), which is
/// native and far faster than encoding in Dart. The result carries no EXIF.
Future<Uint8List> encodeJpegRgba(
  Uint8List rgba,
  int width,
  int height,
  int quality,
) async {
  final canvas = web.HTMLCanvasElement()
    ..width = width
    ..height = height;
  final context = canvas.getContext('2d')! as web.CanvasRenderingContext2D;
  final pixels = Uint8ClampedList.sublistView(rgba);
  context.putImageData(web.ImageData(pixels.toJS, width, height.toJS), 0, 0);
  final blob = Completer<web.Blob?>();
  canvas.toBlob(
    ((web.Blob? b) => blob.complete(b)).toJS,
    'image/jpeg',
    (quality / 100).toJS,
  );
  final encoded = await blob.future;
  if (encoded == null) {
    throw StateError('The browser could not encode the picture.');
  }
  return (await encoded.arrayBuffer().toDart).toDart.asUint8List();
}
