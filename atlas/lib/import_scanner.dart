import 'dart:io';

import 'import_reference.dart';

/// Scans Dart files for import statements.
class ImportScanner {
  const ImportScanner();

  List<ImportReference> scan(File file) {
    final imports = <ImportReference>[];

    if (!file.path.endsWith('.dart')) {
      return imports;
    }

    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trimLeft();

      if (!trimmed.startsWith('import ')) {
        continue;
      }

      final match = RegExp(r'''import\s+['"]([^'"]+)['"]''')
          .firstMatch(trimmed);

      if (match == null) {
        continue;
      }

      imports.add(
        ImportReference(
          source: file.path,
          target: match.group(1)!,
        ),
      );
    }

    return imports;
  }
}
