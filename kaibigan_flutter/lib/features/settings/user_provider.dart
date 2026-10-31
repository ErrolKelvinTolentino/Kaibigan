import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/ai_memory_service.dart';
import '../../core/services/ai_response_feedback_service.dart';
import '../../core/services/backend_status.dart';
import '../../core/services/offline_mode.dart';
import '../../core/services/offline_account_import.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/ui_sound_service.dart';
import '../../core/theme/garden_appearance.dart';
import '../../core/theme/journal_appearance.dart';
import '../../core/utils/api_logger.dart';
import '../../core/utils/env_config.dart';
import '../home/activity_usage_store.dart';
import '../insights/wellbeing_context.dart';

/// [offline] is a deliberate choice to use the app without an account,
/// with every record kept on this device.
enum AuthMode { pending, authenticated, offline }

class UserProvider extends ChangeNotifier {
  UserProvider({OfflineAccountImport? offlineImport})
      : _offlineImport = offlineImport ?? OfflineAccountImport() {
    _initialLoad = _loadPreferences().catchError((Object error) {
      _authError = 'Your saved settings could not be loaded. Please try again.';
      _hasLoadedPreferences = true;
      notifyListeners();
    });
    SupabaseService.initializationState.addListener(_subscribeToAuth);
    _subscribeToAuth();
  }

  void _subscribeToAuth() {
    if (SupabaseService.isInitialized && _authSubscription == null) {
      _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen(
        _handleAuthStateChange,
      );
    }
  }

  Future<void>? _initialLoad;
  StreamSubscription<AuthState>? _authSubscription;
  bool _hasLoadedPreferences = false;
  bool _hasSeenKaiValueDemo = false;
  bool _hasCompletedSetup = false;
  bool _completedSetupThisSession = false;
  bool _hasSeenAppTutorial = false;

  String _displayName = 'Friend';
  String _selectedCompanion = "kai"; // 'kai', 'ann', 'bee'
  String _preferredLanguage = "taglish"; // 'taglish', 'filipino', 'english'
  ThemeMode _themeMode = ThemeMode.light;
  GardenAppearance _gardenAppearance = GardenAppearance.syncWithTime;
  JournalPaperStyle _journalPaperStyle = JournalPaperStyle.ruled;
  JournalAccent _journalAccent = JournalAccent.honey;
  JournalTextSize _journalTextSize = JournalTextSize.normal;
  UiSoundLevel _uiSoundLevel = UiSoundLevel.soft;
  bool _aiMemoryEnabled = true;
  bool _aiWellbeingContextEnabled = true;

  AuthMode _authMode = AuthMode.pending;
  String? _userEmail;
  String? _authError;
  String? _dataError;
  bool _isPasswordRecovery = false;
  bool _disposed = false;
  String? _sessionUserId;
  Future<void>? _sessionWork;
  final OfflineAccountImport _offlineImport;
  bool _hasPendingLocalImport = false;
  bool _isImportingLocalData = false;
  String? _localImportError;

  bool get hasPendingLocalImport => _hasPendingLocalImport;
  bool get isImportingLocalData => _isImportingLocalData;
  String? get localImportError => _localImportError;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  String get displayName => _displayName;
  String get selectedCompanion => _selectedCompanion;
  String get preferredMascotId => _selectedCompanion;
  String get preferredLanguage => _preferredLanguage;
  String get language => _preferredLanguage;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  GardenAppearance get gardenAppearance => _gardenAppearance;
  Future<void> get ready => _ensureLoaded();
  bool get hasLoadedPreferences => _hasLoadedPreferences;
  bool get hasSeenKaiValueDemo => _hasSeenKaiValueDemo;
  bool get hasCompletedSetup => _hasCompletedSetup;
  bool get completedSetupThisSession => _completedSetupThisSession;
  bool get hasSeenAppTutorial => _hasSeenAppTutorial;
  JournalPaperStyle get journalPaperStyle => _journalPaperStyle;
  JournalAccent get journalAccent => _journalAccent;
  JournalTextSize get journalTextSize => _journalTextSize;
  UiSoundLevel get uiSoundLevel => _uiSoundLevel;
  bool get aiMemoryEnabled => _aiMemoryEnabled;
  bool get aiWellbeingContextEnabled => _aiWellbeingContextEnabled;
  AuthMode get authMode => _authMode;
  bool get isAuthenticated => _authMode == AuthMode.authenticated;

