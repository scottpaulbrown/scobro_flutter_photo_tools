import 'package:flutter/widgets.dart';

import '../core/photo_renderer.dart';
import '../loading/versioned_image_loader.dart';
import '../picking/photo_source_picker.dart';
import '../picking/plugin_photo_source_picker.dart';
import 'photo_tools_strings.dart';

/// What [PhotoToolsScope.of] hands the package's widgets: the strings, picker
/// and renderer to use, with defaults filled in.
@immutable
class PhotoToolsScopeData {
  /// Creates [PhotoToolsScopeData].
  const PhotoToolsScopeData({
    this.strings = const PhotoToolsStrings(),
    this.picker = const PluginPhotoSourcePicker(),
    this.renderer = const PhotoRenderer(),
    this.loader,
  });

  /// The defaults used when no [PhotoToolsScope] is present.
  static const PhotoToolsScopeData defaults = PhotoToolsScopeData();

  /// The text the widgets show.
  final PhotoToolsStrings strings;

  /// The picker `PhotoFlow` uses.
  final PhotoSourcePicker picker;

  /// The renderer the editor uses.
  final PhotoRenderer renderer;

  /// Loads stored photos for `PhotoAvatar`; null when the app set none.
  final VersionedImageLoader? loader;

  @override
  bool operator ==(Object other) =>
      other is PhotoToolsScopeData &&
      other.strings == strings &&
      other.picker == picker &&
      other.renderer == renderer &&
      other.loader == loader;

  @override
  int get hashCode => Object.hash(strings, picker, renderer, loader);
}

/// Sets the package's strings, picker, renderer and photo loader for
/// everything below it.
///
/// Optional: without a scope the widgets use English strings, the
/// [PluginPhotoSourcePicker] and the default [PhotoRenderer]. Put one above
/// your `MaterialApp`'s home (or wrap `MaterialApp.builder`'s child) to set
/// them once, or around a single screen. Values passed straight to a widget
/// win over the scope. A nested scope replaces an outer one completely.
///
/// In tests, pass a `FakePhotoSourcePicker` from `testing.dart` as [picker].
class PhotoToolsScope extends InheritedWidget {
  /// Creates a [PhotoToolsScope]; values left null use the defaults.
  const PhotoToolsScope({
    super.key,
    this.strings,
    this.picker,
    this.renderer,
    this.loader,
    required super.child,
  });

  /// The text the widgets show.
  final PhotoToolsStrings? strings;

  /// The picker `PhotoFlow` uses.
  final PhotoSourcePicker? picker;

  /// The renderer the editor uses.
  final PhotoRenderer? renderer;

  /// Loads stored photos for `PhotoAvatar`.
  final VersionedImageLoader? loader;

  /// The nearest scope's values with defaults filled in, or
  /// [PhotoToolsScopeData.defaults] when there is no scope.
  static PhotoToolsScopeData of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PhotoToolsScope>();
    if (scope == null) return PhotoToolsScopeData.defaults;
    return PhotoToolsScopeData(
      strings: scope.strings ?? const PhotoToolsStrings(),
      picker: scope.picker ?? const PluginPhotoSourcePicker(),
      renderer: scope.renderer ?? const PhotoRenderer(),
      loader: scope.loader,
    );
  }

  @override
  bool updateShouldNotify(PhotoToolsScope oldWidget) =>
      strings != oldWidget.strings ||
      picker != oldWidget.picker ||
      renderer != oldWidget.renderer ||
      loader != oldWidget.loader;
}
