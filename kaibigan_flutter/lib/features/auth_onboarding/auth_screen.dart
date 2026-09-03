import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/env_config.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/kaibigan_logo.dart';
import '../../core/widgets/kaibigan_state_view.dart';
import '../companion/companion_model.dart';
import '../settings/user_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.initialTabIndex = 0,
    this.onShowDemo,
  });

  final int initialTabIndex;
  final VoidCallback? onShowDemo;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late int _activeTabIndex;
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;
  bool _obscureRegPassword = true;
  bool _isLoading = false;
  String? _loadingLabel;
  String? _errorMessage;
  String? _confirmationMessage;
  String? _pendingConfirmationEmail;

  bool get _isRegistering => _activeTabIndex == 1;

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex.clamp(0, 1);
  }

  String _copy(String language, String english, String filipino) =>
      LanguageHelper.pick(
        language,
        english: english,
        filipino: filipino,
      );

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    setState(() {
      _isLoading = true;
      _loadingLabel = _copy(
        context.read<UserProvider>().language,
        'Signing in…',
        'Nagse-sign in…',
      );
      _errorMessage = null;
      _confirmationMessage = null;
    });
    final provider = context.read<UserProvider>();
    final success = await provider.login(email: email, password: password);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadingLabel = null;
      if (!success) _errorMessage = provider.authError ?? 'Login failed.';
    });
  }

  Future<void> _handleRegister() async {
    final name = _regNameController.text.trim();
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text;
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your display name.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    setState(() {
      _isLoading = true;
      _loadingLabel = _copy(
        context.read<UserProvider>().language,
        'Creating account…',
        'Gumagawa ng account…',
      );
      _errorMessage = null;
      _confirmationMessage = null;
    });
    final provider = context.read<UserProvider>();
    final success = await provider.register(
      email: email,
      password: password,
      displayName: name,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadingLabel = null;
      if (!success) {
        final message = provider.authError ?? 'Registration failed.';
        if (message.startsWith('Account created!')) {
          _errorMessage = null;
          _pendingConfirmationEmail = email;
          _confirmationMessage = _copy(
            provider.language,
            'Account created. Check your inbox or spam folder, then open the confirmation link to return to Kaibigan.',
            'Nagawa na ang account. Tingnan ang inbox o spam folder, pagkatapos ay buksan ang confirmation link para bumalik sa Kaibigan.',
          );
        } else {
          _errorMessage = message;
        }
      }
    });
  }

  Future<void> _handleResendConfirmation() async {
    final email = _pendingConfirmationEmail;
    if (email == null || _isLoading) return;
    setState(() {
      _isLoading = true;
      _loadingLabel = _copy(
        context.read<UserProvider>().language,
        'Sending email…',
        'Nagpapadala ng email…',
      );
      _errorMessage = null;
      _confirmationMessage = null;
    });
    final provider = context.read<UserProvider>();
    final sent = await provider.resendConfirmation(email);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadingLabel = null;
      if (sent) {
        _confirmationMessage =
            'A new confirmation email was sent. Use the newest link and check your spam folder.';
      } else {
        _errorMessage = provider.authError;
      }
    });
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _loadingLabel = _copy(
        context.read<UserProvider>().language,
        'Connecting…',
        'Kumokonekta…',
      );
      _errorMessage = null;
    });
    final provider = context.read<UserProvider>();
    final started = await provider.loginWithGoogle();
    if (!mounted) return;
    if (!started) {
      setState(() {
        _isLoading = false;
        _loadingLabel = null;
        _errorMessage = provider.authError ?? 'Google sign-in failed.';
      });
    }
  }

  Future<void> _handlePasswordReset() async {
    final email = _loginEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage =
          'Enter your email address above, then tap Forgot password again.');
      return;
    }
    setState(() {
      _isLoading = true;
      _loadingLabel = _copy(
        context.read<UserProvider>().language,
        'Sending reset link…',
        'Nagpapadala ng reset link…',
      );
      _errorMessage = null;
    });
    final provider = context.read<UserProvider>();
    final sent = await provider.resetPassword(email);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadingLabel = null;
      if (!sent) _errorMessage = provider.authError;
    });
    if (sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset email sent. Check your inbox and spam folder.',
          ),
        ),
      );
    }
  }

  void _selectTab(int index) {
    if (_isLoading || _activeTabIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _activeTabIndex = index;
      _errorMessage = null;
      _confirmationMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<UserProvider>();
    final mascot = MascotInfo.getById(user.selectedCompanion);
    final language = user.language;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      body: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: _AuthBackdropPainter(isDark: isDark),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 840;
                final side = isWide ? 40.0 : 20.0;
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    side,
                    isWide ? 30 : 18,
                    side,
                    30,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: isWide
                          ? Row(
                              children: [
                                Expanded(
                                  child: _buildBrandPanel(
                                    isDark,
                                    mascot,
                                    language,
                                    true,
                                  ),
                                ),
                                const SizedBox(width: 42),
                                SizedBox(
                                  width: 430,
                                  child: _buildAuthCard(isDark, language),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildBrandPanel(
                                  isDark,
                                  mascot,
                                  language,
                                  false,
                                ),
                                const SizedBox(height: 22),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 460),
                                  child: _buildAuthCard(isDark, language),
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandPanel(
    bool isDark,
    MascotInfo mascot,
    String language,
    bool expanded,
  ) {
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    if (!expanded) {
      return Semantics(
        header: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KaibiganWordmark(
              fontSize: 34,
              foregroundColor: primary,
            ),
            const SizedBox(height: 8),
            Text(
              _copy(
                language,
                'Your private space for honest moments.',
                'Iyong pribadong espasyo para sa tapat na sandali.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: secondary,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 320.ms).slideY(begin: -0.05);
    }
    return Container(
      height: 650,
      padding: const EdgeInsets.fromLTRB(42, 44, 42, 38),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C291F), const Color(0xFF202823)]
              : [const Color(0xFFFFF4D8), const Color(0xFFF7EEE1)],
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: isDark ? AppColors.darkHoneyBorder : AppColors.honeyBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
            blurRadius: 38,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KaibiganWordmark(
            fontSize: 34,
            foregroundColor: primary,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.honeyAmber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              _copy(
                language,
                'Your private wellness space',
                'Iyong pribadong wellness space',
              ),
              style: TextStyle(
                color: isDark ? AppColors.warmHoney : AppColors.honeyAmber,
                fontSize: 10.5,
                letterSpacing: 0.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _copy(
              language,
              'Come as you are.\nWrite what is real.',
              'Dumating bilang ikaw.\nIsulat ang totoo.',
            ),
            style: TextStyle(
              color: primary,
              fontSize: 39,
              height: 1.12,
              letterSpacing: -1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _copy(
              language,
              '${mascot.name} is here for thoughtful journaling, gentle reflection, and the moments you need somewhere safe to land.',
              'Narito si ${mascot.name} para sa maingat na pagsusulat, banayad na pagninilay, at mga sandaling kailangan mo ng ligtas na pahingahan.',
            ),
            style: TextStyle(
              color: secondary,
              fontSize: 15,
              height: 1.65,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TrustPill(
                icon: Icons.lock_outline_rounded,
                label: _copy(
                  language,
                  'Private by design',
                  'Pribado by design',
                ),
                isDark: isDark,
              ),
              _TrustPill(
                icon: Icons.spa_outlined,
                label: _copy(
                  language,
                  'Gentle, never judgmental',
                  'Banayad, walang panghuhusga',
                ),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 380.ms).slideX(begin: -0.035);
  }

  Widget _buildAuthCard(bool isDark, String language) {
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 25, 24, 23),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.honeyBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isRegistering
                  ? _copy(language, 'REGISTER', 'MAG-REGISTER')
                  : _copy(language, 'LOGIN', 'MAG-LOGIN'),
              style: const TextStyle(
                color: AppColors.honeyAmber,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isRegistering
                  ? _copy(
                      language,
                      'Create your account',
                      'Gumawa ng account',
                    )
                  : _copy(
                      language,
                      'Welcome back',
                      'Maligayang pagbabalik',
                    ),
              style: TextStyle(
                fontSize: 26,
                height: 1.15,
                letterSpacing: -0.65,
                fontWeight: FontWeight.w900,
                color: primary,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _isRegistering
                  ? _copy(
                      language,
                      'A few details, then this space is yours.',
                      'Ilang detalye lang, at iyo na ang espasyong ito.',
                    )
                  : _copy(
                      language,
                      'Your thoughts are right where you left them.',
                      'Naghihintay ang iyong mga tala kung saan mo iniwan.',
                    ),
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: secondary,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              child: Column(
                children: [
                  if (_confirmationMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: _buildMessage(
                        _confirmationMessage!,
                        Icons.mark_email_read_outlined,
                        AppColors.sageGreen,
                        action: _pendingConfirmationEmail == null
                            ? null
                            : TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : _handleResendConfirmation,
                                child: Text(
                                  _copy(
                                    language,
                                    'Resend email',
                                    'Ipadala ulit',
                                  ),
                                ),
                              ),
                      ),
                    ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: _buildMessage(
                        _errorMessage!,
                        Icons.info_outline_rounded,
                        AppColors.moodAwful,
                      ),
                    ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.035, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _isRegistering
                  ? _buildRegisterForm(isDark, language)
                  : _buildLoginForm(isDark, language),
            ),
            if (EnvConfig.googleAuthEnabled) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _copy(language, 'or', 'o'),
                      style: TextStyle(fontSize: 12, color: secondary),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  icon: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                  label: Text(
                    _copy(
                      language,
                      'Continue with Google',
                      'Magpatuloy gamit ang Google',
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _buildAccountSwitch(language, secondary),
            if (widget.onShowDemo != null) ...[
              const SizedBox(height: 4),
              Center(
                child: TextButton.icon(
                  key: const ValueKey('show-kai-demo'),
                  onPressed: _isLoading ? null : widget.onShowDemo,
                  icon: const Icon(Icons.auto_awesome_outlined, size: 16),
                  label: Text(
                    _copy(
                      language,
                      'See Kai in action',
                      'Makita kung paano tumutulong si Kai',
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: secondary.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _copy(
                      language,
                      'Your entries stay tied to your private account.',
                      'Nananatiling pribado sa account mo ang iyong mga tala.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.8,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: secondary.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 70.ms, duration: 350.ms).slideY(begin: 0.025);
  }

  Widget _buildAccountSwitch(String language, Color secondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            _isRegistering
                ? _copy(
                    language,
                    'Already have an account?',
                    'May account ka na?',
                  )
                : _copy(
                    language,
                    'New to Kaibigan?',
                    'Bago sa Kaibigan?',
                  ),
            style: TextStyle(
              color: secondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 3),
        TextButton(
          key: ValueKey(
            _isRegistering ? 'switch-to-login' : 'switch-to-register',
          ),
          onPressed:
              _isLoading ? null : () => _selectTab(_isRegistering ? 0 : 1),
          child: Text(
            _isRegistering
                ? _copy(language, 'Login', 'Mag-login')
                : _copy(language, 'Register', 'Mag-register'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(
    String message,
    IconData icon,
    Color color, {
    Widget? action,
  }) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12.2,
                  height: 1.45,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (action != null) action,
          ],
        ),
      ),
    ).animate().fadeIn(duration: 180.ms);
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    Iterable<String>? autofillHints,
    ValueChanged<String>? onSubmitted,
  }) {
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 3, bottom: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: secondary,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onSubmitted: onSubmitted,
          autocorrect: keyboardType != TextInputType.emailAddress,
          enableSuggestions: !obscureText,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: suffixIcon,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isDark, String language) {
    return KeyedSubtree(
      key: const ValueKey('LoginForm'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField(
            controller: _loginEmailController,
            label: _copy(language, 'Email', 'Email'),
            hint: 'you@example.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            isDark: isDark,
          ),
          const SizedBox(height: 15),
          _buildField(
            controller: _loginPasswordController,
            label: _copy(language, 'Password', 'Password'),
            hint: _copy(
              language,
              'Enter your password',
              'Ilagay ang iyong password',
            ),
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureLoginPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) {
              if (!_isLoading) _handleLogin();
            },
            isDark: isDark,
            suffixIcon: _passwordVisibilityButton(
              language,
              _obscureLoginPassword,
              () => setState(
                () => _obscureLoginPassword = !_obscureLoginPassword,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _handlePasswordReset,
              child: Text(
                _copy(
                  language,
                  'Forgot password?',
                  'Nakalimutan ang password?',
                ),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ),
          const SizedBox(height: 7),
          _buildPrimaryButton(
            _copy(
              language,
              'Login',
              'Mag-login',
            ),
            _handleLogin,
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(bool isDark, String language) {
    return KeyedSubtree(
      key: const ValueKey('RegisterForm'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField(
            controller: _regNameController,
            label: _copy(
              language,
              'What should we call you?',
              'Ano ang gusto mong itawag namin sa iyo?',
            ),
            hint: _copy(language, 'Your name', 'Iyong pangalan'),
            icon: Icons.person_outline_rounded,
            autofillHints: const [AutofillHints.name],
            isDark: isDark,
          ),
          const SizedBox(height: 15),
          _buildField(
            controller: _regEmailController,
            label: _copy(language, 'Email', 'Email'),
            hint: 'you@example.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            isDark: isDark,
          ),
          const SizedBox(height: 15),
          _buildField(
            controller: _regPasswordController,
            label: _copy(
              language,
              'Create a password',
              'Gumawa ng password',
            ),
            hint: _copy(
              language,
              'At least 6 characters',
              'Hindi bababa sa 6 na character',
            ),
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureRegPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) {
              if (!_isLoading) _handleRegister();
            },
            isDark: isDark,
            suffixIcon: _passwordVisibilityButton(
              language,
              _obscureRegPassword,
              () => setState(
                () => _obscureRegPassword = !_obscureRegPassword,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _buildPrimaryButton(
            _copy(
              language,
              'Register',
              'Mag-register',
            ),
            _handleRegister,
          ),
        ],
      ),
    );
  }

  Widget _passwordVisibilityButton(
    String language,
    bool obscure,
    VoidCallback onPressed,
  ) {
    return IconButton(
      tooltip: obscure
          ? _copy(language, 'Show password', 'Ipakita ang password')
          : _copy(language, 'Hide password', 'Itago ang password'),
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildPrimaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.honeyAmber,
          foregroundColor: AppColors.onHoney,
          disabledBackgroundColor: AppColors.honeyAmber.withValues(alpha: 0.35),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isLoading
              ? Row(
                  key: ValueKey('auth-loading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const KaibiganLoadingMark(
                      color: AppColors.onHoney,
                      compact: true,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _loadingLabel ?? 'Please wait…',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  key: ValueKey(label),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.textSecondaryDark : AppColors.sageGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackdropPainter extends CustomPainter {
  const _AuthBackdropPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final honey = Paint()
      ..color = AppColors.pollenGlow.withValues(alpha: isDark ? 0.035 : 0.18);
    final sage = Paint()
      ..color = AppColors.sageGreen.withValues(alpha: isDark ? 0.035 : 0.055);
    canvas.drawCircle(
        Offset(size.width * 0.07, size.height * 0.14), 150, honey);
    canvas.drawCircle(
      Offset(size.width * 0.93, size.height * 0.88),
      190,
      sage,
    );
  }

  @override
  bool shouldRepaint(covariant _AuthBackdropPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
