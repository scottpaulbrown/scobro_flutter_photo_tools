import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// An extra row in the photo source sheet that loads a picture its own way,
/// for example "Use Google picture" or "Choose from library".
@immutable
class CustomPhotoSource {
  /// Creates a [CustomPhotoSource].
  const CustomPhotoSource({
    required this.id,
    required this.icon,
    required this.label,
    required this.load,
  });

  /// A stable id, used for the row's key (`PhotoToolsKeys.sourceCustom(id)`).
  final String id;

  /// The row's icon.
  final IconData icon;

  /// The row's text.
  final String label;

  /// Fetches the picture's bytes; null means the user backed out. A thrown
  /// error ends `PhotoFlow.run` with `PhotoFailed`.
  final Future<Uint8List?> Function() load;
}
