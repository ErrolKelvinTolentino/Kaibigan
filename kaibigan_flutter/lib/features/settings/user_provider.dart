import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';

enum AuthMode { pending, authenticated }

class UserProvider extends ChangeNotifier {
  UserProvider() {
    _initialLoad = _loadPreferences();
  }

  Future<void>? _initialLoad;

  String _displayName = "Errol";
  String _selectedCompanion = "kai"; // 'kai', 'ann', 'bee'
  String _preferredLanguage = "taglish"; // 'taglish', 'filipino', 'english'
  bool _isDarkMode = false;
  AuthMode _authMode = AuthMode.pending;
  String? _userEmail;
  String? _authError;

  String get displayName => _displayName;
  String get selectedCompanion => _selectedCompanion;
  String get preferredMascotId => _selectedCompanion;
  String get preferredLanguage => _preferredLanguage;
  String get language => _preferredLanguage;
  bool get isDarkMode => _isDarkMode;
  AuthMode get authMode => _authMode;
  bool get isAuthenticated => _authMode == AuthMode.authenticated;
  String? get userEmail => _userEmail;
  String get email => _userEmail ?? '';
  String? get authError => _authError;

  Future<void> _ensureLoaded() async {
    await _initialLoad;
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _displayName = prefs.getString('display_name') ?? "Errol";
    _selectedCompanion = prefs.getString('selected_companion') ?? "kai";
    _preferredLanguage = prefs.getString('preferred_language') ?? "taglish";
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    _userEmail = prefs.getString('user_email');

    if (SupabaseService.isInitialized) {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser != null) {
        _authMode = AuthMode.authenticated;
        _userEmail = currentUser.email;
        _displayName =
            currentUser.userMetadata?['display_name'] ?? _displayName;
        await _upsertProfileToSupabase(
          userId: currentUser.id,
          email: _userEmail ?? '',
          displayName: _displayName,
        );
      } else {
        _authMode = AuthMode.pending;
      }
    } else {
      _authMode = AuthMode.pending;
    }

    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    await _ensureLoaded();
    _authError = null;

    if (!SupabaseService.isInitialized) {
      _authError =
          'Supabase is not initialized. Please check your connection or credentials.';
      notifyListeners();
      return false;
    }

    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        _authMode = AuthMode.authenticated;
        _userEmail = response.user?.email ?? email;
        _displayName = response.user?.userMetadata?['display_name'] ??
            email.split('@').first;
        await _upsertProfileToSupabase(
          userId: response.user!.id,
          email: _userEmail!,
          displayName: _displayName,
        );
        await _saveUserState();
        notifyListeners();
        return true;
      } else {
        _authError = 'Login failed. Session could not be created.';
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _authError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _authError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _ensureLoaded();
    _authError = null;

    if (!SupabaseService.isInitialized) {
      _authError =
          'Supabase is not initialized. Please check your connection or credentials.';
      notifyListeners();
      return false;
    }

    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      if (response.user != null) {
        await _upsertProfileToSupabase(
          userId: response.user!.id,
          email: email,
          displayName: displayName,
        );

        if (response.session != null) {
          _authMode = AuthMode.authenticated;
          _userEmail = response.user?.email ?? email;
          _displayName = displayName;
          await _saveUserState();
          notifyListeners();
          return true;
        } else {
          // If email confirmation is required by Supabase project settings
          _authError =
              'Account created! Please check your email to confirm registration before logging in.';
          notifyListeners();
          return false;
        }
      } else {
        _authError = 'Registration failed. Could not create account.';
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _authError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _authError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _ensureLoaded();
    if (SupabaseService.isInitialized) {
      try {
        await SupabaseService.client.auth.signOut();
      } catch (e) {
        print("Error signing out from Supabase: $e");
      }
    }
    _authMode = AuthMode.pending;
    _userEmail = null;
    _authError = null;
    await _saveUserState();
    notifyListeners();
  }

  Future<void> _saveUserState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_mode', _authMode.name);
    await prefs.setString('display_name', _displayName);
    if (_userEmail != null) {
      await prefs.setString('user_email', _userEmail!);
    } else {
      await prefs.remove('user_email');
    }
  }

  Future<void> _upsertProfileToSupabase({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    if (!SupabaseService.isInitialized) return;

    try {
      final client = SupabaseService.client;
      await client.from('profiles').upsert({
        'id': userId,
        'email': email.toLowerCase(),
        'display_name': displayName,
        'preferred_mascot_id': _selectedCompanion,
        'preferred_language': _preferredLanguage,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (e) {
      print("Error upserting profile to Supabase: $e");
    }
  }

  Future<void> setCompanion(String companionId) async {
    _selectedCompanion = companionId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_companion', companionId);
  }

  Future<void> setSelectedCompanion(String companionId) => setCompanion(companionId);

  Future<void> setLanguage(String lang) async {
    _preferredLanguage = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_language', lang);
  }

  Future<void> toggleDarkMode(bool val) async {
    _isDarkMode = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', val);
  }

  Future<void> updateDisplayName(String name) async {
    _displayName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('display_name', name);

    if (SupabaseService.isInitialized &&
        SupabaseService.client.auth.currentUser != null) {
      final userId = SupabaseService.client.auth.currentUser!.id;
      final email = SupabaseService.client.auth.currentUser!.email ?? _userEmail ?? '';
      await _upsertProfileToSupabase(
        userId: userId,
        email: email,
        displayName: name,
      );
    }
  }
}
