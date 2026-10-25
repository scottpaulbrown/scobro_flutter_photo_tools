import 'package:flutter/foundation.dart';

import '../core/image_format.dart';
import '../core/image_validator.dart';

/// A picture the user chose, already checked against the picker's
/// `ValidationRules`, before it is framed.
@immutable
class PickedImage {
  /// Creates a [PickedImage].
  const PickedImage({
    required this.name,
    required this.bytes,
    required this.format,
  });

  /// The file name the platform reported, for example `IMG_0042.jpg`.
  final String name;

  /// The picture's encoded bytes.
  final Uint8List bytes;

  /// The format sniffed from [bytes].
  final ImageFormat format;

  @override
  String toString() =>
      'PickedImage($name, ${format.name}, ${bytes.length} bytes)';
}

/// What choosing a picture came to.
@immutable
sealed class PickResult {
  const PickResult();
}

/// A picture was chosen and passed the checks.
final class Picked extends PickResult {
  /// Creates a [Picked].
  const Picked(this.image);

  /// The chosen picture.
  final PickedImage image;

  @override
  String toString() => 'Picked($image)';
}

/// The user backed out of the picker.
final class PickCancelled extends PickResult {
  /// Creates a [PickCancelled].
  const PickCancelled();

  @override
  bool operator ==(Object other) => other is PickCancelled;

  @override
  int get hashCode => (PickCancelled).hashCode;

  @override
  String toString() => 'PickCancelled()';
}

/// A file was chosen but can't be used; [error] says why.
final class PickRefused extends PickResult {
  /// Creates a [PickRefused].
  const PickRefused(this.error);

  /// Why the file was refused.
  final ImageValidationError error;

  @override
  bool operator ==(Object other) =>
      other is PickRefused && other.error == error;

  @override
  int get hashCode => Object.hash(PickRefused, error);

  @override
  String toString() => 'PickRefused($error)';
}

/// The app may not use the camera (the user denied access).
final class CameraDenied extends PickResult {
  /// Creates a [CameraDenied].
  const CameraDenied();

  @override
  bool operator ==(Object other) => other is CameraDenied;

  @override
  int get hashCode => (CameraDenied).hashCode;

  @override
  String toString() => 'CameraDenied()';
}
