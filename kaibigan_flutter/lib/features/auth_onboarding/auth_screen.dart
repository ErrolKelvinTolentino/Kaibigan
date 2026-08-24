import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/env_config.dart';
import '../companion/companion_model.dart';
import '../settings/user_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _activeTabIndex = 0; // 0 for Login, 1 for Register

  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();

  bool _obscureLoginPassword = true;
  bool _obscureRegPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _confirmationMessage;
  String? _pendingConfirmationEmail;

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
      _errorMessage = null;
      _confirmationMessage = null;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.login(email: email, password: password);

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        setState(
            () => _errorMessage = userProvider.authError ?? 'Login failed.');
      }
    }
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
      _errorMessage = null;
      _confirmationMessage = null;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.register(
      email: email,
      password: password,
      displayName: name,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        final message = userProvider.authError ?? 'Registration failed.';
        if (message.startsWith('Account created!')) {
          setState(() {
            _errorMessage = null;
            _pendingConfirmationEmail = email;
            _confirmationMessage =
                'Account created. Check your inbox or spam folder, then open the confirmation link while Kaibigan is running on localhost:3000.';
          });
        } else {
          setState(() => _errorMessage = message);
        }
      }
    }
  }

  Future<void> _handleResendConfirmation() async {
    final email = _pendingConfirmationEmail;
    if (email == null || _isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _confirmationMessage = null;
    });
    final provider = context.read<UserProvider>();
    final sent = await provider.resendConfirmation(email);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
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
      _errorMessage = null;
    });
    final provider = context.read<UserProvider>();
    final started = await provider.loginWithGoogle();
    if (!mounted) return;
    if (!started) {
      setState(() {
        _isLoading = false;
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
      _errorMessage = null;
    });
    final provider = context.read<UserProvider>();
    final sent = await provider.resetPassword(email);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (!sent) _errorMessage = provider.authError;
    });
    if (sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Password reset email sent. Check your inbox and spam folder.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final mascot = MascotInfo.getById(userProvider.selectedCompanion);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo & Mascot Header
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.sageGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.sageGreen.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(mascot.materialIcon,
                          color: AppColors.sageGreen, size: 42),
                    ),
                  )
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 16),

                  Text(
                    'Kaibigan',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your AI-Assisted Mental Wellness Companion',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Custom Segmented Toggle (Login / Register)
                  Container(
                    height: 52,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _activeTabIndex = 0;
                              _errorMessage = null;
                              _confirmationMessage = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: _activeTabIndex == 0
                                    ? AppColors.sageGreen
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _activeTabIndex == 0
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _activeTabIndex = 1;
                              _errorMessage = null;
                              _confirmationMessage = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: _activeTabIndex == 1
                                    ? AppColors.sageGreen
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _activeTabIndex == 1
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_confirmationMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.sageGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.sageGreen.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.mark_email_read_outlined,
                                  color: AppColors.sageGreen, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _confirmationMessage!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.sageGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_pendingConfirmationEmail != null) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : _handleResendConfirmation,
                              child: const Text('Resend confirmation email'),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(),
                    const SizedBox(height: 16),
                  ],

                  // Error Alert Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(),
                    const SizedBox(height: 16),
                  ],

                  // Form Container (Animated Switcher between Login & Register)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _activeTabIndex == 0
                        ? _buildLoginForm(isDark)
                        : _buildRegisterForm(isDark),
                  ),
                  if (EnvConfig.googleAuthEnabled) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
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
                        label: const Text('Continue with Google'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool isDark = false,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color:
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          prefixIcon: Icon(prefixIcon, color: AppColors.sageGreen, size: 22),
          suffixIcon: suffixIcon,
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: AppColors.sageGreen, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool isDark) {
    return KeyedSubtree(
      key: const ValueKey('LoginForm'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomTextField(
            controller: _loginEmailController,
            hintText: 'Email Address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildCustomTextField(
            controller: _loginPasswordController,
            hintText: 'Password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureLoginPassword,
            isDark: isDark,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              onPressed: () => setState(
                  () => _obscureLoginPassword = !_obscureLoginPassword),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _handlePasswordReset,
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sageGreen,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: AppColors.sageGreen.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Log In to Kaibigan',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(bool isDark) {
    return KeyedSubtree(
      key: const ValueKey('RegisterForm'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomTextField(
            controller: _regNameController,
            hintText: 'Display Name (e.g. Errol)',
            prefixIcon: Icons.person_outline,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildCustomTextField(
            controller: _regEmailController,
            hintText: 'Email Address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildCustomTextField(
            controller: _regPasswordController,
            hintText: 'Password (min 6 characters)',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureRegPassword,
            isDark: isDark,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              onPressed: () =>
                  setState(() => _obscureRegPassword = !_obscureRegPassword),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sageGreen,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: AppColors.sageGreen.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Create Kaibigan Account',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
