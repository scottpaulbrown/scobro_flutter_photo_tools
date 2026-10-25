import 'package:flutter/material.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';

import 'fake_photo_server.dart';
import 'gallery_app.dart';

/// A family of avatars served through `VersionedImageLoader`: each photo is
/// fetched once per version, and people without one show initials.
class LoaderDemo extends StatefulWidget {
  /// Creates a [LoaderDemo].
  const LoaderDemo({super.key, required this.server, required this.loader});

  /// The ids the gallery seeds with photos.
  static const seededIds = ['ana', 'ben', 'cleo', 'dev'];

  /// Where photos come from.
  final FakePhotoServer server;

  /// The cache the avatars share (also set on `PhotoToolsScope`).
  final VersionedImageLoader loader;

  @override
  State<LoaderDemo> createState() => _LoaderDemoState();
}

class _LoaderDemoState extends State<LoaderDemo> {
  static const _people = [
    ('ana', 'Ana Ruiz'),
    ('ben', 'Ben Okafor'),
    ('cleo', 'Cleo Park'),
    ('dev', 'Dev Shah'),
    ('eli', 'Eli Moreau'),
    ('fay', 'Fay Lindqvist'),
  ];
  static const _colors = [
    Color(0xFFE9C46A),
    Color(0xFF2A9D8F),
    Color(0xFFE76F51),
    Color(0xFF8AB17D),
    Color(0xFF6D597A),
    Color(0xFF457B9D),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final server = widget.server;
    return DemoPage(
      eyebrow: 'VersionedImageLoader',
      title: 'Photos behind your own auth',
      description: 'Each avatar fetches through your HTTP client once per '
          'photo version. Replacing the photos bumps the versions, so they '
          'are fetched again; people without a photo keep their initials.',
      children: [
        Panel(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              for (final (i, (id, name)) in _people.indexed)
                SizedBox(
                  width: 96,
                  child: Column(
                    children: [
                      PhotoAvatar(
                        name: name,
                        size: 72,
                        color: _colors[i],
                        photoId: id,
                        photoVersion: server.versionOf(id),
                        semanticLabel: name,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name.split(' ').first,
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Server fetches so far: ${server.fetchCount} · '
          'cached photos: ${widget.loader.length}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => setState(server.bumpVersions),
              icon: const Icon(Icons.autorenew),
              label: const Text('Replace photos (new versions)'),
            ),
            OutlinedButton(
              onPressed: () => setState(() {}),
              child: const Text('Refresh counts'),
            ),
          ],
        ),
      ],
    );
  }
}
