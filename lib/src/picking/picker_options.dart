import 'package:flutter/foundation.dart';

import '../core/image_validator.dart';

/// How a [PhotoSourcePicker] picks.
@immutable
class PickerOptions {
  /// Creates [PickerOptions].
  const PickerOptions({
    this.maxDimension = 4096,
    this.validation = const ValidationRules(),
  }) : assert(
          maxDimension == null || maxDimension > 0,
          'maxDimension must be positive',
        );

  /// The longest edge, in pixels, that the platform picker is asked to
  /// downscale to, so a 48 MP camera shot isn't decoded at full size. Null
  /// keeps the original size.
  ///
  /// Applies to the camera and the Android/iOS photo gallery; desktop and web
  /// file pickers return files unchanged.
  final int? maxDimension;

  /// What a picked file must satisfy; anything else comes back as a
  /// `PickRefused`.
  final ValidationRules validation;

  @override
  bool operator ==(Object other) =>
      other is PickerOptions &&
      other.maxDimension == maxDimension &&
      other.validation == validation;

  @override
  int get hashCode => Object.hash(maxDimension, validation);
}
