import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/constants/app_colors.dart';
import '../../core/storage/secure_storage.dart';
import '../auth/auth_provider.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _pinController = TextEditingController();
  final _localAuth = LocalAuthentication();
  bool _biometricAvailable = false;
  bool _isBiometricEnabled = false;
  String? _error;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = ref.read(secureStorageProvider);
    final bioOn = await storage.isBiometricEnabled();
    final canCheck = await _localAuth.canCheckBiometrics;
    final types = await _localAuth.getAvailableBiometrics();
    final supported = await _localAuth.isDeviceSupported();
    if (!mounted) return;
    setState(() {
      _isBiometricEnabled = bioOn;
      _biometricAvailable = canCheck && types.isNotEmpty && supported;
      _checking = false;
    });
    if (_isBiometricEnabled && _biometricAvailable) {
      Future.delayed(const Duration(milliseconds: 400), () => _authenticateBiometric());
    }
  }

  Future<void> _authenticateBiometric() async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Unlock OfficeBuddy',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (ok && mounted) {
        final pin = await ref.read(secureStorageProvider).getPin();
        if (pin != null) {
          final err = await ref.read(authProvider.notifier).loginWithPin(pin);
          if (err == null && mounted) {
            context.go('/');
            return;
          }
        }
        if (mounted) context.go('/');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Biometric failed');
    }
  }

  Future<void> _verifyPin(String pin) async {
    if (pin.length != 4) {
      setState(() => _error = 'Enter 4-digit PIN');
      return;
    }
    final err = await ref.read(authProvider.notifier).loginWithPin(pin);
    if (err == null && mounted) {
      context.go('/');
    } else if (mounted) {
      setState(() {
        _error = err ?? 'Incorrect PIN';
        _pinController.clear();
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)]),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Center(child: Icon(Icons.lock, color: Colors.white, size: 32)),
                ),
                const SizedBox(height: 16),
                const Text('App Locked', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Enter your PIN to unlock', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      const Text('Enter PIN', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 16),
                      PinCodeTextField(
                        appContext: context,
                        length: 4,
                        controller: _pinController,
                        obscureText: true,
                        obscuringCharacter: '●',
                        animationType: AnimationType.fade,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(8),
                          fieldHeight: 50,
                          fieldWidth: 45,
                          activeFillColor: Colors.white,
                          inactiveFillColor: Colors.white,
                          selectedFillColor: AppColors.primary.withValues(alpha: 0.05),
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.textLight.withValues(alpha: 0.3),
                          selectedColor: AppColors.primary,
                        ),
                        enableActiveFill: true,
                        onCompleted: _verifyPin,
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [const Icon(Icons.error_outline, color: AppColors.error, size: 16), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)))]),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _verifyPin(_pinController.text.trim()),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: const Text('Unlock', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      if (_biometricAvailable && _isBiometricEnabled) ...[
                        const SizedBox(height: 16),
                        const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR')), Expanded(child: Divider())]),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _authenticateBiometric,
                            icon: const Icon(Icons.fingerprint, color: AppColors.primary),
                            label: const Text('Unlock with Biometric'),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () async {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) context.go('/auth');
                        },
                        child: const Text('Login with Email & Password', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
