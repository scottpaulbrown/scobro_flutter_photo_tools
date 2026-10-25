import 'package:flutter/material.dart';

import '../photo_tools_keys.dart';
import '../theme/photo_tools_strings.dart';

/// The editor's controls: a zoom slider between zoom-out and zoom-in buttons,
/// and a Rotate button. One row when there is room, two when the width or
/// the text size is tight.
class ZoomRotateBar extends StatelessWidget {
  /// Creates a [ZoomRotateBar].
  const ZoomRotateBar({
    super.key,
    required this.zoom,
    required this.maxZoom,
    required this.enabled,
    required this.onZoom,
    required this.onRotate,
    required this.strings,
  });

  /// The current zoom.
  final double zoom;

  /// The slider's upper end.
  final double maxZoom;

  /// Whether the controls respond.
  final bool enabled;

  /// Called with a new zoom.
  final ValueChanged<double> onZoom;

  /// Called when Rotate is pressed.
  final VoidCallback onRotate;

  /// The labels.
  final PhotoToolsStrings strings;

  @override
  Widget build(BuildContext context) {
    final step = (maxZoom - 1) / 6;
    final value = zoom.clamp(1.0, maxZoom);
    final slider = Row(
      children: [
        IconButton(
          key: PhotoToolsKeys.zoomOut,
          tooltip: strings.zoomOut,
          icon: const Icon(Icons.zoom_out),
          onPressed: enabled && value > 1
              ? () => onZoom((value - step).clamp(1.0, maxZoom))
              : null,
        ),
        Expanded(
          child: Slider(
            key: PhotoToolsKeys.zoomSlider,
            min: 1,
            max: maxZoom,
            value: value,
            semanticFormatterCallback: strings.zoomValue,
            onChanged: enabled ? onZoom : null,
          ),
        ),
        IconButton(
          key: PhotoToolsKeys.zoomIn,
          tooltip: strings.zoomIn,
          icon: const Icon(Icons.zoom_in),
          onPressed: enabled && value < maxZoom
              ? () => onZoom((value + step).clamp(1.0, maxZoom))
              : null,
        ),
      ],
    );
    final rotate = OutlinedButton.icon(
      key: PhotoToolsKeys.rotate,
      onPressed: enabled ? onRotate : null,
      icon: const Icon(Icons.rotate_right),
      label: Text(strings.rotate),
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 48),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        if (constraints.maxWidth >= 360 * textScale) {
          return Row(
            children: [
              Expanded(child: slider),
              const SizedBox(width: 8),
              rotate,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            slider,
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerRight, child: rotate),
          ],
        );
      },
    );
  }
}
