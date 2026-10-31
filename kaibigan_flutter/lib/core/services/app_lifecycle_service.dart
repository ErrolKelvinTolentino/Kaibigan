import 'package:flutter/services.dart';

/// Coordinates application lifecycle actions between Flutter and native host platforms.
///
/// Moving to the background rather than finishing the activity preserves the
/// running task in memory so that returning to the app from the OS background/recent
/// apps tray does not trigger a cold start or reset the user's active session.
abstract final class AppLifecycleService {
  static const String channelName = 'com.kaibigan.app/app_lifecycle';
  static const MethodChannel _channel = MethodChannel(channelName);

  /// Test seam: when set, [sendToBackground] returns this value without
  /// touching platform channels.
  static bool? sendToBackgroundResultForTesting;

  /// Requests the host platform to move the application task to the background
  /// rather than terminating or finishing the activity.
  ///
  /// Returns `true` if the platform handled the request (e.g. Android `moveTaskToBack`),
  /// or `false` if unsupported or failed.
  static Future<bool> sendToBackground() async {
    if (sendToBackgroundResultForTesting != null) {
      return sendToBackgroundResultForTesting!;
    }
    try {
      final bool? result =
          await _channel.invokeMethod<bool>('sendToBackground');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    } on MissingPluginException catch (_) {
      return false;
    }
  }
}