  String get startupIdentity => isOffline
      ? 'offline:${OfflineMode.scope}'
      : isAuthenticated
          ? 'account:${SupabaseService.isInitialized ? SupabaseService.client.auth.currentUser?.id ?? _userEmail : _userEmail}'
          : 'signed-out';

  /// Using the app without an account, storing everything on this device.
  bool get isOffline => _authMode == AuthMode.offline;

  /// Whether the person is past the sign-in gate at all. Screens should ask
  /// this rather than [isAuthenticated], which is specifically about having
  /// an account.
  bool get canUseApp => isAuthenticated || isOffline;
  String? get userEmail => _userEmail;
  String get email => _userEmail ?? '';
  String? get authError => _authError;
  String? get dataError => _dataError;
  bool get isPasswordRecovery => _isPasswordRecovery;

  Future<void> _ensureLoaded() async {
    await _initialLoad;
  }

  void _resetToDefaults() {
    _displayName = 'Friend';
    _selectedCompanion = 'kai';
    _preferredLanguage = 'taglish';
    _themeMode = ThemeMode.light;
    _gardenAppearance = GardenAppearance.syncWithTime;
    _journalPaperStyle = JournalPaperStyle.ruled;
    _journalAccent = JournalAccent.honey;
    _journalTextSize = JournalTextSize.normal;
    _uiSoundLevel = UiSoundLevel.soft;
    _aiMemoryEnabled = true;
    _aiWellbeingContextEnabled = true;
    _hasSeenKaiValueDemo = false;
    _hasCompletedSetup = false;
    _completedSetupThisSession = false;
    _hasSeenAppTutorial = false;
  }

  Future<void> _loadScopedPreferences(String identity) async {
    final prefs = await SharedPreferences.getInstance();
    _displayName =
        prefs.getString('user_pref_${identity}_display_name') ?? _displayName;
    _selectedCompanion =
        prefs.getString('user_pref_${identity}_selected_companion') ??
            _selectedCompanion;
    _preferredLanguage =
        prefs.getString('user_pref_${identity}_preferred_language') ??
            _preferredLanguage;
    final savedTheme = prefs.getString('user_pref_${identity}_theme_mode');
    if (savedTheme != null) {
      _themeMode = switch (savedTheme) {
        'system' => ThemeMode.system,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.light,
      };
    }
    final garden = prefs.getString('user_pref_${identity}_garden_appearance');
    if (garden != null) {
      _gardenAppearance = GardenAppearance.fromStorage(garden);
    }
    final paper = prefs.getString('user_pref_${identity}_journal_paper_style');
    if (paper != null) {
      _journalPaperStyle = JournalPaperStyleX.fromStorage(paper);
    }
    final accent = prefs.getString('user_pref_${identity}_journal_accent');
    if (accent != null) {
      _journalAccent = JournalAccentX.fromStorage(accent);
    }
    final textSize = prefs.getString('user_pref_${identity}_journal_text_size');
    if (textSize != null) {
      _journalTextSize = JournalTextSizeX.fromStorage(textSize);
    }
    final sound = prefs.getString('user_pref_${identity}_ui_sound_level');
    if (sound != null) {
      _uiSoundLevel = UiSoundLevelX.fromStorage(sound);
      UiSoundPlayer.activeController?.setLevel(_uiSoundLevel);
    }
    _aiMemoryEnabled =
        prefs.getBool('user_pref_${identity}_ai_memory_enabled') ?? true;
    _aiWellbeingContextEnabled =
        prefs.getBool('user_pref_${identity}_ai_wellbeing_context_enabled') ??
            true;
    _hasCompletedSetup = prefs.getBool('companion_setup_v1_$identity') ?? false;
    _hasSeenAppTutorial =
        prefs.getBool('app_tutorial_seen_v1_$identity') ?? false;
    _hasSeenKaiValueDemo =
        prefs.getBool('user_pref_${identity}_kai_value_demo_seen_v1') ?? false;
  }

