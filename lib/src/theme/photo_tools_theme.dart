import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Optional visual overrides for the package's widgets.
///
/// Everything defaults to the app's [ColorScheme], so most apps never need
/// this. Add one to `ThemeData.extensions` to change any value:
///
/// ```dart
/// ThemeData(
///   extensions: const [PhotoToolsTheme(guideColor: Colors.amber, stageRadius: 8)],
/// )
/// ```
@immutable
class PhotoToolsTheme extends ThemeExtension<PhotoToolsTheme> {
  /// Creates a [PhotoToolsTheme]; values left null use the defaults.
  const PhotoToolsTheme({
    this.stageBackground,
    this.stageScrim,
    this.guideColor,
    this.guideWidth,
    this.stageRadius,
    this.badgeBackground,
    this.badgeForeground,
    this.previewBackground,
  });

  /// The defaults for [scheme]: a dark stage, a half-transparent scrim, a
  /// white guide and the scheme's primary colour on the badge.
  factory PhotoToolsTheme.fallback(ColorScheme scheme) => PhotoToolsTheme(
        stageBackground: Color.alphaBlend(
          scheme.scrim.withValues(alpha: 0.82),
          scheme.surface,
        ),
        stageScrim: scheme.scrim.withValues(alpha: 0.55),
        guideColor: Colors.white,
        guideWidth: 2,
        stageRadius: 20,
        badgeBackground: scheme.primary,
        badgeForeground: scheme.onPrimary,
        previewBackground: scheme.surfaceContainerLow,
      );

  /// The resolved theme for [context]: the app's [PhotoToolsTheme] extension
  /// over [PhotoToolsTheme.fallback]. Every value is non-null.
  static PhotoToolsTheme of(BuildContext context) {
    final theme = Theme.of(context);
    final fallback = PhotoToolsTheme.fallback(theme.colorScheme);
    final custom = theme.extension<PhotoToolsTheme>();
    return custom == null ? fallback : fallback._merge(custom);
  }

  /// The colour behind the picture in the editor's framing area.
  final Color? stageBackground;

  /// The colour laid over the part of the picture outside the crop.
  final Color? stageScrim;

  /// The colour of the crop guide's outline.
  final Color? guideColor;

  /// The width of the crop guide's outline, in logical pixels.
  final double? guideWidth;

  /// The corner radius of the framing area.
  final double? stageRadius;

  /// The fill of `ChangePhotoBadge`'s camera badge.
  final Color? badgeBackground;

  /// The icon colour of `ChangePhotoBadge`'s camera badge.
  final Color? badgeForeground;

  /// The surface behind the editor's previews.
  final Color? previewBackground;

  PhotoToolsTheme _merge(PhotoToolsTheme other) => copyWith(
        stageBackground: other.stageBackground,
        stageScrim: other.stageScrim,
        guideColor: other.guideColor,
        guideWidth: other.guideWidth,
        stageRadius: other.stageRadius,
        badgeBackground: other.badgeBackground,
        badgeForeground: other.badgeForeground,
        previewBackground: other.previewBackground,
      );

  @override
  PhotoToolsTheme copyWith({
    Color? stageBackground,
    Color? stageScrim,
    Color? guideColor,
    double? guideWidth,
    double? stageRadius,
    Color? badgeBackground,
    Color? badgeForeground,
    Color? previewBackground,
  }) =>
      PhotoToolsTheme(
        stageBackground: stageBackground ?? this.stageBackground,
        stageScrim: stageScrim ?? this.stageScrim,
        guideColor: guideColor ?? this.guideColor,
        guideWidth: guideWidth ?? this.guideWidth,
        stageRadius: stageRadius ?? this.stageRadius,
        badgeBackground: badgeBackground ?? this.badgeBackground,
        badgeForeground: badgeForeground ?? this.badgeForeground,
        previewBackground: previewBackground ?? this.previewBackground,
      );

  @override
  PhotoToolsTheme lerp(PhotoToolsTheme? other, double t) {
    if (other == null) return this;
    return PhotoToolsTheme(
      stageBackground: Color.lerp(stageBackground, other.stageBackground, t),
      stageScrim: Color.lerp(stageScrim, other.stageScrim, t),
      guideColor: Color.lerp(guideColor, other.guideColor, t),
      guideWidth: lerpDouble(guideWidth, other.guideWidth, t),
      stageRadius: lerpDouble(stageRadius, other.stageRadius, t),
      badgeBackground: Color.lerp(badgeBackground, other.badgeBackground, t),
      badgeForeground: Color.lerp(badgeForeground, other.badgeForeground, t),
      previewBackground:
          Color.lerp(previewBackground, other.previewBackground, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PhotoToolsTheme &&
      other.stageBackground == stageBackground &&
      other.stageScrim == stageScrim &&
      other.guideColor == guideColor &&
      other.guideWidth == guideWidth &&
      other.stageRadius == stageRadius &&
      other.badgeBackground == badgeBackground &&
      other.badgeForeground == badgeForeground &&
      other.previewBackground == previewBackground;

  @override
  int get hashCode => Object.hash(
        stageBackground,
        stageScrim,
        guideColor,
        guideWidth,
        stageRadius,
        badgeBackground,
        badgeForeground,
        previewBackground,
      );
}
