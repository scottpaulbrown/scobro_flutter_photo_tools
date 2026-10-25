import 'package:flutter/material.dart';

import '../photo_tools_keys.dart';
import '../theme/photo_tools_theme.dart';

/// One preview in a [PhotoPreviewStrip]: how big it is and what it's called.
@immutable
class PhotoPreviewSpec {
  /// Creates a [PhotoPreviewSpec].
  const PhotoPreviewSpec({required this.size, this.caption, this.builder});

  /// The preview's longer edge in logical pixels; the shorter edge follows
  /// from the strip's aspect ratio.
  final double size;

  /// The text under the preview, for example `Profile` or `Lists`.
  final String? caption;

  /// Wraps the framed picture, for example in the app's own avatar widget.
  /// `framed` is the picture already clipped to the editor's guide shape.
  /// Null shows the framed picture as it is.
  final Widget Function(BuildContext context, Widget framed)? builder;

  /// The preview's size at [aspectRatio] (width / height).
  Size sizeFor(double aspectRatio) => aspectRatio >= 1
      ? Size(size, size / aspectRatio)
      : Size(size * aspectRatio, size);
}

/// A row of previews of the picture at the sizes the app will show it, on a
/// quiet tonal surface. The editor shows one when given `previews`.
class PhotoPreviewStrip extends StatelessWidget {
  /// Creates a [PhotoPreviewStrip].
  const PhotoPreviewStrip({
    super.key,
    required this.specs,
    required this.builder,
    this.title,
    this.aspectRatio = 1,
  });

  /// The previews to show.
  final List<PhotoPreviewSpec> specs;

  /// Builds each preview's content; it is laid out at the spec's size.
  final Widget Function(BuildContext context, PhotoPreviewSpec spec) builder;

  /// A small heading above the strip.
  final String? title;

  /// The previews' width divided by their height.
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final tools = PhotoToolsTheme.of(context);
    final title = this.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Semantics(
            header: true,
            child: Text(
              title,
              style: textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        DecoratedBox(
          key: PhotoToolsKeys.previews,
          decoration: BoxDecoration(
            color: tools.previewBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final spec in specs)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.fromSize(
                        size: spec.sizeFor(aspectRatio),
                        child: builder(context, spec),
                      ),
                      if (spec.caption != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          spec.caption!,
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
