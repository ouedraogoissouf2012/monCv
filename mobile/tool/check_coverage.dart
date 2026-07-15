import 'dart:io';

const threshold = 65.0;

void main(List<String> arguments) {
  final inputPath = _argument(arguments, '--input=') ?? 'coverage/lcov.info';
  final excludesPath =
      _argument(arguments, '--excludes=') ?? 'tool/coverage_excludes.txt';
  final summaryPath = _argument(arguments, '--summary=');

  final input = File(inputPath);
  if (!input.existsSync()) {
    stderr.writeln('Coverage file not found: $inputPath');
    exitCode = 2;
    return;
  }

  final excludedPaths = File(excludesPath)
      .readAsLinesSync()
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toSet();
  final records = _parseLcov(input.readAsLinesSync());
  final raw = _total(records);
  final measuredRecords =
      records.where((record) => !excludedPaths.contains(record.path)).toList();
  final measured = _total(measuredRecords);
  final missingExclusions = excludedPaths.difference(
    records.map((record) => record.path).toSet(),
  );

  if (missingExclusions.isNotEmpty) {
    stderr.writeln(
      'Remove stale coverage exclusions: ${missingExclusions.join(', ')}',
    );
    exitCode = 2;
    return;
  }

  final passed = measured.rate >= threshold;
  final summary = '''
## Flutter coverage

| Scope | Covered lines | Total lines | Coverage | Threshold |
|---|---:|---:|---:|---:|
| Raw project | ${raw.covered} | ${raw.total} | ${raw.rate.toStringAsFixed(2)}% | information |
| Enforced scope | ${measured.covered} | ${measured.total} | ${measured.rate.toStringAsFixed(2)}% | ${threshold.toStringAsFixed(0)}% |

Legacy/generated exclusions: ${excludedPaths.length}. Result: **${passed ? 'PASS' : 'FAIL'}**.
''';

  stdout.write(summary);
  if (summaryPath != null) File(summaryPath).writeAsStringSync(summary);
  final githubSummary = Platform.environment['GITHUB_STEP_SUMMARY'];
  if (githubSummary != null && githubSummary.isNotEmpty) {
    File(githubSummary).writeAsStringSync(summary, mode: FileMode.append);
  }
  if (!passed) exitCode = 1;
}

String? _argument(List<String> arguments, String prefix) {
  for (final argument in arguments) {
    if (argument.startsWith(prefix)) return argument.substring(prefix.length);
  }
  return null;
}

List<_CoverageRecord> _parseLcov(List<String> lines) {
  final records = <_CoverageRecord>[];
  String? source;
  var found = 0;
  var hit = 0;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      source = _normalizePath(line.substring(3));
      found = 0;
      hit = 0;
    } else if (line.startsWith('LF:')) {
      found = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hit = int.parse(line.substring(3));
    } else if (line == 'end_of_record' && source != null) {
      records.add(_CoverageRecord(source, hit, found));
      source = null;
    }
  }
  return records;
}

String _normalizePath(String path) {
  final normalized = path.replaceAll('\\', '/');
  final libIndex = normalized.lastIndexOf('/lib/');
  return libIndex >= 0 ? normalized.substring(libIndex + 1) : normalized;
}

_CoverageTotal _total(Iterable<_CoverageRecord> records) {
  var covered = 0;
  var total = 0;
  for (final record in records) {
    covered += record.covered;
    total += record.total;
  }
  return _CoverageTotal(covered, total);
}

class _CoverageRecord {
  const _CoverageRecord(this.path, this.covered, this.total);

  final String path;
  final int covered;
  final int total;
}

class _CoverageTotal {
  const _CoverageTotal(this.covered, this.total);

  final int covered;
  final int total;
  double get rate => total == 0 ? 100 : covered * 100 / total;
}
