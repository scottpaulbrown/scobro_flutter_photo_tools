import 'package:flutter/material.dart';

import '../photo_tools_keys.dart';
import '../picking/photo_source_picker.dart';
import '../theme/photo_tools_scope.dart';
import '../theme/photo_tools_strings.dart';
import 'adaptive_sheet.dart';
import 'custom_photo_source.dart';

/// What the user picked in the photo source sheet.
@immutable
sealed class PhotoSourceChoice {
  const PhotoSourceChoice();

  /// "From this device".
  static const PhotoSourceChoice device = DeviceSourceChoice();

  /// "Take a photo".
  static const PhotoSourceChoice camera = CameraSourceChoice();

  /// "Remove photo", already confirmed.
  static const PhotoSourceChoice remove = RemoveSourceChoice();
}

/// "From this device".
final class DeviceSourceChoice extends PhotoSourceChoice {
  /// Creates a [DeviceSourceChoice].
  const DeviceSourceChoice();
}

/// "Take a photo".
final class CameraSourceChoice extends PhotoSourceChoice {
  /// Creates a [CameraSourceChoice].
  const CameraSourceChoice();
}

/// One of the app's [CustomPhotoSource]s.
final class CustomSourceChoice extends PhotoSourceChoice {
  /// Creates a [CustomSourceChoice].
  const CustomSourceChoice(this.source);

  /// The chosen source.
  final CustomPhotoSource source;
}

/// "Remove photo", already confirmed by the user.
final class RemoveSourceChoice extends PhotoSourceChoice {
  /// Creates a [RemoveSourceChoice].
  const RemoveSourceChoice();
}

/// Asks where the picture should come from: a bottom sheet on phones, a
/// 480 px dialog on larger screens. Resolves to the choice, or null when
/// dismissed.
///
/// Rows, in order: From this device; Take a photo (when [allowCamera] and the
/// [picker] can take one); each of [customSources]; and, when [showRemove],
/// Remove photo, which asks for confirmation first ([removeConfirmName] names
/// whose photo it is in that prompt).
Future<PhotoSourceChoice?> showPhotoSourceSheet(
  BuildContext context, {
  String? title,
  bool allowCamera = true,
  List<CustomPhotoSource> customSources = const [],
  bool showRemove = false,
  String? removeConfirmName,
  PhotoToolsStrings? strings,
  PhotoSourcePicker? picker,
}) {
  final scope = PhotoToolsScope.of(context);
  return showAdaptiveSheet<PhotoSourceChoice>(
    context: context,
    builder: (_) => _PhotoSourceSheet(
      title: title,
      showCamera: allowCamera && (picker ?? scope.picker).canTakePhoto,
      customSources: customSources,
      showRemove: showRemove,
      removeConfirmName: removeConfirmName,
      strings: strings ?? scope.strings,
    ),
  );
}

class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet({
    required this.title,
    required this.showCamera,
    required this.customSources,
    required this.showRemove,
    required this.removeConfirmName,
    required this.strings,
  });

  final String? title;
  final bool showCamera;
  final List<CustomPhotoSource> customSources;
  final bool showRemove;
  final String? removeConfirmName;
  final PhotoToolsStrings strings;

  Future<void> _confirmRemove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.removeConfirmTitle(removeConfirmName)),
        content: Text(strings.removeMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(strings.remove),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop(PhotoSourceChoice.remove);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    void choose(PhotoSourceChoice choice) => Navigator.of(context).pop(choice);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
              child: Semantics(
                header: true,
                child: Text(
                  title ?? strings.sourceSheetTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            _SourceRow(
              key: PhotoToolsKeys.sourceDevice,
              icon: Icons.photo_library_outlined,
              label: strings.fromDevice,
              onTap: () => choose(PhotoSourceChoice.device),
            ),
            if (showCamera)
              _SourceRow(
                key: PhotoToolsKeys.sourceCamera,
                icon: Icons.photo_camera_outlined,
                label: strings.takePhoto,
                onTap: () => choose(PhotoSourceChoice.camera),
              ),
            for (final source in customSources)
              _SourceRow(
                key: PhotoToolsKeys.sourceCustom(source.id),
                icon: source.icon,
                label: source.label,
                onTap: () => choose(CustomSourceChoice(source)),
              ),
            if (showRemove) ...[
              const SizedBox(height: 8),
              _SourceRow(
                key: PhotoToolsKeys.sourceRemove,
                icon: Icons.delete_outline,
                label: strings.removePhoto,
                color: scheme.error,
                onTap: () => _confirmRemove(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: scheme.outlineVariant),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(icon, color: color ?? scheme.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: color ?? scheme.onSurface,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
