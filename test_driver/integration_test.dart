import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver for `flutter drive` runs of the integration tests.
/// Screenshots taken with `binding.takeScreenshot(...)` are written to
/// `docs/mobile/screenshots/<name>.png`.
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('docs/mobile/screenshots/$name.png')
        ..createSync(recursive: true);
      file.writeAsBytesSync(bytes);
      return true;
    },
  );
}
