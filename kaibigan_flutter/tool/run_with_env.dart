import 'dart:io';

/// Anything sent through `--dart-define` is visible to someone using the app,
/// especially in a web build. Provider keys are included only to keep the
/// local demonstration functional; SMTP credentials remain excluded.
const flutterEnvironmentKeys = <String>{
  'SUPABASE_URL',
  'SUPABASE_ANON_KEY',
  'PASSWORD_RESET_REDIRECT_URL',
  'OAUTH_REDIRECT_URL',
  'ENABLE_GOOGLE_AUTH',
  'GEMINI_API_KEY',
  'GEMINI_MODEL',
  'GROQ_API_KEY',
  'GROQ_FALLBACK_MODEL',
};

const runnerEnvironmentKeys = <String>{'FLUTTER_DEVICE'};
const defaultFlutterDevice = 'chrome';

Map<String, String> parseDotEnv(String source) {
  final values = <String, String>{};

  for (var line in source.split(RegExp(r'\r?\n'))) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    if (line.startsWith('export ')) {
      line = line.substring('export '.length).trimLeft();
    }

    final separator = line.indexOf('=');
    if (separator <= 0) continue;

    final key = line.substring(0, separator).trim();
    if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(key)) continue;

    var value = line.substring(separator + 1).trim();
    if (value.length >= 2) {
      final first = value[0];
      final last = value[value.length - 1];
      if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
        value = value.substring(1, value.length - 1);
      }
    }

    values[key] = value;
  }

  return values;
}

Map<String, String> flutterEnvironment(Map<String, String> values) {
  final forwarded = {
    for (final entry in values.entries)
      if (flutterEnvironmentKeys.contains(entry.key) && entry.value.isNotEmpty)
        entry.key: entry.value,
  };

  // Keep older demonstration .env files working while using the clearer
  // provider-specific names in the Flutter application.
  if (!forwarded.containsKey('GEMINI_MODEL') &&
      (values['PRIMARY_AI_MODEL'] ?? '').isNotEmpty) {
    forwarded['GEMINI_MODEL'] = values['PRIMARY_AI_MODEL']!;
  }
  if (!forwarded.containsKey('GROQ_FALLBACK_MODEL') &&
      (values['FALLBACK_AI_MODEL'] ?? '').isNotEmpty) {
    forwarded['GROQ_FALLBACK_MODEL'] = values['FALLBACK_AI_MODEL']!;
  }
  return forwarded;
}

bool hasDeviceSelection(Iterable<String> arguments) {
  return arguments.any(
    (argument) =>
        argument == '-d' ||
        argument == '--device-id' ||
        argument.startsWith('-d=') ||
        argument.startsWith('--device-id='),
  );
}

List<String> buildFlutterArguments({
  required Map<String, String> values,
  required List<String> arguments,
  String defaultDevice = defaultFlutterDevice,
}) {
  final asksForHelp = arguments.contains('-h') || arguments.contains('--help');
  final shouldChooseDefault = !asksForHelp && !hasDeviceSelection(arguments);
  return [
    'run',
    if (shouldChooseDefault) ...['-d', defaultDevice],
    for (final entry in values.entries)
      '--dart-define=${entry.key}=${entry.value}',
    ...arguments,
  ];
}

Directory _findProjectDirectory() {
  final current = Directory.current;
  if (File('${current.path}${Platform.pathSeparator}pubspec.yaml')
      .existsSync()) {
    return current;
  }

  final nested = Directory(
    '${current.path}${Platform.pathSeparator}kaibigan_flutter',
  );
  if (File('${nested.path}${Platform.pathSeparator}pubspec.yaml')
      .existsSync()) {
    return nested;
  }

  throw StateError(
    'Could not find the Kaibigan Flutter project. Run this command from the '
    'repository root or kaibigan_flutter directory.',
  );
}

Future<void> main(List<String> arguments) async {
  final projectDirectory = _findProjectDirectory();
  var envFile = File(
    '${projectDirectory.path}${Platform.pathSeparator}.env',
  );

  if (!envFile.existsSync()) {
    final rootEnv = File(
      '${Directory.current.path}${Platform.pathSeparator}.env',
    );
    if (rootEnv.existsSync()) {
      envFile = rootEnv;
    }
  }

  if (!envFile.existsSync()) {
    stderr.writeln(
      'No .env file found at ${envFile.path}. Copy .env.example to .env first.',
    );
    exitCode = 64;
    return;
  }

  final allValues = parseDotEnv(await envFile.readAsString());
  final flutterValues = flutterEnvironment(allValues);
  final ignoredKeys = allValues.keys
      .where((key) =>
          !flutterEnvironmentKeys.contains(key) &&
          !runnerEnvironmentKeys.contains(key) &&
          key != 'PRIMARY_AI_MODEL' &&
          key != 'FALLBACK_AI_MODEL')
      .toList()
    ..sort();

  if (flutterValues.isEmpty) {
    stderr.writeln(
      'The .env file does not contain any supported Flutter values.',
    );
    exitCode = 64;
    return;
  }

  stdout.writeln(
    'Starting Flutter with ${flutterValues.length} value(s) from .env.',
  );
  if (ignoredKeys.isNotEmpty) {
    stdout.writeln(
      'Not passed to Flutter (server-only or unused): '
      '${ignoredKeys.join(', ')}',
    );
  }

  final configuredDevice = allValues['FLUTTER_DEVICE']?.trim();
  final defaultDevice = configuredDevice == null || configuredDevice.isEmpty
      ? defaultFlutterDevice
      : configuredDevice;
  if (!hasDeviceSelection(arguments) &&
      !arguments.contains('-h') &&
      !arguments.contains('--help')) {
    stdout.writeln(
      'No device specified; launching on "$defaultDevice". '
      'Override with -d <deviceId>.',
    );
  }
  final flutterArguments = buildFlutterArguments(
    values: flutterValues,
    arguments: arguments,
    defaultDevice: defaultDevice,
  );

  final process = await Process.start(
    'flutter',
    flutterArguments,
    workingDirectory: projectDirectory.path,
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  exitCode = await process.exitCode;
}
