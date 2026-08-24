import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/api_logger.dart';
import '../../core/utils/env_config.dart';

enum AuthMode { pending, authenticated }

class UserProvider extends ChangeNotifier {
  UserProvider() {
    _initialLoad = _loadPreferences();
    if (SupabaseService.isInitialized) {
      _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen(
        _handleAuthStateChange,
      );
    }
  }

  Future<void>? _initialLoad;
  StreamSubscription<AuthState>? _authSubscription;

  String _displayName = 'Friend';
  String _selectedCompanion = "kai"; // 'kai', 'ann', 'bee'
  String _preferredLanguage = "taglish"; // 'taglish', 'filipino', 'english'
  bool _isDarkMode = false;
  AuthMode _authMode = AuthMode.pending;
  String? _userEmail;
  String? _authError;
  String? _dataError;
  bool _isPasswordRecovery = false;

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
  String? get dataError => _dataError;
  bool get isPasswordRecovery => _isPasswordRecovery;

  Future<void> _ensureLoaded() async {
    await _initialLoad;
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _displayName = prefs.getString('display_name') ?? 'Friend';
    _selectedCompanion = prefs.getString('selected_companion') ?? "kai";
    _preferredLanguage = prefs.getString('preferred_language') ?? "taglish";
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    _userEmail = prefs.getString('user_email');

    if (SupabaseService.isInitialized) {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser != null) {
        await _applySession(SupabaseService.client.auth.currentSession);
      } else {
        _authMode = AuthMode.pending;
      }
    } else {
      _authMode = AuthMode.pending;
    }

