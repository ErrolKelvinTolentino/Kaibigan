import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/supabase_service.dart';
import '../../core/services/ui_sound_service.dart';
import '../../core/theme/kaibigan_tokens.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/kaibigan_sound_scope.dart';
import '../../core/widgets/kaibigan_surface.dart';
import '../../core/widgets/mobile_layout.dart';
import '../auth_onboarding/auth_screen.dart';
import '../companion/companion_model.dart';
import 'user_provider.dart';

/// Who you are, and the account you are signed in with.
///
/// Everything this screen used to offer twice — companion, language, a second
/// unconfirmed sign-out — now lives in Settings, which owns preferences. This
/// screen owns identity and the account lifecycle, so there is exactly one
/// place to change each thing.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late String _savedName;
  bool _saving = false;

  String get _typedName => _nameController.text.trim();

  /// Save is only offered when there is actually something to save.
  bool get _canSave =>
      !_saving && _typedName.isNotEmpty && _typedName != _savedName;

  @override
  void initState() {
    super.initState();
    _savedName = context.read<UserProvider>().displayName;
    _nameController = TextEditingController(text: _savedName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _copy(String english, String filipino) => LanguageHelper.pick(
        context.read<UserProvider>().language,
        english: english,
        filipino: filipino,
      );

  Future<void> _saveName() async {
    if (!_canSave) return;
    final provider = context.read<UserProvider>();
    final name = _typedName;
    setState(() => _saving = true);
    final saved = await provider.updateDisplayName(name);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved) _savedName = name;
    });
    KaibiganSoundScope.play(
      context,
      saved ? UiSound.success : UiSound.gentle,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          saved
              ? _copy(
                  'Kai will call you $name from now on.',
                  'Tatawagin ka nang $name ni Kai mula ngayon.',
                )
              : provider.dataError ??
                  _copy(
                    'Your name could not be updated.',
                    'Hindi na-update ang iyong pangalan.',
                  ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _copy('Sign out of Kaibigan?', 'Mag-sign out sa Kaibigan?'),
        ),
        content: Text(
          _copy(
            'Your entries stay saved to your account. You can sign back in '
            'any time.',
            'Mananatiling naka-save sa account mo ang iyong mga tala. '
            'Puwede kang mag-sign in ulit anumang oras.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              _copy('Stay signed in', 'Manatiling naka-sign in'),
            ),
          ),
          FilledButton(
            key: const ValueKey('confirm-sign-out'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_copy('Sign out', 'Mag-sign out')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<UserProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    final user = context.watch<UserProvider>();
    final mascot = MascotInfo.getById(user.selectedCompanion);
    final signedIn = user.email.isNotEmpty;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(_copy('Your profile', 'Ang iyong profile')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: MobileContent(
          child: ListView(
            key: const ValueKey('profile-scroll-view'),
            padding: MobileLayout.pageInsets(context, top: 12, bottom: 32),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: mascot.primaryColor.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: mascot.primaryColor.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        mascot.avatarIcon,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                    const SizedBox(height: KaibiganSpace.sm),
                    Text(
                      _savedName,
                      style: text.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _copy(
                        'Walking alongside ${mascot.name}',
                        'Kasama si ${mascot.name}',
                      ),
                      style: text.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KaibiganSpace.xl),

              Text(
                _copy('YOUR NAME', 'ANG PANGALAN MO'),
                style: text.labelSmall?.copyWith(
                  color: palette.textMuted,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: KaibiganSpace.xs),
              KaibiganSurface(
                padding: const EdgeInsets.all(KaibiganSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      key: const ValueKey('profile-display-name-field'),
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      maxLength: 40,
                      enabled: !_saving,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _saveName(),
                      style: text.titleMedium,
                      decoration: InputDecoration(
                        isDense: true,
                        counterText: '',
                        hintText: _copy('What should Kai call you?',
                            'Ano ang itatawag sa iyo ni Kai?'),
                        filled: true,
                        fillColor: palette.surfaceSubtle,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(KaibiganRadius.control),
                          borderSide: BorderSide(color: palette.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(KaibiganRadius.control),
                          borderSide: BorderSide(color: palette.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: KaibiganSpace.sm,
                          vertical: KaibiganSpace.sm,
                        ),
                      ),
                    ),
                    const SizedBox(height: KaibiganSpace.xs),
                    Text(
                      _copy(
                        'This is how your companion greets you. Nothing else '
                        'changes.',
                        'Ito ang itatawag sa iyo ng kasama mo. Wala nang '
                        'ibang magbabago.',
                      ),
                      style: text.bodySmall?.copyWith(
                        color: palette.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: KaibiganSpace.sm),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const ValueKey('profile-save-name'),
                        onPressed: _canSave ? _saveName : null,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _canSave
                                    ? _copy('Save name', 'I-save ang pangalan')
                                    : _copy('Saved', 'Naka-save'),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KaibiganSpace.xl),

              Text(
                _copy('ACCOUNT', 'ACCOUNT'),
                style: text.labelSmall?.copyWith(
                  color: palette.textMuted,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: KaibiganSpace.xs),
              KaibiganSurface(
                key: const ValueKey('profile-account-card'),
                padding: const EdgeInsets.all(KaibiganSpace.md),
                child: Column(
                  children: [
                    _AccountRow(
                      icon: signedIn
                          ? Icons.mark_email_read_outlined
                          : Icons.person_outline_rounded,
                      label: signedIn
                          ? user.email
                          : _copy('Offline profile', 'Offline na profile'),
                      detail: signedIn
                          ? _copy('Signed in', 'Naka-sign in')
                          : _copy(
                              'Not signed in on this device',
                              'Hindi naka-sign in sa device na ito',
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: KaibiganSpace.sm,
                      ),
                      child: Divider(height: 1, color: palette.border),
                    ),
                    _AccountRow(
                      icon: SupabaseService.isInitialized
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_rounded,
                      label: SupabaseService.isInitialized
                          ? _copy('Cloud sync is on', 'Naka-on ang cloud sync')
                          : _copy(
                              'Sync unavailable',
                              'Hindi available ang pag-sync',
                            ),
                      detail: SupabaseService.isInitialized
                          ? _copy(
                              'Your entries are saved to your account',
                              'Naka-save sa account mo ang iyong mga tala',
                            )
                          : _copy(
                              'New entries cannot be saved right now',
                              'Hindi mase-save ang bagong tala ngayon',
                            ),
                      tone: SupabaseService.isInitialized
                          ? _AccountRowTone.good
                          : _AccountRowTone.warning,
                    ),
                    if (signedIn) ...[
                      const SizedBox(height: KaibiganSpace.md),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const ValueKey('profile-sign-out'),
                          onPressed: _confirmSignOut,
                          icon: Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: palette.danger,
                          ),
                          label: Text(
                            _copy('Sign out', 'Mag-sign out'),
                            style: TextStyle(
                              color: palette.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            side: BorderSide(color: palette.danger, width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(KaibiganRadius.control),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: KaibiganSpace.lg),

              // A pointer, not a second copy of the controls: companion,
              // language, theme and sound are owned by Settings.
              KaibiganSurface(
                key: const ValueKey('profile-preferences-pointer'),
                tone: KaibiganSurfaceTone.subtle,
                onTap: () => Navigator.of(context).maybePop(),
                padding: const EdgeInsets.all(KaibiganSpace.sm),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 19, color: palette.accent),
                    const SizedBox(width: KaibiganSpace.sm),
                    Expanded(
                      child: Text(
                        _copy(
                          'Companion, language, theme and sound are in Settings',
                          'Nasa Settings ang kasama, wika, tema at tunog',
                        ),
                        style: text.bodySmall?.copyWith(
                          color: palette.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: palette.textMuted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AccountRowTone { neutral, good, warning }

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.detail,
    this.tone = _AccountRowTone.neutral,
  });

  final IconData icon;
  final String label;
  final String detail;
  final _AccountRowTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    final colour = switch (tone) {
      _AccountRowTone.good => palette.botanical,
      _AccountRowTone.warning => palette.warning,
      _AccountRowTone.neutral => palette.accent,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colour.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(KaibiganRadius.control),
          ),
          child: Icon(icon, size: 19, color: colour),
        ),
        const SizedBox(width: KaibiganSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: text.bodySmall?.copyWith(
                  color: palette.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
