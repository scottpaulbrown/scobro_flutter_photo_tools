// Fails when line coverage of lib/ in coverage/lcov.info is under a threshold.
//
// Usage:
//   flutter test --coverage
//   dart run tool/coverage_gate.dart [--min 90] [--under lib/] [--files]
//
// Generated files (*.g.dart, *.freezed.dart) are left out.
import 'dart:io';

void main(List<String> args) {
  var min = 90.0;
  var under = 'lib/';
  var lcovPath = 'coverage/lcov.info';
  var listFiles = false;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--min':
        min = double.parse(args[++i]);
      case '--under':
        under = args[++i];
      case '--lcov':
        lcovPath = args[++i];
      case '--files':
        listFiles = true;
      default:
        stderr.writeln('Unknown argument: ${args[i]}');
        exit(64);
    }
  }

  final lcov = File(lcovPath);
  if (!lcov.existsSync()) {
    stderr.writeln('$lcovPath not found. Run `flutter test --coverage` first.');
    exit(66);
  }

  final hitsByFile = <String, (int found, int hit)>{};
  String? file;
  var found = 0;
  var hit = 0;
  for (final line in lcov.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      file = line.substring(3).replaceAll(r'\', '/');
      found = 0;
      hit = 0;
    } else if (line.startsWith('DA:')) {
      found++;
      if (!line.endsWith(',0')) hit++;
    } else if (line == 'end_of_record' && file != null) {
      hitsByFile[file] = (found, hit);
      file = null;
    }
  }

  final normalized = under.replaceAll(r'\', '/');
  final included = hitsByFile.entries.where((e) {
    final path = e.key;
    final inScope =
        path.startsWith(normalized) || path.contains('/$normalized');
    return inScope &&
        !path.endsWith('.g.dart') &&
        !path.endsWith('.freezed.dart');
  }).toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  var totalFound = 0;
  var totalHit = 0;
  for (final e in included) {
    totalFound += e.value.$1;
    totalHit += e.value.$2;
    if (listFiles) {
      final pct = e.value.$1 == 0 ? 100 : 100 * e.value.$2 / e.value.$1;
      stdout.writeln(
          '${pct.toStringAsFixed(1).padLeft(6)}%  ${e.value.$2}/${e.value.$1}  ${e.key}');
    }
  }
  final pct = totalFound == 0 ? 100.0 : 100 * totalHit / totalFound;
  stdout.writeln('Coverage of $normalized: ${pct.toStringAsFixed(2)}% '
      '($totalHit/$totalFound lines), minimum $min%.');
  if (pct < min) {
    stderr.writeln('Coverage is under the minimum.');
    exit(1);
  }
}
