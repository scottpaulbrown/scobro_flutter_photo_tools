import 'package:flutter/foundation.dart';

import '../core/image_validator.dart';

/// Every piece of text the package shows, with English defaults.
///
/// Set your own once with `PhotoToolsScope(strings: ...)`, or pass them to a
/// single widget. Override the plain texts through the constructor or
/// [copyWith]; for the texts that depend on a value ([validationMessage],
/// [zoomValue], [removeConfirmTitle], [megabytes]), extend this class and
/// override the method:
///
/// ```dart
/// class FrenchPhotoStrings extends PhotoToolsStrings {
///   const FrenchPhotoStrings() : super(save: 'Enregistrer', cancel: 'Annuler');
///
///   @override
///   String zoomValue(double zoom) => 'Zoom ${zoom.toStringAsFixed(1)} fois';
/// }
/// ```
@immutable
class PhotoToolsStrings {
  /// Creates [PhotoToolsStrings]; any text left out keeps its English
  /// default.
  const PhotoToolsStrings({
    this.editorTitle = 'Frame photo',
    this.save = 'Save photo',
    this.cancel = 'Cancel',
    this.close = 'Close',
    this.rotate = 'Rotate',
    this.zoomIn = 'Zoom in',
    this.zoomOut = 'Zoom out',
    this.stageHint =
        'Photo framing area. Drag to move the photo; pinch, scroll or use the '
            'slider to zoom.',
    this.loading = 'Loading photo',
    this.previewsTitle = 'How it will look',
    this.unreadable = 'That picture could not be read.',
    this.chooseAnother = 'Choose another',
    this.renderFailed = 'That photo could not be saved.',
    this.tryAgain = 'Try again',
    this.discardTitle = 'Discard this photo?',
    this.discardMessage = 'The framing you set will be lost.',
    this.keepEditing = 'Keep editing',
    this.discard = 'Discard',
    this.sourceSheetTitle = 'Choose a photo',
    this.fromDevice = 'From this device',
    this.takePhoto = 'Take a photo',
    this.removePhoto = 'Remove photo',
    this.removeMessage = 'The current photo will be removed.',
    this.remove = 'Remove',
    this.cameraDenied =
        'Camera access is turned off. You can turn it on in your device '
            'settings, or choose a picture from this device.',
    this.emptyFile = 'That file is empty.',
    this.unsupportedFormat =
        "That file isn't a supported picture. Use a JPEG, PNG or WebP image.",
    this.sourceFailed = 'That picture could not be loaded.',
    this.uploadFailed = 'The photo could not be saved. Please try again.',
    this.removeFailed = 'The photo could not be removed. Please try again.',
    this.changePhoto = 'Change photo',
  });

  /// The editor page's title.
  final String editorTitle;

  /// The editor's primary action.
  final String save;

  /// The editor's secondary action, and Cancel in confirmation prompts.
  final String cancel;

  /// The editor's close button tooltip.
  final String close;

  /// The rotate button.
  final String rotate;

  /// The zoom-in end of the slider, for screen readers.
  final String zoomIn;

  /// The zoom-out end of the slider, for screen readers.
  final String zoomOut;

  /// What screen readers announce for the framing area.
  final String stageHint;

  /// What screen readers announce while the picture loads.
  final String loading;

  /// The heading above the editor's previews.
  final String previewsTitle;

  /// Shown when the picked picture can't be decoded.
  final String unreadable;

  /// The action next to [unreadable].
  final String chooseAnother;

  /// Shown when rendering the framed picture fails.
  final String renderFailed;

  /// The action next to [renderFailed].
  final String tryAgain;

  /// The title of the prompt shown when leaving the editor after changes.
  final String discardTitle;

  /// The body of the discard prompt.
  final String discardMessage;

  /// The discard prompt's "stay" action.
  final String keepEditing;

  /// The discard prompt's "leave" action.
  final String discard;

  /// The source sheet's default title.
  final String sourceSheetTitle;

  /// The source sheet's device row.
  final String fromDevice;

  /// The source sheet's camera row.
  final String takePhoto;

  /// The source sheet's remove row.
  final String removePhoto;

  /// The body of the remove confirmation.
  final String removeMessage;

  /// The remove confirmation's destructive action.
  final String remove;

