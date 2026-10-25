import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../core/edited_image.dart';
import '../core/framing_geometry.dart';
import '../core/photo_framing.dart';
import '../core/photo_renderer.dart';
import '../core/render_options.dart';

/// Where a [PhotoEditorController] is up to.
enum PhotoEditorStatus {
  /// Nothing loaded yet.
  idle,

  /// Decoding the picture.
  loading,

  /// The picture is shown and can be framed.
  ready,

  /// The picture couldn't be decoded; see [PhotoEditorController.error].
  failed,

  /// Writing the framed picture.
  rendering,
}

/// The state behind a `PhotoEditor`: the decoded picture and how it is
/// framed.
///
/// A plain [ChangeNotifier], so it works with any state management. Create
/// one, call [load], hand it to a `PhotoEditor`, and call [render] to get the
/// final picture. Dispose it when done.
class PhotoEditorController extends ChangeNotifier {
  /// Creates a [PhotoEditorController] that crops and renders with [options].
  PhotoEditorController({
    this.options = const RenderOptions(),
    PhotoRenderer? renderer,
  }) : renderer = renderer ?? const PhotoRenderer();

  /// The aspect ratio, zoom limit, size and format used.
  final RenderOptions options;

  /// Decodes and renders the picture.
  final PhotoRenderer renderer;

  PhotoEditorStatus _status = PhotoEditorStatus.idle;
  PhotoFraming _framing = const PhotoFraming();
  Uint8List? _source;
  ui.Image? _image;
  Object? _error;
  int _loadToken = 0;
  bool _disposed = false;

  /// Where the editor is up to.
  PhotoEditorStatus get status => _status;

  /// How the picture is framed now.
  PhotoFraming get framing => _framing;

  /// The bytes passed to [load].
  Uint8List? get source => _source;

  /// The decoded, upright picture once [status] is ready.
  ui.Image? get image => _image;

  /// The picture's upright size in pixels, once loaded.
  ui.Size? get imageSize {
    final image = _image;
    return image == null
        ? null
        : ui.Size(image.width.toDouble(), image.height.toDouble());
  }

  /// Whether the picture is shown and can be framed (including while it
  /// renders).
  bool get isReady =>
      _status == PhotoEditorStatus.ready ||
      _status == PhotoEditorStatus.rendering;

  /// Whether the framing differs from the default.
  bool get isEdited => !_framing.isDefault;

  /// What went wrong: set when loading fails ([status] is failed) or when the
  /// last [render] failed ([status] is ready again). Cleared by the next
  /// attempt.
  Object? get error => _error;

  /// Decodes [source] and resets the framing.
  ///
  /// The picture is decoded with Flutter's image codec for display. If that
  /// codec ignored the picture's EXIF orientation (its size doesn't match the
  /// renderer's), the picture is decoded again from upright pixels, so the
  /// editor always shows what will be saved.
  Future<void> load(Uint8List source) async {
    final token = ++_loadToken;
    _source = source;
    _framing = const PhotoFraming();
    _error = null;
    _replaceImage(null);
    _set(PhotoEditorStatus.loading);
    try {
      final results = await Future.wait<Object>(
        [renderer.sizeOf(source), _decode(source)],
        cleanUp: (value) {
          if (value is ui.Image) value.dispose();
        },
      );
      final upright = results[0] as ui.Size;
      var image = results[1] as ui.Image;
      if (image.width != upright.width.round() ||
          image.height != upright.height.round()) {
        image.dispose();
        image = await _decode(await renderer.bakeOrientation(source));
      }
      if (_disposed || token != _loadToken) {
        image.dispose();
        return;
      }
      _replaceImage(image);
      _set(PhotoEditorStatus.ready);
    } catch (e) {
      if (_disposed || token != _loadToken) return;
      _error = e;
      _set(PhotoEditorStatus.failed);
    }
  }

  /// Turns the picture a quarter clockwise and recentres it.
  void rotateClockwise() {
    if (!_canEdit) return;
    _setFraming(_framing.rotatedClockwise());
  }

  /// Sets the zoom, clamped to 1…`options.maxZoom`.
  void setZoom(double zoom) {
    if (!_canEdit) return;
    _setFraming(_framing.copyWith(zoom: zoom.clamp(1.0, options.maxZoom)));
  }

  /// Drags the picture by [stageFraction], in fractions of the crop box (1.0
  /// is its full width or height). The crop always stays inside the picture.
  void panBy(ui.Offset stageFraction) {
    final size = imageSize;
    if (!_canEdit || size == null) return;
    _setFraming(
      FramingGeometry.pan(
        size,
        _framing,
        stageFraction,
        aspectRatio: options.aspectRatio,
        maxZoom: options.maxZoom,
      ),
    );
  }

  /// Goes back to the default framing.
  void reset() {
    if (!_canEdit) return;
    _setFraming(const PhotoFraming());
  }

  /// Renders the framed picture; null when the picture isn't ready or
  /// rendering fails (then [error] says why and [status] is ready again).
  Future<EditedImage?> render() async {
    final source = _source;
    if (_status != PhotoEditorStatus.ready || source == null) return null;
    _error = null;
    _set(PhotoEditorStatus.rendering);
    try {
      final edited = await renderer.render(source, _framing, options);
      if (!_disposed) _set(PhotoEditorStatus.ready);
      return edited;
    } catch (e) {
      if (_disposed) return null;
      _error = e;
      _set(PhotoEditorStatus.ready);
      return null;
    }
  }

  bool get _canEdit => _status == PhotoEditorStatus.ready;

  void _setFraming(PhotoFraming framing) {
    if (framing == _framing) return;
    _framing = framing;
    notifyListeners();
  }

  void _set(PhotoEditorStatus status) {
    if (_disposed) return;
    _status = status;
    notifyListeners();
  }

  void _replaceImage(ui.Image? image) {
    _image?.dispose();
    _image = image;
  }

  static Future<ui.Image> _decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _replaceImage(null);
    super.dispose();
  }
}
