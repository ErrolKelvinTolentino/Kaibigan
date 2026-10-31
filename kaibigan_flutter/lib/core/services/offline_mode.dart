import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_service.dart';

/// Whether the app is running without an account, keeping everything on this
/// device.
///
/// This exists because a wellbeing journal should not stop working when a
/// backend is paused, a network is down, or someone simply does not want an
/// account. Offline mode is a deliberate choice the person makes, not a
/// silent degradation: what it costs them (no sync, no backup, no second
/// device) is stated where they choose it.
abstract final class OfflineMode {
  static const String preferenceKey = 'offline_mode_enabled';

  /// The namespace local records are filed under when there is no account.
  static const String guestScope = 'guest';

  static bool _isEnabled = false;
  static bool _loaded = false;

  static bool get isEnabled => _isEnabled;
  static bool get preferenceLoaded => _loaded;

  /// Defaults to off: an account is still the better experience when one is
  /// available, because it survives losing the phone.
  static Future<bool> loadPreference() async {
    final preferences = await SharedPreferences.getInstance();
    _isEnabled = preferences.getBool(preferenceKey) ?? false;
    _loaded = true;
    return _isEnabled;
  }

  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    _loaded = true;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(preferenceKey, enabled);
  }

  /// Test seam: sets the flag without touching storage.
  static void setEnabledForTesting(bool enabled) {
    _isEnabled = enabled;
    _loaded = true;
  }

  /// Which namespace the providers should read and write right now.
  ///
  /// A signed-in user's id when there is one, so that if someone turns on
  /// offline mode while signed in, their local records stay filed under
  /// their own account rather than mixing into the guest pile.
  static String get scope {
    if (!SupabaseService.isInitialized) return guestScope;
    final id = SupabaseService.client.auth.currentUser?.id;
    return id == null || id.isEmpty ? guestScope : id;
  }

  /// True when writes should go to the device instead of the backend.
  ///
  /// Also true when there is no usable backend at all, so a build with no
  /// credentials still saves what someone writes rather than discarding it.
  static bool get storesLocally => _isEnabled || !SupabaseService.isInitialized;
}
