// Web stub for platform-specific IO helpers.
// On the web, file system and OS environment variables do not exist.

Map<String, String> getPlatformEnvironment() => const <String, String>{};

Future<Map<String, String>> loadFileSystemEnv(
  Map<String, String> Function(String) parser,
) async =>
    const <String, String>{};
