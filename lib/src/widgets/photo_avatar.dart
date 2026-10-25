import 'package:flutter/material.dart';

import '../loading/versioned_image_loader.dart';
import '../loading/versioned_memory_image.dart';
import '../theme/photo_tools_scope.dart';

/// A round avatar: a photo when there is one, otherwise initials.
///
/// The photo comes from, in order: [photoChild] (a widget, such as the
/// editor's live `FramedImage`), [image], or [photoId] + [photoVersion]
/// through [loader] (default: `PhotoToolsScope`'s loader). While a loaded
/// photo arrives, and when there is none, the initials show; the photo fades
/// in over 150 ms.
class PhotoAvatar extends StatelessWidget {
  /// Creates a [PhotoAvatar].
  const PhotoAvatar({
    super.key,
    required this.name,
    required this.size,
    this.color,
    this.ringColor,
    this.ringWidth,
    this.image,
    this.photoChild,
    this.photoId,
    this.photoVersion,
    this.loader,
    this.semanticLabel,
  });

  /// The person's (or thing's) name; the initials come from it.
  final String name;

  /// The diameter.
  final double size;

  /// The fill behind the initials; null uses a neutral surface colour.
  final Color? color;

  /// A ring around the avatar; null for none.
  final Color? ringColor;

  /// The ring's width; defaults to a width that suits [size].
  final double? ringWidth;

  /// A photo the app already holds.
  final ImageProvider? image;

  /// A widget that paints the photo, clipped to the circle.
  final Widget? photoChild;

  /// The id of a stored photo to load through [loader].
  final String? photoId;

  /// The stored photo's version; null means "no photo". Part of the cache
  /// key, so a replaced photo is fetched again.
  final String? photoVersion;

  /// Loads stored photos; defaults to `PhotoToolsScope`'s loader.
  final VersionedImageLoader? loader;

  /// What screen readers announce; null keeps the avatar out of the
  /// semantics tree (decorative).
  final String? semanticLabel;

  /// Up to two initials from [name]: the first letters of its first and last
  /// words, upper-cased. `?` for an empty name.
  static String initialsFor(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    final first = words.first.characters.first;
    if (words.length == 1) return first.toUpperCase();
    return (first + words.last.characters.first).toUpperCase();
  }

  /// The default ring width for [size].
  static double defaultRingWidth(double size) =>
      size >= 64 ? 3 : (size <= 24 ? 1.5 : 2);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = color ?? scheme.surfaceContainerHighest;
    final onFill = color == null
        ? scheme.onSurfaceVariant
        : (ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
            ? Colors.white
            : Colors.black87);
    final initials = initialsFor(name);
    final ring =
        ringColor == null ? 0.0 : (ringWidth ?? defaultRingWidth(size));
    final inner = size - 2 * ring - (ring > 0 ? 2 * ring.clamp(1.0, 2.0) : 0);

    final initialsCircle = DecoratedBox(
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: Center(
        child: Text(
          initials,
          maxLines: 1,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: onFill,
                fontSize: inner * (initials.length > 1 ? 0.36 : 0.42),
                fontWeight: FontWeight.w600,
                height: 1,
              ),
        ),
      ),
    );

    Widget? photo;
    if (photoChild != null) {
      photo = photoChild;
    } else if (image != null) {
      photo = _fadingImage(image!, initialsCircle);
    } else if (photoId != null && photoVersion != null) {
      final source = loader ?? PhotoToolsScope.of(context).loader;
      if (source != null) {
        photo = _fadingImage(
          VersionedMemoryImage(source, photoId!, photoVersion!),
          initialsCircle,
        );
      }
    }

    final Widget face = ClipOval(
      child: SizedBox.square(
        dimension: inner,
        child: Stack(
          fit: StackFit.expand,
          children: [initialsCircle, if (photo != null) photo],
        ),
      ),
    );

    final avatar = SizedBox.square(
      dimension: size,
      child: ring == 0
          ? face
          : DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ringColor!, width: ring),
              ),
              child: Center(child: face),
            ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: avatar);
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: avatar,
    );
  }

  Widget _fadingImage(
    ImageProvider provider,
    Widget fallback,
  ) =>
      Image(
        image: provider,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => fallback,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 150),
            child: child,
          );
        },
      );
}
