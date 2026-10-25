import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/framing_geometry.dart';
import '../photo_tools_keys.dart';
import '../theme/photo_tools_scope.dart';
import '../theme/photo_tools_strings.dart';
import '../theme/photo_tools_theme.dart';
import '../widgets/photo_preview_strip.dart';
import 'crop_guide_shape.dart';
import 'framed_image.dart';
import 'photo_editor_controller.dart';
import 'stage_painter.dart';
import 'zoom_rotate_bar.dart';

/// The framing editor without any page chrome: the framing area, the zoom
/// and rotate controls and, when [previews] are given, a strip of previews.
///
/// Embed it in your own screen, or use `PhotoEditorPage` /
/// `showPhotoEditor` for a ready-made page with Save and Cancel.
///
/// Drag to move the picture, pinch or scroll to zoom, and use the slider and
/// Rotate button; with keyboard focus on the framing area, the arrow keys
/// move the picture and `+` / `-` zoom. The picture can never leave the crop
/// box.
///
/// Lays itself out by its own width: full width under 650, a centred 560
/// column from 650 to 1099, and from 1100 up the framing area on the left
/// with the controls and previews in a column on the right.
class PhotoEditor extends StatefulWidget {
  /// Creates a [PhotoEditor].
  const PhotoEditor({
    super.key,
    required this.controller,
    this.guideShape = CropGuideShape.circle,
    this.previews = const [],
    this.strings,
    this.onChooseAnother,
    this.onRetry,
  });

  /// The picture and its framing. Call `load` on it first.
  final PhotoEditorController controller;

  /// The outline drawn over the crop box. A circle at an aspect ratio other
  /// than 1 is drawn as an oval.
  final CropGuideShape guideShape;

  /// Previews of the framed picture at the sizes the app will show it.
  final List<PhotoPreviewSpec> previews;

  /// The text shown; defaults to `PhotoToolsScope`'s strings.
  final PhotoToolsStrings? strings;

  /// Shown as "Choose another" when the picture can't be read; null hides
  /// the action.
  final VoidCallback? onChooseAnother;

  /// Shown as "Try again" when rendering fails; null hides the action.
  final VoidCallback? onRetry;

  @override
  State<PhotoEditor> createState() => _PhotoEditorState();
}

/// The widest the editor's desktop layout grows; it is centred beyond that.
const double maxDesktopWidth = 1280;

class _PhotoEditorState extends State<PhotoEditor> {
  bool _interacting = false;

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings ?? PhotoToolsScope.of(context).strings;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final stage = _Stage(
          controller: controller,
          guideShape: widget.guideShape,
          strings: strings,
          interacting: _interacting,
          onInteracting: (value) {
            if (value != _interacting) setState(() => _interacting = value);
          },
          onChooseAnother: widget.onChooseAnother,
        );
        final bar = ZoomRotateBar(
          zoom: controller.framing.zoom,
          maxZoom: controller.options.maxZoom,
          enabled: controller.status == PhotoEditorStatus.ready,
          onZoom: controller.setZoom,
          onRotate: controller.rotateClockwise,
          strings: strings,
        );
        final previews = widget.previews.isEmpty
            ? null
            : PhotoPreviewStrip(
                title: strings.previewsTitle,
                specs: widget.previews,
                aspectRatio: controller.options.aspectRatio,
                builder: (context, spec) => _preview(context, spec),
              );
        final renderError = controller.isReady && controller.error != null
            ? _ErrorCard(
                message: strings.renderFailed,
                actionLabel: strings.tryAgain,
                onAction: widget.onRetry,
              )
            : null;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final side = <Widget>[
              bar,
              if (renderError != null) ...[
                const SizedBox(height: 12),
                renderError,
              ],
              if (previews != null) ...[
                const SizedBox(height: 28),
                previews,
              ],
            ];
            if (width >= 1100) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxDesktopWidth),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: stage),
                      const SizedBox(width: 32),
                      SizedBox(
                        width: 360,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: side,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final column = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [stage, const SizedBox(height: 12), ...side],
            );
            if (width >= 650) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: column,
                ),
              );
            }
            return column;
          },
        );
      },
    );
  }

  Widget _preview(BuildContext context, PhotoPreviewSpec spec) {
    final controller = widget.controller;
    final image = controller.image;
    final Widget framed = ClipPath(
      clipper: _GuideClipper(widget.guideShape),
      child: image == null
          ? ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            )
          : FramedImage(
              image: image,
              framing: controller.framing,
              aspectRatio: controller.options.aspectRatio,
              maxZoom: controller.options.maxZoom,
            ),
    );
    return spec.builder?.call(context, framed) ?? framed;
  }
}

