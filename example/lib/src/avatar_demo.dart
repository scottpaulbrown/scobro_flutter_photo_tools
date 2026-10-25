import 'package:flutter/material.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';

import 'fake_photo_server.dart';
import 'gallery_app.dart';

/// A profile card whose photo is changed with `PhotoFlow.run` and uploaded
/// straight away to the fake server.
class AvatarDemo extends StatefulWidget {
  /// Creates an [AvatarDemo].
  const AvatarDemo({super.key, required this.server});

  /// Where photos are uploaded.
  final FakePhotoServer server;

  @override
  State<AvatarDemo> createState() => _AvatarDemoState();
}

class _AvatarDemoState extends State<AvatarDemo> {
  static const _id = 'sam';
  static const _name = 'Sam Rivera';
  bool _busy = false;

  FakePhotoServer get _server => widget.server;

  Future<void> _changePhoto() async {
    final hasPhoto = _server.versionOf(_id) != null;
    final result = await PhotoFlow.run<String>(
      context,
      options: const RenderOptions(outputLongEdge: 512),
      sheetTitle: 'Photo for Sam',
      editorTitle: "Frame Sam's photo",
      removeConfirmName: 'Sam',
      customSources: [
        CustomPhotoSource(
          id: 'sample',
          icon: Icons.landscape_outlined,
          label: 'Use a sample picture',
          load: samplePicture,
        ),
      ],
      onRemove: hasPhoto ? () => _server.remove(_id) : null,
      upload: (image) => _server.upload(_id, image),
      onBusy: (busy) {
        if (mounted) setState(() => _busy = busy);
      },
      errorMessage: (error) => error is FakeServerException
          ? error.message
          : 'Something went wrong. Please try again.',
      previews: [
        for (final (size, caption) in [
          (84.0, 'Profile'),
          (44.0, 'Lists'),
          (24.0, 'Chips'),
        ])
          PhotoPreviewSpec(
            size: size,
            caption: caption,
            builder: (context, framed) => PhotoAvatar(
              name: _name,
              size: size,
              ringColor: Theme.of(context).colorScheme.primary,
              photoChild: framed,
            ),
          ),
      ],
    );
    if (!mounted) return;
    setState(() {});
    switch (result) {
      case PhotoSaved(:final image):
        showMessage(context, 'Saved ${describeImage(image)}');
      case PhotoRemoved():
        showMessage(context, 'Photo removed');
      case PhotoFailed(:final message):
        showMessage(context, message);
      case PhotoCancelled():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _server.lastUpload;
    return DemoPage(
      eyebrow: 'Upload mode',
      title: 'Change a profile photo',
      description: 'Tap the avatar: pick a source, frame the picture, and it '
          'uploads to a fake server as a 512 px JPEG. Turn on failures to see '
          'how errors come back.',
      children: [
        Panel(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              ChangePhotoBadge(
                size: 96,
                busy: _busy,
                semanticLabel: 'Change Sam’s photo',
                onTap: _changePhoto,
                child: PhotoAvatar(
                  name: _name,
                  size: 96,
                  color: theme.colorScheme.primaryContainer,
                  ringColor: theme.colorScheme.primary,
                  photoId: _id,
                  photoVersion: _server.versionOf(_id),
                  semanticLabel: _name,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_name, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      _busy ? 'Saving…' : 'Tap the photo to change it',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            children: [
              SwitchListTile(
                key: const ValueKey('fail-uploads'),
                title: const Text('Make uploads fail'),
                subtitle: const Text('The fake server answers 503'),
                value: _server.failUploads,
                onChanged: (value) =>
                    setState(() => _server.failUploads = value),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              ListTile(
                title: const Text('Last upload'),
                subtitle: Text(
                  last == null ? 'Nothing yet' : describeImage(last),
                  key: const ValueKey('last-upload'),
                ),
                trailing: Text(
                  'v${_server.versionOf(_id) ?? '–'}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
