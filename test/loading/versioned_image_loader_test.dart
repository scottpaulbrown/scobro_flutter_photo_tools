import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

void main() {
  late List<(String, String)> fetched;
  Uint8List bytesFor(String id, String v) =>
      Uint8List.fromList('$id@$v'.codeUnits);

  VersionedImageLoader loader({int maxEntries = 100}) {
    fetched = [];
    return VersionedImageLoader(
      maxEntries: maxEntries,
      fetch: (id, version) async {
        fetched.add((id, version));
        if (id == 'none') return null;
        if (id == 'broken') throw StateError('500');
        return bytesFor(id, version);
      },
    );
  }

  test('one fetch per id and version', () async {
    final l = loader();
    expect(await l.load('a', '1'), bytesFor('a', '1'));
    expect(await l.load('a', '1'), bytesFor('a', '1'));
    expect(fetched, [('a', '1')]);
    expect(l.contains('a', '1'), isTrue);
    expect(l.peek('a', '1'), bytesFor('a', '1'));
    expect(l.length, 1);
  });

  test('a new version is fetched again', () async {
    final l = loader();
    await l.load('a', '1');
    await l.load('a', '2');
    expect(fetched, [('a', '1'), ('a', '2')]);
  });

  test('concurrent calls share one fetch', () async {
    final l = loader();
    final results = await Future.wait([l.load('a', '1'), l.load('a', '1')]);
    expect(results[0], results[1]);
    expect(fetched, hasLength(1));
  });

  test('"no photo" is cached; failures are not', () async {
    final l = loader();
    expect(await l.load('none', '1'), isNull);
    expect(await l.load('none', '1'), isNull);
    expect(fetched, hasLength(1));
    expect(l.contains('none', '1'), isTrue);

    expect(await l.load('broken', '1'), isNull);
    expect(await l.load('broken', '1'), isNull);
    expect(fetched.where((f) => f.$1 == 'broken'), hasLength(2));
    expect(l.contains('broken', '1'), isFalse);
  });

  test('a fetcher that throws synchronously is retried', () async {
    var calls = 0;
    final l = VersionedImageLoader(
      fetch: (id, version) {
        calls++;
        throw StateError('sync');
      },
    );
    expect(await l.load('a', '1'), isNull);
    expect(await l.load('a', '1'), isNull);
    expect(calls, 2);
  });

  test('least recently used entries are dropped', () async {
    final l = loader(maxEntries: 2);
    await l.load('a', '1');
    await l.load('b', '1');
    await l.load('a', '1'); // a is now the most recent.
    await l.load('c', '1'); // drops b.
    expect(l.length, 2);
    expect(l.contains('a', '1'), isTrue);
    expect(l.contains('b', '1'), isFalse);
    expect(l.contains('c', '1'), isTrue);
  });

  test('evict drops every version of an id; clear drops all', () async {
    final l = loader();
    await l.load('a', '1');
    await l.load('a', '2');
    await l.load('b', '1');
    l.evict('a');
    expect(l.contains('a', '1'), isFalse);
    expect(l.contains('a', '2'), isFalse);
    expect(l.contains('b', '1'), isTrue);
    l.clear();
    expect(l.length, 0);
    expect(l.peek('b', '1'), isNull);
  });

  group('VersionedMemoryImage', () {
    test('compares by loader, id, version and scale', () {
      final l = loader();
      final other = loader();
      expect(
          VersionedMemoryImage(l, 'a', '1'), VersionedMemoryImage(l, 'a', '1'));
      expect(
        VersionedMemoryImage(l, 'a', '1').hashCode,
        VersionedMemoryImage(l, 'a', '1').hashCode,
      );
      expect(VersionedMemoryImage(l, 'a', '1'),
          isNot(VersionedMemoryImage(l, 'a', '2')));
      expect(VersionedMemoryImage(l, 'a', '1'),
          isNot(VersionedMemoryImage(other, 'a', '1')));
      expect(VersionedMemoryImage(l, 'a', '1', scale: 2).toString(),
          contains('scale: 2'));
    });

    testWidgets('decodes the loaded bytes', (tester) async {
      final png = TestImages.asymmetricPng(width: 6, height: 3);
      final l = VersionedImageLoader(fetch: (_, __) async => png);
      final provider = VersionedMemoryImage(l, 'a', '1');
      final info = await tester.runAsync(() async {
        final key = await provider.obtainKey(ImageConfiguration.empty);
        expect(key, provider);
        final completer = Completer<ImageInfo>();
        provider.resolve(ImageConfiguration.empty).addListener(
              ImageStreamListener((info, _) => completer.complete(info)),
            );
        return completer.future;
      });
      expect(info!.image.width, 6);
      info.dispose();
    });

    testWidgets('fails when there is no photo', (tester) async {
      final l = VersionedImageLoader(fetch: (_, __) async => null);
      final error = await tester.runAsync(() {
        final completer = Completer<Object>();
        VersionedMemoryImage(l, 'none', '1')
            .resolve(ImageConfiguration.empty)
            .addListener(
              ImageStreamListener(
                (_, __) {},
                onError: (e, _) => completer.complete(e),
              ),
            );
        return completer.future;
      });
      expect(error, isA<StateError>());
    });
  });
}