    notifyListeners();
  }

  Future<void> _applySession(Session? session) async {
    if (session == null) {
      _authMode = AuthMode.pending;
      _userEmail = null;
      _displayName = 'Friend';
      notifyListeners();
      return;
    }

    _authMode = AuthMode.authenticated;
    _userEmail = session.user.email;
    _displayName = session.user.userMetadata?['display_name'] ??
        session.user.userMetadata?['full_name'] ??
        session.user.userMetadata?['name'] ??
        session.user.email?.split('@').first ??
        _displayName;
    await _loadProfile(session.user.id);
    await _saveUserState();
    notifyListeners();
  }

  Future<void> _handleAuthStateChange(AuthState state) async {
    if (state.event == AuthChangeEvent.passwordRecovery) {
      _isPasswordRecovery = true;
    } else if (state.event == AuthChangeEvent.signedOut) {
      _isPasswordRecovery = false;
    }
    await _applySession(state.session);
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final profile = await SupabaseService.client
          .from('profiles')
          .select('display_name, preferred_mascot_id, preferred_language')
          .eq('id', userId)
          .maybeSingle();
      if (profile != null) {
        _displayName = profile['display_name'] as String? ?? _displayName;
        _selectedCompanion =
            profile['preferred_mascot_id'] as String? ?? _selectedCompanion;
        _preferredLanguage =
            profile['preferred_language'] as String? ?? _preferredLanguage;
      } else {
        await _upsertProfileToSupabase(
          userId: userId,
          email: _userEmail ?? '',
          displayName: _displayName,
        );
      }
    } catch (error) {
      ApiLogger.logDatabase(
        operation: 'SELECT',
        table: 'profiles',
        error: error.toString(),
      );
    }
  }

  String _friendlyAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login') ||
        message.contains('invalid credentials')) {
      return 'That email or password is incorrect. Please try again.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please confirm your email before logging in.';
    }
    if (message.contains('already registered') ||
        message.contains('already exists')) {
      return 'An account already exists for this email. Try logging in instead.';
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return 'We could not complete that request. Check your connection and try again.';
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
      _authError = _friendlyAuthError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _authError =
          'We could not log you in. Check your connection and try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    await _ensureLoaded();
    _authError = null;
    if (!EnvConfig.googleAuthEnabled) {
      _authError = 'Google sign-in is not configured yet.';
      notifyListeners();
      return false;
    }
    if (!SupabaseService.isInitialized) {
      _authError = 'Google sign-in is unavailable right now.';
      notifyListeners();
      return false;
    }
    try {
      final redirectUrl = EnvConfig.oauthRedirectUrl.trim();
      final started = await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl.isEmpty ? null : redirectUrl,
      );
      if (!started) {
        _authError = 'Google sign-in could not be started. Please try again.';
        notifyListeners();
      }
      return started;
    } on AuthException catch (error) {
      _authError = _friendlyAuthError(error);
    } catch (_) {
      _authError = 'Google sign-in could not be started. Please try again.';
    }
    notifyListeners();
    return false;
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
        emailRedirectTo: EnvConfig.oauthRedirectUrl,
      );

      if (response.user != null) {
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
      _authError = _friendlyAuthError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _authError =
          'We could not create your account. Check your connection and try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendConfirmation(String email) async {
    await _ensureLoaded();
    _authError = null;

    if (!SupabaseService.isInitialized) {
      _authError =
          'Supabase is not initialized. Please check your connection or credentials.';
      notifyListeners();
      return false;
    }

    try {
      await SupabaseService.client.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
        emailRedirectTo: EnvConfig.oauthRedirectUrl,
      );
      notifyListeners();
      return true;
    } on AuthException catch (error) {
      _authError = _friendlyAuthError(error);
    } catch (_) {
      _authError =
          'We could not resend the confirmation email. Please try again.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> resetPassword(String email) async {
    await _ensureLoaded();
    _authError = null;
    if (!SupabaseService.isInitialized) {
      _authError =
          'Password recovery is unavailable right now. Please try again later.';
      notifyListeners();
      return false;
    }
    try {
      final redirectUrl = EnvConfig.passwordResetRedirectUrl.trim();
      await SupabaseService.client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: redirectUrl.isEmpty ? null : redirectUrl,
      );
      return true;
    } on AuthException catch (error) {
      _authError = _friendlyAuthError(error);
    } catch (_) {
      _authError =
          'We could not send the reset email. Check your connection and try again.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> updateRecoveredPassword(String password) async {
    _authError = null;
    if (password.length < 8) {
      _authError = 'Use at least 8 characters for your new password.';
      notifyListeners();
      return false;
    }
    try {
      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: password),
      );
      _isPasswordRecovery = false;
      notifyListeners();
      return true;
    } on AuthException catch (error) {
      _authError = _friendlyAuthError(error);
    } catch (_) {
      _authError =
          'We could not update your password. Please request a new reset link.';
    }
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _ensureLoaded();
    if (SupabaseService.isInitialized) {
      try {
        await SupabaseService.client.auth.signOut();
      } catch (e) {
        _authError =
            'We could not sign you out. Check your connection and try again.';
        notifyListeners();
        return;
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

  Future<bool> _upsertProfileToSupabase({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    if (!SupabaseService.isInitialized) {
      _dataError = 'Profile sync is unavailable.';
      return false;
    }

    try {
      _dataError = null;
      final client = SupabaseService.client;
      await client.from('profiles').upsert({
        'id': userId,
        'email': email.toLowerCase(),
        'display_name': displayName,
        'preferred_mascot_id': _selectedCompanion,
        'preferred_language': _preferredLanguage,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
      return true;
    } catch (e) {
      _dataError = 'Your profile changes could not be synced.';
      ApiLogger.logDatabase(
        operation: 'UPSERT',
        table: 'profiles',
        error: e.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> setCompanion(String companionId) async {
    _selectedCompanion = companionId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_companion', companionId);
    return _syncCurrentProfile();
  }

  Future<bool> setSelectedCompanion(String companionId) =>
      setCompanion(companionId);

  Future<bool> setLanguage(String lang) async {
    _preferredLanguage = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_language', lang);
    return _syncCurrentProfile();
  }

  Future<void> toggleDarkMode(bool val) async {
    _isDarkMode = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', val);
  }

  Future<bool> updateDisplayName(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      _dataError = 'Display name cannot be empty.';
      notifyListeners();
      return false;
    }
    _displayName = cleanName;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('display_name', cleanName);

    if (SupabaseService.isInitialized &&
        SupabaseService.client.auth.currentUser != null) {
      final userId = SupabaseService.client.auth.currentUser!.id;
      final email =
          SupabaseService.client.auth.currentUser!.email ?? _userEmail ?? '';
      return _upsertProfileToSupabase(
        userId: userId,
        email: email,
        displayName: cleanName,
      );
    }
    _dataError = 'Profile sync is unavailable.';
    notifyListeners();
    return false;
  }

  Future<bool> _syncCurrentProfile() async {
    if (!SupabaseService.isInitialized) return false;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return false;
    return _upsertProfileToSupabase(
      userId: user.id,
      email: user.email ?? _userEmail ?? '',
      displayName: _displayName,
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
