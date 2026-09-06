// Native (VM/IO) implementation for platform-specific IO helpers.
// Used on Android, iOS, Windows, macOS, and Linux.

import 'dart:io';

Map<String, String> getPlatformEnvironment() {
  try {
    return Platform.environment;
  } catch (_) {
    return const <String, String>{};
  }
}

Future<Map<String, String>> loadFileSystemEnv(
  Map<String, String> Function(String) parser,
) async {
  try {
    final current = Directory.current;
    final candidates = [
      File('${current.path}${Platform.pathSeparator}.env'),
      File('${current.path}${Platform.pathSeparator}kaibigan_flutter${Platform.pathSeparator}.env'),
      File('${current.parent.path}${Platform.pathSeparator}.env'),
      File('${current.parent.path}${Platform.pathSeparator}kaibigan_flutter${Platform.pathSeparator}.env'),
    ];

    for (final file in candidates) {
      if (file.existsSync()) {
        final content = await file.readAsString();
        return parser(content);
      }
    }
  } catch (_) {}

  return const <String, String>{};
}