class _GuideClipper extends CustomClipper<Path> {
  _GuideClipper(this.shape);

  final CropGuideShape shape;

  @override
  Path getClip(Size size) => shape.pathFor(Offset.zero & size);

  @override
  bool shouldReclip(covariant _GuideClipper oldClipper) =>
      oldClipper.shape != shape;
}

/// The framing area: the picture, the guide and every gesture.
class _Stage extends StatefulWidget {
  const _Stage({
    required this.controller,
    required this.guideShape,
    required this.strings,
    required this.interacting,
    required this.onInteracting,
    required this.onChooseAnother,
  });

  final PhotoEditorController controller;
  final CropGuideShape guideShape;
  final PhotoToolsStrings strings;
  final bool interacting;
  final ValueChanged<bool> onInteracting;
  final VoidCallback? onChooseAnother;

  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> {
  double _gestureStartZoom = 1;

  PhotoEditorController get _controller => widget.controller;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    const nudge = 0.04;
    final key = event.logicalKey;
    final zoomStep = (_controller.options.maxZoom - 1) / 12;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _controller.panBy(const Offset(-nudge, 0));
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _controller.panBy(const Offset(nudge, 0));
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _controller.panBy(const Offset(0, -nudge));
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _controller.panBy(const Offset(0, nudge));
    } else if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd) {
      _controller.setZoom(_controller.framing.zoom + zoomStep);
    } else if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      _controller.setZoom(_controller.framing.zoom - zoomStep);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final tools = PhotoToolsTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(tools.stageRadius!);
    final ratio = _controller.options.aspectRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.62;
        final pad = (width * 0.06).clamp(12.0, 32.0);
        final crop = FramingGeometry.largestFit(
          Size(
            (width - 2 * pad).clamp(1.0, double.infinity),
            (maxHeight - 2 * pad).clamp(1.0, double.infinity),
          ),
          ratio,
        );
        final height = crop.height + 2 * pad;
        final cropBox = Rect.fromLTWH(
          (width - crop.width) / 2,
          pad,
          crop.width,
          crop.height,
        );

        final image = _controller.image;
        final Widget content;
        if (_controller.status == PhotoEditorStatus.failed) {
          content = Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _ErrorCard(
                message: widget.strings.unreadable,
                actionLabel: widget.strings.chooseAnother,
                onAction: widget.onChooseAnother,
              ),
            ),
          );
        } else if (image == null) {
          content = Center(
            child: Semantics(
              label: widget.strings.loading,
              child: CircularProgressIndicator(color: tools.guideColor),
            ),
          );
        } else {
          content = TweenAnimationBuilder<double>(
            tween: Tween(end: widget.interacting ? 1 : 0),
            duration: const Duration(milliseconds: 180),
            builder: (context, grid, _) => CustomPaint(
              size: Size(width, height),
              painter: StagePainter(
                image: image,
                framing: _controller.framing,
                cropBox: cropBox,
                aspectRatio: ratio,
                maxZoom: _controller.options.maxZoom,
                guideShape: widget.guideShape,
                scrim: tools.stageScrim!,
                guideColor: tools.guideColor!,
                guideWidth: tools.guideWidth!,
                gridOpacity: grid,
              ),
            ),
          );
        }

        return Semantics(
          label: widget.strings.stageHint,
          child: Focus(
            onKeyEvent: _onKey,
            child: Builder(
              builder: (context) {
                final focused = Focus.of(context).hasFocus;
                return Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      GestureBinding.instance.pointerSignalResolver.register(
                        event,
                        (event) => _controller.setZoom(
                          _controller.framing.zoom -
                              (event as PointerScrollEvent).scrollDelta.dy /
                                  400,
                        ),
                      );
                    }
                  },
                  child: GestureDetector(
                    key: PhotoToolsKeys.stage,
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Focus.of(context).requestFocus(),
                    onScaleStart: (_) {
                      _gestureStartZoom = _controller.framing.zoom;
                      widget.onInteracting(true);
                    },
                    onScaleUpdate: (details) {
                      if (details.pointerCount > 1) {
                        _controller.setZoom(_gestureStartZoom * details.scale);
                      }
                      _controller.panBy(
                        Offset(
                          details.focalPointDelta.dx / cropBox.width,
                          details.focalPointDelta.dy / cropBox.height,
                        ),
                      );
                    },
                    onScaleEnd: (_) => widget.onInteracting(false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: height,
                      decoration: BoxDecoration(
                        color: tools.stageBackground,
                        borderRadius: radius,
                        border: Border.all(
                          color:
                              focused ? scheme.primary : scheme.outlineVariant,
                          width: focused ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(borderRadius: radius, child: content),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: scheme.onErrorContainer,
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }
}
