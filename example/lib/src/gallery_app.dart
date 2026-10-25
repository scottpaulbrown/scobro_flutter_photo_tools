import 'package:flutter/material.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';

import 'avatar_demo.dart';
import 'banner_demo.dart';
import 'fake_photo_server.dart';
import 'loader_demo.dart';

/// The example gallery: an avatar uploaded to a fake server, a staged 16:9
/// banner, and the versioned image loader.
class GalleryApp extends StatefulWidget {
  /// Creates a [GalleryApp].
  ///
  /// Tests pass a `FakePhotoSourcePicker` as [picker]; [seedLoaderDemo]
  /// gives the loader demo generated photos at start-up.
  const GalleryApp({
    super.key,
    required this.server,
    this.picker,
    this.seedLoaderDemo = true,
  });

  /// The stand-in backend.
  final FakePhotoServer server;

  /// The photo picker; null uses the real plugins.
  final PhotoSourcePicker? picker;

  /// Whether to seed the loader demo's photos.
  final bool seedLoaderDemo;

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  late final VersionedImageLoader _loader =
      VersionedImageLoader(fetch: widget.server.fetch);

  @override
  void initState() {
    super.initState();
    if (widget.seedLoaderDemo) {
      widget.server.seed(LoaderDemo.seededIds).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PhotoToolsScope(
      picker: widget.picker,
      loader: _loader,
      child: MaterialApp(
        title: 'Photo tools gallery',
        debugShowCheckedModeBanner: false,
        theme: galleryTheme(Brightness.light),
        darkTheme: galleryTheme(Brightness.dark),
        home: _GalleryHome(server: widget.server, loader: _loader),
      ),
    );
  }
}

/// A warm, editorial theme: ink on paper with a terracotta accent.
ThemeData galleryTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFB4532A),
    brightness: brightness,
  ).copyWith(
    surface: dark ? const Color(0xFF1A1714) : const Color(0xFFFBF6EF),
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final text = base.textTheme;
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: text.copyWith(
      displaySmall: text.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.05,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      labelSmall: text.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
      ),
    ),
  );
}

class _GalleryHome extends StatefulWidget {
  const _GalleryHome({required this.server, required this.loader});

  final FakePhotoServer server;
  final VersionedImageLoader loader;

  @override
  State<_GalleryHome> createState() => _GalleryHomeState();
}

class _GalleryHomeState extends State<_GalleryHome> {
  int _index = 0;

  static const _destinations = [
    (Icons.face_outlined, Icons.face, 'Avatar'),
    (Icons.panorama_outlined, Icons.panorama, 'Banner'),
    (Icons.grid_view_outlined, Icons.grid_view, 'Loader'),
  ];

  @override
  Widget build(BuildContext context) {
    final page = switch (_index) {
      0 => AvatarDemo(server: widget.server),
      1 => const BannerDemo(),
      _ => LoaderDemo(server: widget.server, loader: widget.loader),
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < 650) {
          return Scaffold(
            body: SafeArea(child: page),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final (icon, selected, label) in _destinations)
                  NavigationDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: label,
                  ),
              ],
            ),
          );
        }
        final extended = width >= 1100;
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  extended: extended,
                  labelType: extended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Icon(
                      Icons.crop_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                  ),
                  destinations: [
                    for (final (icon, selected, label) in _destinations)
                      NavigationRailDestination(
                        icon: Icon(icon),
                        selectedIcon: Icon(selected),
                        label: Text(label),
                      ),
                  ],
                ),
                VerticalDivider(
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(child: page),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The shared page frame: an eyebrow, a big title, a line of explanation and
/// the demo, centred and constrained on wide screens.
class DemoPage extends StatelessWidget {
  /// Creates a [DemoPage].
  const DemoPage({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.children,
  });

  /// The small label above the title.
  final String eyebrow;

  /// The page title.
  final String title;

  /// One or two sentences on what the demo shows.
  final String description;

  /// The demo itself.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = width < 650 ? 20.0 : 40.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(gutter, 32, gutter, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(title, style: theme.textTheme.displaySmall),
              const SizedBox(height: 12),
              Text(
                description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows [message] in a floating snack bar.
void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}

/// "512 × 512 JPEG · 42 KB".
String describeImage(EditedImage image) =>
    '${image.width} × ${image.height} ${image.format.name.toUpperCase()} · '
    '${(image.bytes.length / 1024).toStringAsFixed(0)} KB';

/// A quiet rounded panel on a tonal surface with a hairline border.
class Panel extends StatelessWidget {
  /// Creates a [Panel].
  const Panel({super.key, required this.child, this.padding = EdgeInsets.zero});

  /// The content.
  final Widget child;

  /// Space around [child].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}