  Future<void> _saveScopedPreferences(String identity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pref_${identity}_display_name', _displayName);
    await prefs.setString(
        'user_pref_${identity}_selected_companion', _selectedCompanion);
    await prefs.setString(
        'user_pref_${identity}_preferred_language', _preferredLanguage);
    await prefs.setString('user_pref_${identity}_theme_mode', _themeMode.name);
    await prefs.setString(
        'user_pref_${identity}_garden_appearance', _gardenAppearance.name);
    await prefs.setString(
        'user_pref_${identity}_journal_paper_style', _journalPaperStyle.name);
    await prefs.setString(
        'user_pref_${identity}_journal_accent', _journalAccent.name);
    await prefs.setString(
        'user_pref_${identity}_journal_text_size', _journalTextSize.name);
    await prefs.setString(
        'user_pref_${identity}_ui_sound_level', _uiSoundLevel.name);
    await prefs.setBool(
        'user_pref_${identity}_ai_memory_enabled', _aiMemoryEnabled);
    await prefs.setBool('user_pref_${identity}_ai_wellbeing_context_enabled',
        _aiWellbeingContextEnabled);
    await prefs.setBool('companion_setup_v1_$identity', _hasCompletedSetup);
    await prefs.setBool('app_tutorial_seen_v1_$identity', _hasSeenAppTutorial);
    await prefs.setBool(
        'user_pref_${identity}_kai_value_demo_seen_v1', _hasSeenKaiValueDemo);
  }

