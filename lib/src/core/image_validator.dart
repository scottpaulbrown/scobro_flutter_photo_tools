import 'package:flutter/foundation.dart';

import 'image_format.dart';

/// Why a picture was refused by [ImageValidator.check].
///
/// Turn one into text for the user with `PhotoToolsStrings.validationMessage`.
@immutable
sealed class ImageValidationError {
  const ImageValidationError();

  /// The file has no bytes at all.
  const factory ImageValidationError.empty() = EmptyImageError;

  /// The file isn't one of the allowed formats. [found] is its format when it
  /// is a JPEG, PNG or WebP that the rules don't allow, and null when it isn't
  /// a picture the package can read (HEIC, PDF, ...).
  const factory ImageValidationError.unsupportedFormat(ImageFormat? found) =
      UnsupportedImageFormatError;

  /// The file is [bytes] long, more than the [maxBytes] the rules allow.
  const factory ImageValidationError.tooLarge(int bytes, int maxBytes) =
      ImageTooLargeError;
}

/// The file has no bytes at all.
final class EmptyImageError extends ImageValidationError {
  /// Creates an [EmptyImageError].
  const EmptyImageError();

  @override
  bool operator ==(Object other) => other is EmptyImageError;

  @override
  int get hashCode => (EmptyImageError).hashCode;

  @override
  String toString() => 'ImageValidationError.empty()';
}

/// The file isn't one of the allowed formats.
final class UnsupportedImageFormatError extends ImageValidationError {
  /// Creates an [UnsupportedImageFormatError].
  const UnsupportedImageFormatError(this.found);

  /// The file's format when it is a readable picture the rules don't allow;
  /// null when it isn't a JPEG, PNG or WebP at all.
  final ImageFormat? found;

  @override
  bool operator ==(Object other) =>
      other is UnsupportedImageFormatError && other.found == found;

  @override
  int get hashCode => Object.hash(UnsupportedImageFormatError, found);

  @override
  String toString() => 'ImageValidationError.unsupportedFormat($found)';
}

/// The file is larger than the rules allow.
final class ImageTooLargeError extends ImageValidationError {
  /// Creates an [ImageTooLargeError].
  const ImageTooLargeError(this.bytes, this.maxBytes);

  /// The file's size in bytes.
  final int bytes;

  /// The largest size allowed, in bytes (inclusive).
  final int maxBytes;

  @override
  bool operator ==(Object other) =>
      other is ImageTooLargeError &&
      other.bytes == bytes &&
      other.maxBytes == maxBytes;

  @override
  int get hashCode => Object.hash(ImageTooLargeError, bytes, maxBytes);

  @override
  String toString() => 'ImageValidationError.tooLarge($bytes, $maxBytes)';
}

/// What [ImageValidator.check] accepts.
@immutable
class ValidationRules {
  /// Creates [ValidationRules]. By default every [ImageFormat] is allowed and
  /// there is no size limit.
  const ValidationRules({
    this.allowedFormats = ImageFormat.values,
    this.maxBytes,
  }) : assert(maxBytes == null || maxBytes > 0, 'maxBytes must be positive');

  /// The formats that are accepted.
  final List<ImageFormat> allowedFormats;

  /// The largest accepted file size in bytes (inclusive); null for no limit.
  final int? maxBytes;

  @override
  bool operator ==(Object other) =>
      other is ValidationRules &&
      other.maxBytes == maxBytes &&
      listEquals(other.allowedFormats, allowedFormats);

  @override
  int get hashCode => Object.hash(Object.hashAll(allowedFormats), maxBytes);
}

/// Checks a chosen picture before it is framed or sent, so an unusable file is
/// refused early. Servers should still check again.
abstract final class ImageValidator {
  /// Null when [bytes] satisfy [rules], otherwise why they don't.
  ///
  /// Checks run in this order: empty, format, size.
  static ImageValidationError? check(
    Uint8List bytes, [
    ValidationRules rules = const ValidationRules(),
  ]) {
    if (bytes.isEmpty) return const ImageValidationError.empty();
    final format = detectImageFormat(bytes);
    if (format == null || !rules.allowedFormats.contains(format)) {
      return ImageValidationError.unsupportedFormat(format);
    }
    final max = rules.maxBytes;
    if (max != null && bytes.length > max) {
      return ImageValidationError.tooLarge(bytes.length, max);
    }
    return null;
  }
}