  /// Shown when the user has denied camera access.
  final String cameraDenied;

  /// Shown for [EmptyImageError].
  final String emptyFile;

  /// Shown for [UnsupportedImageFormatError].
  final String unsupportedFormat;

  /// Shown when a custom source fails to load its picture.
  final String sourceFailed;

  /// Shown when the app's upload callback throws and no `errorMessage`
  /// callback turns the error into text.
  final String uploadFailed;

  /// Shown when the app's remove callback throws and no `errorMessage`
  /// callback turns the error into text.
  final String removeFailed;

  /// The tooltip and screen-reader label of `ChangePhotoBadge`.
  final String changePhoto;

  /// The text for a refused file.
  String validationMessage(ImageValidationError error) => switch (error) {
        EmptyImageError() => emptyFile,
        UnsupportedImageFormatError() => unsupportedFormat,
        ImageTooLargeError(:final maxBytes) =>
          'That picture is larger than ${megabytes(maxBytes)}.',
      };

  /// A byte count as megabytes, for example `5 MB` or `2.5 MB`.
  String megabytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    final text = mb == mb.roundToDouble()
        ? mb.round().toString()
        : mb.toStringAsFixed(1);
    return '$text MB';
  }

  /// What screen readers announce for the zoom slider's value.
  String zoomValue(double zoom) => 'Zoom ${zoom.toStringAsFixed(1)} times';

  /// The title of the remove confirmation; [name] is whose photo it is, when
  /// the app passes one.
  String removeConfirmTitle(String? name) =>
      name == null ? 'Remove this photo?' : "Remove $name's photo?";

  /// A copy with the given texts replaced.
  PhotoToolsStrings copyWith({
    String? editorTitle,
    String? save,
    String? cancel,
    String? close,
    String? rotate,
    String? zoomIn,
    String? zoomOut,
    String? stageHint,
    String? loading,
    String? previewsTitle,
    String? unreadable,
    String? chooseAnother,
    String? renderFailed,
    String? tryAgain,
    String? discardTitle,
    String? discardMessage,
    String? keepEditing,
    String? discard,
    String? sourceSheetTitle,
    String? fromDevice,
    String? takePhoto,
    String? removePhoto,
    String? removeMessage,
    String? remove,
    String? cameraDenied,
    String? emptyFile,
    String? unsupportedFormat,
    String? sourceFailed,
    String? uploadFailed,
    String? removeFailed,
    String? changePhoto,
  }) =>
      PhotoToolsStrings(
        editorTitle: editorTitle ?? this.editorTitle,
        save: save ?? this.save,
        cancel: cancel ?? this.cancel,
        close: close ?? this.close,
        rotate: rotate ?? this.rotate,
        zoomIn: zoomIn ?? this.zoomIn,
        zoomOut: zoomOut ?? this.zoomOut,
        stageHint: stageHint ?? this.stageHint,
        loading: loading ?? this.loading,
        previewsTitle: previewsTitle ?? this.previewsTitle,
        unreadable: unreadable ?? this.unreadable,
        chooseAnother: chooseAnother ?? this.chooseAnother,
        renderFailed: renderFailed ?? this.renderFailed,
        tryAgain: tryAgain ?? this.tryAgain,
        discardTitle: discardTitle ?? this.discardTitle,
        discardMessage: discardMessage ?? this.discardMessage,
        keepEditing: keepEditing ?? this.keepEditing,
        discard: discard ?? this.discard,
        sourceSheetTitle: sourceSheetTitle ?? this.sourceSheetTitle,
        fromDevice: fromDevice ?? this.fromDevice,
        takePhoto: takePhoto ?? this.takePhoto,
        removePhoto: removePhoto ?? this.removePhoto,
        removeMessage: removeMessage ?? this.removeMessage,
        remove: remove ?? this.remove,
        cameraDenied: cameraDenied ?? this.cameraDenied,
        emptyFile: emptyFile ?? this.emptyFile,
        unsupportedFormat: unsupportedFormat ?? this.unsupportedFormat,
        sourceFailed: sourceFailed ?? this.sourceFailed,
        uploadFailed: uploadFailed ?? this.uploadFailed,
        removeFailed: removeFailed ?? this.removeFailed,
        changePhoto: changePhoto ?? this.changePhoto,
      );
}
