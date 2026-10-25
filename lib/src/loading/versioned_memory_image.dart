import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'versioned_image_loader.dart';

/// An [ImageProvider] for the photo [id] at [version], loaded through a
/// [VersionedImageLoader].
///
/// Fails (so `Image.errorBuilder` runs) when the loader has no photo.
@immutable
class VersionedMemoryImage extends ImageProvider<VersionedMemoryImage> {
  /// Creates a [VersionedMemoryImage].
  const VersionedMemoryImage(this.loader, this.id, this.version,
      {this.scale = 1});

  /// Where the bytes come from.
  final VersionedImageLoader loader;

  /// The photo's id.
  final String id;

  /// The photo's version.
  final String version;

  /// The image's scale.
  final double scale;

  @override
  Future<VersionedMemoryImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<VersionedMemoryImage>(this);

  @override
  ImageStreamCompleter loadImage(
    VersionedMemoryImage key,
    ImageDecoderCallback decode,
  ) =>
      MultiFrameImageStreamCompleter(
        codec: _load(decode),
        scale: scale,
        debugLabel: 'VersionedMemoryImage($id, $version)',
      );

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final bytes = await loader.load(id, version);
    if (bytes == null) {
      throw StateError('No photo for $id at version $version.');
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is VersionedMemoryImage &&
      identical(other.loader, loader) &&
      other.id == id &&
      other.version == version &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(identityHashCode(loader), id, version, scale);

  @override
  String toString() => 'VersionedMemoryImage($id, $version, scale: $scale)';
}
