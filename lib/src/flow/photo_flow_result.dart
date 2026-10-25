import 'package:flutter/foundation.dart';

import '../core/edited_image.dart';

/// How `PhotoFlow.run` ended. [T] is what the app's upload callback returns.
@immutable
sealed class PhotoFlowResult<T> {
  const PhotoFlowResult();
}

/// A picture was framed and, when an upload callback was given, uploaded.
final class PhotoSaved<T> extends PhotoFlowResult<T> {
  /// Creates a [PhotoSaved].
  const PhotoSaved(this.image, [this.uploadResult]);

  /// The framed picture.
  final EditedImage image;

  /// What the upload callback returned; null in staged mode (no callback).
  final T? uploadResult;

  @override
  String toString() => 'PhotoSaved($image, $uploadResult)';
}

/// The user chose Remove photo and the remove callback finished.
final class PhotoRemoved<T> extends PhotoFlowResult<T> {
  /// Creates a [PhotoRemoved].
  const PhotoRemoved();

  @override
  bool operator ==(Object other) => other is PhotoRemoved;

  @override
  int get hashCode => (PhotoRemoved).hashCode;

  @override
  String toString() => 'PhotoRemoved()';
}

/// The user backed out at some step; nothing changed.
final class PhotoCancelled<T> extends PhotoFlowResult<T> {
  /// Creates a [PhotoCancelled].
  const PhotoCancelled();

  @override
  bool operator ==(Object other) => other is PhotoCancelled;

  @override
  int get hashCode => (PhotoCancelled).hashCode;

  @override
  String toString() => 'PhotoCancelled()';
}

/// Something went wrong. [message] is ready to show the user; [error] is the
/// underlying exception or validation error, when there is one.
///
/// `PhotoFlow` never shows it itself: show it where it fits your app, for
/// example in a snack bar once the sheet has closed.
final class PhotoFailed<T> extends PhotoFlowResult<T> {
  /// Creates a [PhotoFailed].
  const PhotoFailed(this.message, [this.error]);

  /// Text for the user.
  final String message;

  /// The cause: an exception, an `ImageValidationError`, or null.
  final Object? error;

  @override
  String toString() => 'PhotoFailed($message, $error)';
}
