import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';

import 'fake_photo_server.dart';
import 'gallery_app.dart';

/// A 16:9 banner chosen in staged mode: the flow returns the picture and
/// uploads nothing, as when the record it belongs to doesn't exist yet.
class BannerDemo extends StatefulWidget {
  /// Creates a [BannerDemo].
  const BannerDemo({super.key});

  @override
  State<BannerDemo> createState() => _BannerDemoState();
}

class _BannerDemoState extends State<BannerDemo> {
  EditedImage? _banner;

  Future<void> _choose() async {
    final result = await PhotoFlow.run<void>(
      context,
      options: const RenderOptions(aspectRatio: 16 / 9, outputLongEdge: 1600),
      guideShape: CropGuideShape.roundedRect,
      sheetTitle: 'Banner picture',
      editorTitle: 'Frame the banner',
      allowCamera: false,
      customSources: [
        const CustomPhotoSource(
          id: 'sample',
          icon: Icons.landscape_outlined,
          label: 'Use a sample picture',
          load: _sample,
        ),
      ],
    );
    if (!mounted) return;
    switch (result) {
      case PhotoSaved(:final image):
        setState(() => _banner = image);
      case PhotoFailed(:final message):
        showMessage(context, message);
      case PhotoRemoved() || PhotoCancelled():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final banner = _banner;
    return DemoPage(
      eyebrow: 'Staged mode',
      title: 'Pick a 16:9 banner',
      description: 'No upload callback, so the flow hands back the framed '
          'picture to hold until you save the record. Output: 1600 × 900.',
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: banner == null
                ? ColoredBox(
                    color: theme.colorScheme.surfaceContainerHigh,
                    child: Icon(
                      Icons.panorama_outlined,
                      size: 56,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Image.memory(
                    banner.bytes,
                    key: const ValueKey('banner-result'),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          banner == null
              ? 'No banner yet'
              : '${describeImage(banner)} · held locally, not uploaded',
          key: const ValueKey('banner-caption'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _choose,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(banner == null ? 'Choose banner' : 'Change banner'),
            ),
            if (banner != null) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => setState(() => _banner = null),
                child: const Text('Clear'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

Future<Uint8List?> _sample() => samplePicture(seed: 1);
