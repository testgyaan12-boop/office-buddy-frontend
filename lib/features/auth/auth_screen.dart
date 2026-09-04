import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/constants/app_colors.dart';
import '../../core/storage/secure_storage.dart';
import '../../shared/widgets/password_field.dart';
import 'auth_provider.dart';

enum AuthPage { login, register, verifyEmail, forgotPassword, resetPassword }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  AuthPage _page = AuthPage.login;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _otpController = TextEditingController();
  final _verifyTokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewController = TextEditingController();
  final _pinLoginController = TextEditingController();
  final _localAuth = LocalAuthentication();
  String _storedEmail = '';
  bool _obscurePassword = true;
  bool _showPinLogin = false;
  bool _hasPin = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String? _pinError;

  @override
  void initState() {
    super.initState();
    _loadPinState();
  }

  Future<void> _loadPinState() async {
    final storage = ref.read(secureStorageProvider);
    final hasPin = await storage.hasPin();
    final bioOn = await storage.isBiometricEnabled();
    bool bioAvail = false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final types = await _localAuth.getAvailableBiometrics();
      final supported = await _localAuth.isDeviceSupported();
      bioAvail = canCheck && types.isNotEmpty && supported;
    } catch (_) {}
    if (mounted) {
      setState(() {
        _hasPin = hasPin;
        _biometricEnabled = bioOn;
        _biometricAvailable = bioAvail;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _otpController.dispose();
    _verifyTokenController.dispose();
    _newPasswordController.dispose();
    _confirmNewController.dispose();
    _pinLoginController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/');
      }
      if (next.status == AuthStatus.emailUnverified && _page == AuthPage.login) {
        _storedEmail = _emailController.text.trim();
        setState(() => _page = AuthPage.verifyEmail);
      }
      if (next.status == AuthStatus.unauthenticated && next.verifyEmailMessage != null && _page == AuthPage.register) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.verifyEmailMessage!),
              backgroundColor: AppColors.success,
            ),
          );
        });
        setState(() => _page = AuthPage.login);
      }
      if (next.status == AuthStatus.unauthenticated && next.verifyEmailMessage != null && _page == AuthPage.verifyEmail && next.verifyEmailMessage!.toLowerCase().contains('verified successfully')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.verifyEmailMessage!),
              backgroundColor: AppColors.success,
            ),
          );
        });
        setState(() => _page = AuthPage.login);
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildCard(authState),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text(
              'OB',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'OfficeBuddy',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _pageSubtitle(),
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  String _pageSubtitle() {
    switch (_page) {
      case AuthPage.login:
        return 'Welcome back! Sign in to continue';
      case AuthPage.register:
        return 'Create your account to get started';
      case AuthPage.verifyEmail:
        return 'Check your email to verify your account';
      case AuthPage.forgotPassword:
        return 'Enter your email to receive a reset OTP';
      case AuthPage.resetPassword:
        return 'Enter the OTP and set a new password';
    }
  }

  Widget _buildCard(AuthState authState) {
    switch (_page) {
      case AuthPage.login:
        return _buildLoginCard(authState);
      case AuthPage.register:
        return _buildRegisterCard(authState);
      case AuthPage.verifyEmail:
        return _buildVerifyCard(authState);
      case AuthPage.forgotPassword:
        return _buildForgotCard(authState);
      case AuthPage.resetPassword:
        return _buildResetCard(authState);
    }
  }

  Widget _buildLoginCard(AuthState authState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.login_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textLight),
                hintText: 'Email address',
                hintStyle: const TextStyle(color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              validator: (v) => (v == null || v.trim().isEmpty || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textLight),
                hintText: 'Password',
                hintStyle: const TextStyle(color: AppColors.textLight),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textLight, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _formKey.currentState?.reset();
                  setState(() => _page = AuthPage.forgotPassword);
                },
                child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ),
            ),
            if (authState.status == AuthStatus.error || authState.status == AuthStatus.emailUnverified)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(authState.error ?? '', style: const TextStyle(color: AppColors.error, fontSize: 13))),
                      ],
                    ),
                    if (authState.status == AuthStatus.emailUnverified)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GestureDetector(
                          onTap: () {
                            _storedEmail = _emailController.text.trim();
                            setState(() => _page = AuthPage.verifyEmail);
                          },
                          child: const Text('Verify Email', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: authState.status == AuthStatus.loading ? null : _onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: authState.status == AuthStatus.loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            if (_hasPin) ...[
              const SizedBox(height: 12),
              Row(children: [Expanded(child: Divider(color: AppColors.textLight.withValues(alpha: 0.2))), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.w600))), Expanded(child: Divider(color: AppColors.textLight.withValues(alpha: 0.2)))]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showPinLogin = !_showPinLogin),
                  icon: Icon(_showPinLogin ? Icons.close_rounded : Icons.lock_rounded, size: 18, color: AppColors.primary),
                  label: Text(_showPinLogin ? 'Hide PIN Login' : 'Login with PIN', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              if (_showPinLogin) ...[
                const SizedBox(height: 12),
                PinCodeTextField(
                  appContext: context,
                  length: 4,
                  controller: _pinLoginController,
                  obscureText: true,
                  obscuringCharacter: '●',
                  animationType: AnimationType.fade,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(8),
                    fieldHeight: 48,
                    fieldWidth: 45,
                    activeFillColor: Colors.white,
                    inactiveFillColor: AppColors.background,
                    selectedFillColor: AppColors.primary.withValues(alpha: 0.05),
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.textLight.withValues(alpha: 0.3),
                    selectedColor: AppColors.primary,
                  ),
                  enableActiveFill: true,
                  onCompleted: (_) => _onPinLogin(),
                  onChanged: (_) {
                    if (_pinError != null) setState(() => _pinError = null);
                  },
                ),
                if (_pinError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                    child: Text(_pinError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authState.status == AuthStatus.loading ? null : _onPinLogin,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: authState.status == AuthStatus.loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Unlock with PIN', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
              if (_biometricAvailable && _biometricEnabled) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _onBiometricLogin,
                    icon: const Icon(Icons.fingerprint, color: AppColors.primary, size: 20),
                    label: const Text('Login with Biometric', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                TextButton(
                  onPressed: () {
                    _formKey.currentState?.reset();
                    setState(() => _page = AuthPage.register);
                  },
                  child: const Text('Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterCard(AuthState authState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_rounded, color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.textLight),
                hintText: 'Full name',
                hintStyle: const TextStyle(color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textLight),
                hintText: 'Email address',
                hintStyle: const TextStyle(color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              validator: (v) => (v == null || v.trim().isEmpty || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 14),
            PasswordField(controller: _passwordController),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textLight),
                hintText: 'Confirm password',
                hintStyle: const TextStyle(color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              validator: (v) => (v != _passwordController.text) ? 'Passwords do not match' : null,
            ),
            if (authState.status == AuthStatus.error)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(authState.error ?? '', style: const TextStyle(color: AppColors.error, fontSize: 13))),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: authState.status == AuthStatus.loading ? null : _onRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: authState.status == AuthStatus.loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account?', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                TextButton(
                  onPressed: () {
                    _formKey.currentState?.reset();
                    setState(() => _page = AuthPage.login);
                  },
                  child: const Text('Sign In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyCard(AuthState authState) {
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : authState.user?.email ?? _storedEmail;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.mark_email_unread_rounded, size: 56, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'Check Your Email',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            authState.verifyEmailMessage ?? 'We sent a verification link to',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
          const SizedBox(height: 24),
          TextFormField(
            controller: _verifyTokenController,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, letterSpacing: 4, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Paste verification token',
              hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: authState.status == AuthStatus.loading ? null : _onVerify,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: authState.status == AuthStatus.loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Text('Verify Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: authState.status == AuthStatus.loading ? null : () => ref.read(authProvider.notifier).resendVerification(email),
            child: const Text('Resend Email', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
          if (authState.status == AuthStatus.error)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(authState.error ?? '', style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _formKey.currentState?.reset();
              setState(() => _page = AuthPage.login);
            },
            child: const Text('Back to Sign In', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotCard(AuthState authState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Icon(Icons.lock_reset_rounded, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Reset Password',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your email and we\'ll send you a password reset OTP',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textLight),
                hintText: 'Email address',
                hintStyle: const TextStyle(color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              validator: (v) => (v == null || v.trim().isEmpty || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            if (authState.status == AuthStatus.error)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Text(authState.error ?? '', style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: authState.status == AuthStatus.loading ? null : _onForgot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: authState.status == AuthStatus.loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('Send OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _formKey.currentState?.reset();
                setState(() => _page = AuthPage.login);
              },
              child: const Text('Back to Sign In', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetCard(AuthState authState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Icon(Icons.lock_open_rounded, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Enter OTP & New Password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'OTP sent to $_storedEmail',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _otpController,
              textAlign: TextAlign.center,
              maxLength: 6,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 20),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                counterText: '',
              ),
              validator: (v) => (v == null || v.length != 6) ? 'Enter 6-digit OTP' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textLight),
                hintText: 'New password',
                hintStyle: const TextStyle(color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter a new password';
                if (v.length < 8) return 'At least 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmNewController,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textLight),
                hintText: 'Confirm new password',
                hintStyle: const TextStyle(color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              validator: (v) => (v != _newPasswordController.text) ? 'Passwords do not match' : null,
            ),
            if (authState.status == AuthStatus.error)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Text(authState.error ?? '', style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: authState.status == AuthStatus.loading ? null : _onReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: authState.status == AuthStatus.loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('Reset Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _formKey.currentState?.reset();
                setState(() => _page = AuthPage.forgotPassword);
              },
              child: const Text('Resend OTP', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            TextButton(
              onPressed: () {
                _formKey.currentState?.reset();
                setState(() => _page = AuthPage.login);
              },
              child: const Text('Back to Sign In', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  Future<void> _onPinLogin() async {
    final pin = _pinLoginController.text.trim();
    if (pin.length != 4) {
      setState(() => _pinError = 'Enter 4-digit PIN');
      return;
    }
    final err = await ref.read(authProvider.notifier).loginWithPin(pin);
    if (err != null && mounted) {
      setState(() => _pinError = err);
    } else {
      if (mounted) setState(() => _pinError = null);
    }
  }

  Future<void> _onBiometricLogin() async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Login with Biometric',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (!ok) return;
      final pin = await ref.read(secureStorageProvider).getPin();
      if (pin == null) {
        if (mounted) setState(() => _pinError = 'No PIN set');
        return;
      }
      final err = await ref.read(authProvider.notifier).loginWithPin(pin);
      if (err != null && mounted) setState(() => _pinError = err);
    } catch (e) {
      if (mounted) setState(() => _pinError = 'Biometric failed');
    }
  }

  void _onRegister() {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    _storedEmail = email;
    ref.read(authProvider.notifier).register(
      _nameController.text.trim(),
      email,
      _passwordController.text,
    );
  }

  void _onVerify() {
    final token = _verifyTokenController.text.trim();
    if (token.isEmpty) return;
    ref.read(authProvider.notifier).verifyEmail(token);
  }

  void _onForgot() {
    if (!_formKey.currentState!.validate()) return;
    _storedEmail = _emailController.text.trim();
    ref.read(authProvider.notifier).forgotPassword(_storedEmail);
    setState(() => _page = AuthPage.resetPassword);
  }

  void _onReset() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await ref.read(authProvider.notifier).resetPassword(
      _storedEmail,
      _otpController.text.trim(),
      _newPasswordController.text,
    );
    if (error.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }
}
