import 'package:flutter/material.dart';

import '../photo_tools_keys.dart';
import '../theme/photo_tools_scope.dart';
import '../theme/photo_tools_theme.dart';

/// Wraps an avatar ([child], [size] across) in a tap target with a small
/// camera badge at its bottom-right, for "change photo".
///
/// While [busy] (for example while `PhotoFlow` uploads), a progress ring
/// covers the avatar and taps are ignored. When not [enabled] it is just the
/// avatar, with no badge.
class ChangePhotoBadge extends StatelessWidget {
  /// Creates a [ChangePhotoBadge].
  const ChangePhotoBadge({
    super.key,
    required this.child,
    required this.size,
    required this.onTap,
    this.enabled = true,
    this.busy = false,
    this.semanticLabel,
  });

  /// The avatar, laid out [size] x [size].
  final Widget child;

  /// The avatar's diameter.
  final double size;

  /// Starts the photo change.
  final VoidCallback onTap;

  /// Whether tapping starts a change (and the badge shows).
  final bool enabled;

  /// Whether a photo is being saved.
  final bool busy;

  /// The tooltip and screen-reader label; defaults to
  /// `PhotoToolsStrings.changePhoto`.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tools = PhotoToolsTheme.of(context);
    final label =
        semanticLabel ?? PhotoToolsScope.of(context).strings.changePhoto;
    final badge = (size * 0.36).clamp(18.0, 28.0);
    final stack = SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: child),
          if (busy)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surface.withValues(alpha: 0.6),
                ),
                child: Padding(
                  padding: EdgeInsets.all(size * 0.26),
                  child: CircularProgressIndicator(
                    strokeWidth: (size * 0.05).clamp(2.0, 4.0),
                  ),
                ),
              ),
            ),
          if (enabled)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  color: tools.badgeBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 2),
                ),
                child: Icon(
                  Icons.photo_camera,
                  size: badge * 0.52,
                  color: tools.badgeForeground,
                ),
              ),
            ),
        ],
      ),
    );
    if (!enabled) return stack;
    return Semantics(
      button: true,
      enabled: !busy,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkResponse(
          key: PhotoToolsKeys.changePhoto,
          onTap: busy ? null : onTap,
          radius: size * 0.62,
          child: stack,
        ),
      ),
    );
  }
}
