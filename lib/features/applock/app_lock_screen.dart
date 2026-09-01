import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/storage/secure_storage.dart';
import '../../shared/widgets/app_card.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  final _pinController = TextEditingController();
  final _localAuth = LocalAuthentication();
  bool _isSettingPin = false;
  bool _isConfirming = false;
  String? _firstPin;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      final enrolled = await _localAuth.isDeviceSupported();
      if (mounted) {
        setState(() => _biometricAvailable = available && enrolled);
      }
    } catch (_) {}
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock OfficeBuddy',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (authenticated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric enabled')),
        );
      }
    } catch (_) {}
  }

  Future<void> _savePin() async {
    final pin = _pinController.text;
    if (pin.length < 4) return;

    if (_isConfirming) {
      if (pin == _firstPin) {
        await ref.read(secureStorageProvider).savePin(pin);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN set successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PINs do not match'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _isConfirming = false;
          _firstPin = null;
          _pinController.clear();
        });
      }
    } else {
      setState(() {
        _firstPin = pin;
        _isConfirming = true;
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
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appLock)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('App Lock'),
                    subtitle: const Text('Require PIN to open app'),
                    value: false,
                    activeColor: AppColors.primary,
                    onChanged: (v) async {
                      if (v) {
                        setState(() => _isSettingPin = true);
                      }
                    },
                  ),
                  if (_biometricAvailable)
                    SwitchListTile(
                      title: const Text('Fingerprint / Face ID'),
                      subtitle: const Text('Use biometric authentication'),
                      value: false,
                      activeColor: AppColors.primary,
                      onChanged: (v) {
                        if (v) _authenticateWithBiometrics();
                      },
                    ),
                ],
              ),
            ),
            if (_isSettingPin) ...[
              const SizedBox(height: 24),
              Text(
                _isConfirming ? 'Confirm PIN' : 'Set your PIN',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Enter ${_isConfirming ? 'PIN again' : '4-6 digit PIN'}',
                  prefixIcon: const Icon(Icons.pin),
                ),
                onSubmitted: (_) => _savePin(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isConfirming ? 'Confirm' : AppStrings.save),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
