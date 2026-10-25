import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads real fonts (Roboto and Material Icons, under test/fonts) so goldens
/// show readable text and icons instead of the default test boxes.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFont('Roboto', [
    'test/fonts/Roboto-Regular.ttf',
    'test/fonts/Roboto-Medium.ttf',
    'test/fonts/Roboto-Bold.ttf',
  ]);
  await _loadFont('MaterialIcons', ['test/fonts/MaterialIcons-Regular.otf']);
  await testMain();
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) return;
    final bytes = file.readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}
