import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

void main() {
  Future<PhotoToolsScopeData> read(WidgetTester tester, Widget? scope) async {
    late PhotoToolsScopeData data;
    final probe = Builder(
      builder: (context) {
        data = PhotoToolsScope.of(context);
        return const SizedBox();
      },
    );
    await tester.pumpWidget(
      scope == null ? probe : PhotoToolsScope(child: probe),
    );
    return data;
  }

  testWidgets('without a scope the defaults are used', (tester) async {
    final data = await read(tester, null);
    expect(data, PhotoToolsScopeData.defaults);
    expect(data.strings.save, 'Save photo');
    expect(data.picker, isA<PluginPhotoSourcePicker>());
    expect(data.renderer, isA<PhotoRenderer>());
  });

  testWidgets('an empty scope fills in the defaults', (tester) async {
    final data = await read(tester, const SizedBox());
    expect(data, PhotoToolsScopeData.defaults);
    expect(data.hashCode, PhotoToolsScopeData.defaults.hashCode);
  });

  testWidgets('a scope provides its values and notifies on change',
      (tester) async {
    final picker = FakePhotoSourcePicker();
    const strings = PhotoToolsStrings(save: 'Keep');
    var builds = 0;
    late PhotoToolsScopeData data;
    Widget app(PhotoToolsStrings s) => PhotoToolsScope(
          strings: s,
          picker: picker,
          renderer: const PhotoRenderer(),
          child: Builder(
            builder: (context) {
              builds++;
              data = PhotoToolsScope.of(context);
              return const SizedBox();
            },
          ),
        );

    await tester.pumpWidget(app(strings));
    expect(data.strings.save, 'Keep');
    expect(data.picker, same(picker));

    await tester.pumpWidget(app(const PhotoToolsStrings(save: 'Other')));
    expect(data.strings.save, 'Other');
    expect(builds, 2);
  });

  test('updateShouldNotify compares every value', () {
    final picker = FakePhotoSourcePicker();
    const child = SizedBox();
    final a = PhotoToolsScope(picker: picker, child: child);
    expect(a.updateShouldNotify(PhotoToolsScope(picker: picker, child: child)),
        isFalse);
    expect(a.updateShouldNotify(const PhotoToolsScope(child: child)), isTrue);
    expect(
      a.updateShouldNotify(
        PhotoToolsScope(
          picker: picker,
          renderer: const PhotoRenderer(),
          child: child,
        ),
      ),
      isTrue,
    );
  });
}
