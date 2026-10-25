import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';

/// Stands in for your backend: stores uploaded photos with a version that
/// changes on every upload, and can be told to fail uploads.
///
/// In a real app these would be calls through Dio, `http` or Firebase
/// Storage; see doc/upload-recipes.md.
class FakePhotoServer {
  /// Creates a [FakePhotoServer]; [latency] delays every call.
  FakePhotoServer({this.latency = const Duration(milliseconds: 700)});

  /// How long each call takes.
  final Duration latency;

  /// When true, every upload throws.
  bool failUploads = false;

  final _photos = <String, (Uint8List, int)>{};

  /// How many times [fetch] ran, to show the loader's cache at work.
  int fetchCount = 0;

  /// What the last upload received.
  EditedImage? lastUpload;

  /// The current version of [id]'s photo; null when there is none.
  String? versionOf(String id) => _photos[id]?.$2.toString();

  /// Stores [image] as [id]'s photo and returns the new version.
  Future<String> upload(String id, EditedImage image) async {
    await Future<void>.delayed(latency);
    if (failUploads) {
      throw const FakeServerException('The server is having a bad day (503).');
    }
    final version = (_photos[id]?.$2 ?? 0) + 1;
    _photos[id] = (image.bytes, version);
    lastUpload = image;
    return version.toString();
  }

  /// Removes [id]'s photo.
  Future<void> remove(String id) async {
    await Future<void>.delayed(latency);
    _photos.remove(id);
  }

  /// The bytes of [id]'s photo at [version], or null.
  Future<Uint8List?> fetch(String id, String version) async {
    fetchCount++;
    await Future<void>.delayed(latency);
    final stored = _photos[id];
    if (stored == null || stored.$2.toString() != version) return null;
    return stored.$1;
  }

  /// Gives [ids] generated photos, so the loader demo has something to show.
  Future<void> seed(List<String> ids) async {
    for (final (i, id) in ids.indexed) {
      _photos[id] = (await samplePicture(seed: i), 1);
    }
  }

  /// Bumps every stored photo's version, as if each were replaced.
  void bumpVersions() {
    for (final id in _photos.keys.toList()) {
      final (bytes, version) = _photos[id]!;
      _photos[id] = (bytes, version + 1);
    }
  }
}

/// A failure from [FakePhotoServer].
class FakeServerException implements Exception {
  /// Creates a [FakeServerException].
  const FakeServerException(this.message);

  /// What went wrong.
  final String message;

  @override
  String toString() => message;
}

/// A generated 640 x 480 PNG: soft bands of colour with a sun, different for
/// each [seed]. Used as a custom photo source and to seed the server.
Future<Uint8List> samplePicture({int seed = 0}) async {
  const width = 640.0;
  const height = 480.0;
  final palettes = [
    [const Color(0xFFF4A261), const Color(0xFFE76F51), const Color(0xFF264653)],
    [const Color(0xFF8ECAE6), const Color(0xFF219EBC), const Color(0xFF023047)],
    [const Color(0xFFCDB4DB), const Color(0xFFFFAFCC), const Color(0xFF3A3042)],
    [const Color(0xFFB7E4C7), const Color(0xFF52B788), const Color(0xFF1B4332)],
  ];
  final colors = palettes[seed % palettes.length];
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, width, height),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(0, height),
        [colors[0], colors[1]],
      ),
  );
  final random = math.Random(seed);
  canvas.drawCircle(
    Offset(160 + random.nextDouble() * 320, 150 + random.nextDouble() * 60),
    70,
    Paint()..color = const Color(0xFFFFF3B0),
  );
  for (var i = 0; i < 3; i++) {
    final path = Path()..moveTo(0, height);
    for (var x = 0.0; x <= width; x += 40) {
      path.lineTo(
        x,
        300 + i * 50 + math.sin(x / 90 + seed + i) * 30,
      );
    }
    path
      ..lineTo(width, height)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = colors[2].withValues(alpha: 0.45 + i * 0.25),
    );
  }
  final image =
      await recorder.endRecording().toImage(width.toInt(), height.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}
