import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/edited_image.dart';
import '../core/photo_renderer.dart';
import '../core/render_options.dart';
import '../photo_tools_keys.dart';
import '../theme/photo_tools_scope.dart';
import '../theme/photo_tools_strings.dart';
import '../widgets/photo_preview_strip.dart';
import 'crop_guide_shape.dart';
import 'photo_editor.dart' show PhotoEditor, maxDesktopWidth;
import 'photo_editor_controller.dart';

/// Opens a [PhotoEditorPage] for [source] on a new page and resolves to the
/// framed picture, or null when the user leaves without saving.
///
/// The page is pushed as a plain [MaterialPageRoute], so it works with any
/// router. Apps using a declarative router can show [PhotoEditorPage] from
/// their own route instead.
Future<EditedImage?> showPhotoEditor(
  BuildContext context, {
  required Uint8List source,
  RenderOptions options = const RenderOptions(),
  CropGuideShape guideShape = CropGuideShape.circle,
  String? title,
  List<PhotoPreviewSpec> previews = const [],
  PhotoToolsStrings? strings,
  PhotoRenderer? renderer,
}) =>
    Navigator.of(context).push<EditedImage>(
      MaterialPageRoute<EditedImage>(
        builder: (_) => PhotoEditorPage(
          source: source,
          options: options,
          guideShape: guideShape,
          title: title,
          previews: previews,
          strings: strings,
          renderer: renderer,
        ),
      ),
    );

/// A full page for framing one picture: a close button and title, the
/// [PhotoEditor], and a Cancel / Save action bar.
///
/// Pops with an [EditedImage] on Save and with null on every way out. When
/// the framing has changed, leaving (Cancel, close, system back) asks before
/// discarding.
class PhotoEditorPage extends StatefulWidget {
  /// Creates a [PhotoEditorPage].
  const PhotoEditorPage({
    super.key,
    required this.source,
    this.options = const RenderOptions(),
    this.guideShape = CropGuideShape.circle,
    this.title,
    this.previews = const [],
    this.strings,
    this.renderer,
  });

  /// The picked picture's bytes.
  final Uint8List source;

  /// The aspect ratio, zoom limit, size and format of the result.
  final RenderOptions options;

  /// The outline drawn over the crop box.
  final CropGuideShape guideShape;

  /// The page title; defaults to `strings.editorTitle`.
  final String? title;

  /// Previews of the framed picture at the sizes the app will show it.
  final List<PhotoPreviewSpec> previews;

  /// The text shown; defaults to `PhotoToolsScope`'s strings.
  final PhotoToolsStrings? strings;

  /// The renderer; defaults to `PhotoToolsScope`'s renderer.
  final PhotoRenderer? renderer;

  @override
  State<PhotoEditorPage> createState() => _PhotoEditorPageState();
}

class _PhotoEditorPageState extends State<PhotoEditorPage> {
  PhotoEditorController? _controller;

  PhotoEditorController get controller => _controller!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      _controller = PhotoEditorController(
        options: widget.options,
        renderer: widget.renderer ?? PhotoToolsScope.of(context).renderer,
      );
      controller.load(widget.source);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  bool get _busy => controller.status == PhotoEditorStatus.rendering;

  Future<void> _confirmDiscard(PhotoToolsStrings strings) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.discardTitle),
        content: Text(strings.discardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.discard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    final image = await controller.render();
    if (image != null && mounted) Navigator.of(context).pop(image);
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings ?? PhotoToolsScope.of(context).strings;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return PopScope<EditedImage>(
          canPop: !controller.isEdited,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !_busy) _confirmDiscard(strings);
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: IconButton(
                key: PhotoToolsKeys.close,
                tooltip: strings.close,
                icon: const Icon(Icons.close),
                onPressed: _busy ? null : () => Navigator.maybePop(context),
              ),
              title: Text(widget.title ?? strings.editorTitle),
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final gutter = width < 650 ? 16.0 : 24.0;
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 24),
                        child: PhotoEditor(
                          controller: controller,
                          guideShape: widget.guideShape,
                          previews: widget.previews,
                          strings: strings,
                          onChooseAnother: () => Navigator.of(context).pop(),
                          onRetry: _save,
                        ),
                      ),
                    ),
                    _ActionBar(
                      width: width,
                      gutter: gutter,
                      cancel: TextButton(
                        key: PhotoToolsKeys.cancel,
                        onPressed:
                            _busy ? null : () => Navigator.maybePop(context),
                        child: Text(strings.cancel),
                      ),
                      save: FilledButton(
                        key: PhotoToolsKeys.save,
                        onPressed: controller.status == PhotoEditorStatus.ready
                            ? _save
                            : null,
                        child: _busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(strings.save),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// The page's bottom band: Cancel and Save, set apart from the editor.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.width,
    required this.gutter,
    required this.cancel,
    required this.save,
  });

  final double width;
  final double gutter;
  final Widget cancel;
  final Widget save;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = width < 650;
    final maxWidth =
        compact ? double.infinity : (width < 1100 ? 560.0 : maxDesktopWidth);
    final buttonStyle = Theme.of(context).filledButtonTheme.style;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 12),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: FilledButtonTheme(
                data: FilledButtonThemeData(
                  style: (buttonStyle ?? const ButtonStyle()).merge(
                    FilledButton.styleFrom(minimumSize: const Size(120, 48)),
                  ),
                ),
                child: Row(
                  children: compact
                      ? [
                          Expanded(child: cancel),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: save),
                        ]
                      : [
                          const Spacer(),
                          cancel,
                          const SizedBox(width: 12),
                          save,
                        ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