  Future<void> _loadLegacyFallback() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('display_name')) {
      _displayName = prefs.getString('display_name') ?? _displayName;
    }
    if (prefs.containsKey('selected_companion')) {
      _selectedCompanion =
          prefs.getString('selected_companion') ?? _selectedCompanion;
    }
    if (prefs.containsKey('preferred_language')) {
      _preferredLanguage =
          prefs.getString('preferred_language') ?? _preferredLanguage;
    }
    if (prefs.containsKey('theme_mode')) {
      final savedTheme = prefs.getString('theme_mode');
      _themeMode = switch (savedTheme) {
        'system' => ThemeMode.system,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.light,
      };
    } else if (prefs.getBool('is_dark_mode') == true) {
      _themeMode = ThemeMode.dark;
    }
    if (prefs.containsKey('garden_appearance')) {
      _gardenAppearance =
          GardenAppearance.fromStorage(prefs.getString('garden_appearance'));
    }
    if (prefs.containsKey('journal_paper_style')) {
      _journalPaperStyle = JournalPaperStyleX.fromStorage(
          prefs.getString('journal_paper_style'));
    }
    if (prefs.containsKey('journal_accent')) {
      _journalAccent =
          JournalAccentX.fromStorage(prefs.getString('journal_accent'));
    }
    if (prefs.containsKey('journal_text_size')) {
      _journalTextSize =
          JournalTextSizeX.fromStorage(prefs.getString('journal_text_size'));
    }
    if (prefs.containsKey('selected_companion') &&
        prefs.containsKey('preferred_language')) {
      _hasCompletedSetup = true;
    }
    if (prefs.getString('display_name') != 'Maria') {
      _hasSeenAppTutorial = true;
    }
  }

  Future<void> _loadPreferences() async {
    final session = SupabaseService.isInitialized
        ? SupabaseService.client.auth.currentSession
        : null;
    if (session != null) {
      await _applySession(session);
    } else {
      await OfflineMode.loadPreference();
      _authMode = OfflineMode.isEnabled ? AuthMode.offline : AuthMode.pending;
      if (_authMode == AuthMode.offline) {
        final prefs = await SharedPreferences.getInstance();
        final identity = startupIdentity;
        final hasScopedSettings = prefs.getKeys().any((key) =>
            key.startsWith('user_pref_${identity}_') ||
            key == 'companion_setup_v1_$identity');
        // Migrate a remembered guest's older setup once. Never borrow an
        // authenticated account's unscoped settings for a guest identity.
        if (!hasScopedSettings &&
            prefs.getString('auth_mode') != 'authenticated' &&
            prefs.getString('user_email') == null &&
            prefs.containsKey('selected_companion') &&
            prefs.containsKey('preferred_language')) {
          await _loadLegacyFallback();
          await _saveScopedPreferences(identity);
        }
        await _loadScopedPreferences(startupIdentity);
      } else {
        _resetToDefaults();
        await _loadLegacyFallback();
      }
    }

    _hasPendingLocalImport = await _offlineImport.pendingFor(_sessionUserId);
    if (_hasPendingLocalImport && !canUseApp) _hasSeenKaiValueDemo = true;
    _hasLoadedPreferences = true;
    notifyListeners();
  }

  Future<void> _applySession(Session? session) {
    if (session != null &&
        _sessionUserId == session.user.id &&
        isAuthenticated) {
      return _sessionWork ?? Future<void>.value();
    }
    _sessionUserId = session?.user.id;
    _sessionWork = _applySessionDetails(session);
    return _sessionWork!;
  }

  Future<void> _applySessionDetails(Session? session) async {
    if (session == null) {
      _authMode = AuthMode.pending;
      _userEmail = null;
      _sessionUserId = null;
      _resetToDefaults();
      _hasPendingLocalImport = await _offlineImport.pendingFor(null);
      _localImportError = null;
      notifyListeners();
      return;
    }

    _authMode = AuthMode.authenticated;
    _userEmail = session.user.email;
    _sessionUserId = session.user.id;
    final identity = startupIdentity;

    // Reset state before loading account-specific values
    _resetToDefaults();
    await _loadScopedPreferences(identity);

    if (_displayName == 'Friend') {
      _displayName = session.user.userMetadata?['display_name'] ??
          session.user.userMetadata?['full_name'] ??
          session.user.userMetadata?['name'] ??
          session.user.email?.split('@').first ??
          'Friend';
    }

    await OfflineMode.setEnabled(false);
    await _loadProfile(session.user.id);
    if (SupabaseService.client.auth.currentUser?.id != session.user.id ||
        _authMode != AuthMode.authenticated) {
      return;
    }
    await _syncLocalImport(session.user.id);
    if (_sessionUserId != session.user.id || !isAuthenticated) return;
    await _saveUserState();
    notifyListeners();
  }

  Future<void> _handleAuthStateChange(AuthState state) async {
    await _initialLoad;
    if (_disposed) return;
    if (state.session == null &&
        SupabaseService.client.auth.currentSession != null) {
      return;
    }
    if (state.session == null &&
        isOffline &&
        state.event != AuthChangeEvent.signedOut) {
      return;
    }
    if (state.session != null &&
        SupabaseService.client.auth.currentUser?.id != state.session!.user.id) {
      return;
    }
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
          .select(
              'display_name, preferred_mascot_id, preferred_language, theme_mode, garden_appearance, journal_paper_style, journal_accent, journal_text_size, ui_sound_level, ai_memory_enabled, ai_wellbeing_context_enabled, has_completed_setup, has_seen_tutorial')
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (SupabaseService.client.auth.currentUser?.id != userId) return;
      if (profile != null) {
        _displayName = profile['display_name'] as String? ?? _displayName;
        _selectedCompanion = profile['preferred_mascot_id'] as String? ?? 'kai';
        _preferredLanguage =
            profile['preferred_language'] as String? ?? 'taglish';

        final themeStr = profile['theme_mode'] as String?;
        if (themeStr != null) {
          _themeMode = switch (themeStr) {
            'system' => ThemeMode.system,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.light,
          };
        }
        if (profile['garden_appearance'] != null) {
          _gardenAppearance = GardenAppearance.fromStorage(
            profile['garden_appearance'] as String?,
          );
        }
        if (profile['journal_paper_style'] != null) {
          _journalPaperStyle = JournalPaperStyleX.fromStorage(
            profile['journal_paper_style'] as String?,
          );
        }
        if (profile['journal_accent'] != null) {
          _journalAccent = JournalAccentX.fromStorage(
            profile['journal_accent'] as String?,
          );
        }
        if (profile['journal_text_size'] != null) {
          _journalTextSize = JournalTextSizeX.fromStorage(
            profile['journal_text_size'] as String?,
          );
        }
        if (profile['ui_sound_level'] != null) {
          _uiSoundLevel = UiSoundLevelX.fromStorage(
            profile['ui_sound_level'] as String?,
          );
          UiSoundPlayer.activeController?.setLevel(_uiSoundLevel);
        }
        if (profile['ai_memory_enabled'] != null) {
          _aiMemoryEnabled = profile['ai_memory_enabled'] as bool;
          AIMemoryService.setEnabled(_aiMemoryEnabled, userId);
        }
        if (profile['ai_wellbeing_context_enabled'] != null) {
          _aiWellbeingContextEnabled =
              profile['ai_wellbeing_context_enabled'] as bool;
          WellbeingContextService.setEnabled(
              _aiWellbeingContextEnabled, userId);
        }
        if (profile['has_completed_setup'] != null) {
          _hasCompletedSetup = profile['has_completed_setup'] as bool;
        }
        if (profile['has_seen_tutorial'] != null) {
          _hasSeenAppTutorial = profile['has_seen_tutorial'] as bool;
        }

        await _saveScopedPreferences(startupIdentity);
      } else {
        // Brand new account: start with clean defaults
        _resetToDefaults();
        final current = SupabaseService.client.auth.currentUser;
        _displayName = current?.userMetadata?['display_name'] ??
            current?.userMetadata?['full_name'] ??
            current?.userMetadata?['name'] ??
            current?.email?.split('@').first ??
            'Friend';
        await _upsertProfileToSupabase(
          userId: userId,
          email: _userEmail ?? '',
          displayName: _displayName,
        );
        await _saveScopedPreferences(startupIdentity);
      }
    } catch (error) {
      ApiLogger.logDatabase(
        operation: 'SELECT',
        table: 'profiles',
        error: error.toString(),
      );
    }
  }

  String _transportError(Object error, {required String action}) {
    final kind = BackendStatus.classify(error);
    ApiLogger.logDatabase(
      operation: 'AUTH',
      table: action,
      error: '${kind.name}: $error',
    );
    return BackendStatus.describe(kind, language: language, action: action);
  }

  String _friendlyAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login') ||
        message.contains('invalid credentials')) {
      return 'Invalid email or password.';
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
    return 'The server could not complete that request: ${error.message}';
  }

  Future<void> continueOffline({String? displayName}) async {
    await _ensureLoaded();
    await _offlineImport.cancelPrepared();
    _hasPendingLocalImport = false;
    _localImportError = null;
    await OfflineMode.setEnabled(true);
    _authMode = AuthMode.offline;
    _authError = null;
    _userEmail = null;
    _sessionUserId = null;
    if (displayName != null && displayName.trim().isNotEmpty) {
      _displayName = displayName.trim();
    }
    await _loadScopedPreferences(startupIdentity);
    await _saveUserState();
    notifyListeners();
  }

  Future<void> leaveOfflineMode({bool importLocalData = false}) async {
    await _ensureLoaded();
    if (importLocalData) {
      try {
        await _offlineImport.prepare(OfflineMode.scope);
        _hasPendingLocalImport = await _offlineImport.pendingFor(null);
      } catch (_) {
        _localImportError =
            'Your local backup could not be prepared. Your entries are still on this device. Please try again.';
        notifyListeners();
        return;
      }
    }
    await OfflineMode.setEnabled(false);
    if (_authMode == AuthMode.offline) {
      _authMode = AuthMode.pending;
      _resetToDefaults();
    }
    // The person already chose account setup. Do not replay the value demo.
    _hasSeenKaiValueDemo = true;
    _localImportError = null;
    await _saveUserState();
    notifyListeners();
  }

  Future<bool> _syncLocalImport(String owner) async {
    final pending = await _offlineImport.pendingFor(owner);
    if (_sessionUserId != owner || !isAuthenticated) return false;
    _hasPendingLocalImport = pending;
    if (!_hasPendingLocalImport) {
      _localImportError = null;
      return true;
    }
    final synced = await _offlineImport.sync();
    final stillPending = await _offlineImport.pendingFor(owner);
    if (_sessionUserId != owner || !isAuthenticated) return false;
    _hasPendingLocalImport = stillPending;
    _localImportError = synced
        ? null
        : 'Your account is connected, but some local entries still need to upload. They are safe on this device. Reconnect and tap Retry backup.';
    return synced;
  }

  Future<bool> retryLocalImport() async {
    if (_isImportingLocalData || !isAuthenticated || _sessionUserId == null) {
      return false;
    }
    _isImportingLocalData = true;
    notifyListeners();
    try {
      return await _syncLocalImport(_sessionUserId!);
    } finally {
      _isImportingLocalData = false;
      notifyListeners();
    }
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
        await OfflineMode.setEnabled(false);
        _authMode = AuthMode.authenticated;
        _userEmail = response.user?.email ?? email;
        await _applySession(response.session);
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
    } catch (error) {
      _authError = _transportError(error, action: 'sign you in');
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
          _resetToDefaults();
          _displayName = displayName;
          await OfflineMode.setEnabled(false);
          await _applySession(response.session);
          return true;
        } else {
          _authError =
              'Account created! Please check your email to confirm registration before logging in.';
          notifyListeners();
          return false;
        }
      }
      _authError = 'Sign up failed. Please try again.';
      notifyListeners();
      return false;
    } on AuthException catch (error) {
      _authError = _friendlyAuthError(error);
    } catch (error) {
      _authError = _transportError(error, action: 'create your account');
    }
    notifyListeners();
    return false;
  }

  Future<bool> requestPasswordReset(String email) async {
    await _ensureLoaded();
    _authError = null;
    if (!SupabaseService.isInitialized) {
      _authError = 'Password reset is unavailable right now.';
      notifyListeners();
      return false;
    }
    try {
      final redirectUrl = EnvConfig.oauthRedirectUrl.trim();
      await SupabaseService.client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: redirectUrl.isEmpty ? null : redirectUrl,
      );
      return true;
    } on AuthException catch (error) {
      _authError = _friendlyAuthError(error);
    } catch (error) {
      _authError = _transportError(error, action: 'send the reset link');
    }
    notifyListeners();
    return false;
  }

  Future<bool> resetPassword(String email) => requestPasswordReset(email);

  Future<bool> resendConfirmation(String email) async {
    await _ensureLoaded();
    _authError = null;
    if (!SupabaseService.isInitialized) {
      _authError = 'Supabase is not initialized.';
      notifyListeners();
      return false;
    }
    try {
      await SupabaseService.client.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
        emailRedirectTo: EnvConfig.oauthRedirectUrl,
      );
      return true;
    } on AuthException catch (error) {
      _authError = _friendlyAuthError(error);
    } catch (error) {
      _authError = _transportError(error, action: 'resend confirmation email');
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
      } catch (error) {
        _authError = _transportError(error, action: 'sign you out');
        notifyListeners();
        return;
      }
    }
    _authMode = AuthMode.pending;
    _userEmail = null;
    _sessionUserId = null;
    _sessionWork = null;
    _authError = null;
    _resetToDefaults();

    // Reset external subsystems to fresh defaults
    UiSoundPlayer.reset();
    AIMemoryService.reset();
    WellbeingContextService.reset();
    AIResponseFeedbackService.reset();
    await ActivityUsageStore.clearActivityStats();

    // Clear legacy un-scoped preference keys so they cannot cross-contaminate next login
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('display_name');
    await prefs.remove('selected_companion');
    await prefs.remove('preferred_language');
    await prefs.remove('theme_mode');
    await prefs.remove('is_dark_mode');
    await prefs.remove('garden_appearance');
    await prefs.remove('journal_paper_style');
    await prefs.remove('journal_accent');
    await prefs.remove('journal_text_size');
    await prefs.remove('ui_sound_level');
    await prefs.remove('ai_memory_enabled');
    await prefs.remove('ai_wellbeing_context_enabled');
    await prefs.remove('user_email');
    await prefs.remove('auth_mode');

    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    await _ensureLoaded();
    _dataError = null;
    if (!SupabaseService.isInitialized ||
        SupabaseService.client.auth.currentUser == null) {
      _dataError = 'Account deletion is unavailable right now.';
      notifyListeners();
      return false;
    }

    try {
      final response =
          await SupabaseService.client.functions.invoke('delete-account');
      if (response.status < 200 || response.status >= 300) {
        throw StateError('Delete account returned ${response.status}.');
      }
      try {
        await SupabaseService.client.auth.signOut(scope: SignOutScope.local);
      } catch (_) {}

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _authMode = AuthMode.pending;
      _userEmail = null;
      _sessionUserId = null;
      _sessionWork = null;
      _resetToDefaults();

      UiSoundPlayer.reset();
      AIMemoryService.reset();
      WellbeingContextService.reset();
      AIResponseFeedbackService.reset();
      await ActivityUsageStore.clearActivityStats();

      _isPasswordRecovery = false;
      _authError = null;
      _dataError = null;
      notifyListeners();
      return true;
    } catch (error) {
      ApiLogger.logDatabase(
        operation: 'DELETE',
        table: 'account',
        error: error.toString(),
      );
      _dataError = _transportError(error, action: 'delete your account');
      notifyListeners();
      return false;
    }
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

  Future<bool> completeCompanionSetup() async {
    final identity = startupIdentity;
    try {
      _hasCompletedSetup = true;
      _completedSetupThisSession = true;
      notifyListeners();
      await _saveScopedPreferences(identity);
      await _syncCurrentProfile({'has_completed_setup': true});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> completeAppTutorial() async {
    final identity = startupIdentity;
    try {
      _hasSeenAppTutorial = true;
      notifyListeners();
      await _saveScopedPreferences(identity);
      await _syncCurrentProfile({'has_seen_tutorial': true});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resetAppTutorial() async {
    final identity = startupIdentity;
    try {
      _hasSeenAppTutorial = false;
      notifyListeners();
      await _saveScopedPreferences(identity);
      await _syncCurrentProfile({'has_seen_tutorial': false});
      return true;
    } catch (_) {
      return false;
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
      final profile = {
        'email': email.toLowerCase(),
        'display_name': displayName,
        'preferred_mascot_id': _selectedCompanion,
        'preferred_language': _preferredLanguage,
        'theme_mode': _themeMode.name,
        'garden_appearance': _gardenAppearance.name,
        'journal_paper_style': _journalPaperStyle.name,
        'journal_accent': _journalAccent.name,
        'journal_text_size': _journalTextSize.name,
        'ui_sound_level': _uiSoundLevel.name,
        'ai_memory_enabled': _aiMemoryEnabled,
        'ai_wellbeing_context_enabled': _aiWellbeingContextEnabled,
        'has_completed_setup': _hasCompletedSetup,
        'has_seen_tutorial': _hasSeenAppTutorial,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final updated = await client
          .from('profiles')
          .update(profile)
          .eq('id', userId)
          .select('id')
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (updated == null) {
        await client.from('profiles').insert({
          'id': userId,
          ...profile,
        }).timeout(const Duration(seconds: 5));
      }
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
    await _ensureLoaded();
    _selectedCompanion = companionId;
    notifyListeners();
    await _saveScopedPreferences(startupIdentity);
    return _syncCurrentProfile({'preferred_mascot_id': companionId});
  }

  Future<bool> setSelectedCompanion(String companionId) =>
      setCompanion(companionId);

  Future<bool> setLanguage(String lang) async {
    await _ensureLoaded();
    _preferredLanguage = lang;
    notifyListeners();
    await _saveScopedPreferences(startupIdentity);
    return _syncCurrentProfile({'preferred_language': lang});
  }

  void completeKaiValueDemo() {
    if (_hasSeenKaiValueDemo) return;
    _hasSeenKaiValueDemo = true;
    notifyListeners();
    unawaited(_saveScopedPreferences(startupIdentity));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _ensureLoaded();
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _saveScopedPreferences(startupIdentity);
    // Retain legacy key for backwards compatibility
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
    await prefs.setBool('is_dark_mode', mode == ThemeMode.dark);
    await _syncCurrentProfile({'theme_mode': mode.name});
  }

  Future<void> toggleDarkMode(bool val) =>
      setThemeMode(val ? ThemeMode.dark : ThemeMode.light);

  Future<void> setGardenAppearance(GardenAppearance appearance) async {
    await _ensureLoaded();
    if (_gardenAppearance == appearance) return;
    _gardenAppearance = appearance;
    notifyListeners();
    await _saveScopedPreferences(startupIdentity);
    await _syncCurrentProfile({'garden_appearance': appearance.name});
  }

  Future<void> setJournalPaperStyle(JournalPaperStyle style) async {
    if (_journalPaperStyle == style) return;
    _journalPaperStyle = style;
    notifyListeners();
    await _saveScopedPreferences(startupIdentity);
    await _syncCurrentProfile({'journal_paper_style': style.name});
  }

  Future<void> setJournalAccent(JournalAccent accent) async {
    if (_journalAccent == accent) return;
    _journalAccent = accent;
    notifyListeners();
    await _saveScopedPreferences(startupIdentity);
    await _syncCurrentProfile({'journal_accent': accent.name});
  }

  Future<void> setJournalTextSize(JournalTextSize size) async {
    if (_journalTextSize == size) return;
    _journalTextSize = size;
    notifyListeners();
    await _saveScopedPreferences(startupIdentity);
    await _syncCurrentProfile({'journal_text_size': size.name});
  }

  Future<void> resetJournalAppearance() async {
    _journalPaperStyle = JournalPaperStyle.ruled;
    _journalAccent = JournalAccent.honey;
    _journalTextSize = JournalTextSize.normal;
    notifyListeners();
    await _saveScopedPreferences(startupIdentity);
    await _syncCurrentProfile({
      'journal_paper_style': JournalPaperStyle.ruled.name,
      'journal_accent': JournalAccent.honey.name,
      'journal_text_size': JournalTextSize.normal.name,
    });
  }

  Future<void> setUiSoundLevel(UiSoundLevel level,
      {UiSoundController? soundController}) async {
    _uiSoundLevel = level;
    await soundController?.setLevel(level);
    UiSoundPlayer.activeController?.setLevel(level);
    notifyListeners();
    await _saveScopedPreferences(startupIdentity);
    await _syncCurrentProfile({'ui_sound_level': level.name});
  }

  Future<void> setAiMemoryEnabled(bool enabled) async {
    _aiMemoryEnabled = enabled;
    await AIMemoryService.setEnabled(enabled, _sessionUserId);
    notifyListeners();
    await _saveScopedPreferences(startupIdentity);
    await _syncCurrentProfile({'ai_memory_enabled': enabled});
  }

  Future<void> setAiWellbeingContextEnabled(bool enabled) async {
    _aiWellbeingContextEnabled = enabled;
    await WellbeingContextService.setEnabled(enabled, _sessionUserId);
    notifyListeners();
    await _saveScopedPreferences(startupIdentity);
    await _syncCurrentProfile({'ai_wellbeing_context_enabled': enabled});
  }

  Future<bool> updateDisplayName(String name) async {
    await _ensureLoaded();
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      _dataError = 'Display name cannot be empty.';
      notifyListeners();
      return false;
    }
    _displayName = cleanName;
    notifyListeners();
    await _saveScopedPreferences(startupIdentity);
    return _syncCurrentProfile({'display_name': cleanName});
  }

  Future<bool> _syncCurrentProfile([Map<String, dynamic>? partialData]) async {
    if (!SupabaseService.isInitialized) return false;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return false;
    try {
      final payload = {
        'updated_at': DateTime.now().toIso8601String(),
        if (partialData != null)
          ...partialData
        else ...{
          'email': (user.email ?? _userEmail ?? '').toLowerCase(),
          'display_name': _displayName,
          'preferred_mascot_id': _selectedCompanion,
          'preferred_language': _preferredLanguage,
          'theme_mode': _themeMode.name,
          'garden_appearance': _gardenAppearance.name,
          'journal_paper_style': _journalPaperStyle.name,
          'journal_accent': _journalAccent.name,
          'journal_text_size': _journalTextSize.name,
          'ui_sound_level': _uiSoundLevel.name,
          'ai_memory_enabled': _aiMemoryEnabled,
          'ai_wellbeing_context_enabled': _aiWellbeingContextEnabled,
          'has_completed_setup': _hasCompletedSetup,
          'has_seen_tutorial': _hasSeenAppTutorial,
        },
      };

      final updated = await SupabaseService.client
          .from('profiles')
          .update(payload)
          .eq('id', user.id)
          .select('id')
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (updated == null) {
        await SupabaseService.client.from('profiles').insert({
          'id': user.id,
          'email': (user.email ?? _userEmail ?? '').toLowerCase(),
          'display_name': _displayName,
          'preferred_mascot_id': _selectedCompanion,
          'preferred_language': _preferredLanguage,
          'theme_mode': _themeMode.name,
          'garden_appearance': _gardenAppearance.name,
          'journal_paper_style': _journalPaperStyle.name,
          'journal_accent': _journalAccent.name,
          'journal_text_size': _journalTextSize.name,
          'ui_sound_level': _uiSoundLevel.name,
          'ai_memory_enabled': _aiMemoryEnabled,
          'ai_wellbeing_context_enabled': _aiWellbeingContextEnabled,
          'has_completed_setup': _hasCompletedSetup,
          'has_seen_tutorial': _hasSeenAppTutorial,
          ...payload,
        }).timeout(const Duration(seconds: 5));
      }
      return true;
    } catch (e) {
      ApiLogger.logDatabase(
        operation: 'UPDATE',
        table: 'profiles',
        error: e.toString(),
      );
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    SupabaseService.initializationState.removeListener(_subscribeToAuth);
    _authSubscription?.cancel();
    super.dispose();
  }
}
