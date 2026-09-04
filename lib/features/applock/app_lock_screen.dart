import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
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
  bool _appLockEnabled = false;
  bool _biometricEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
    _checkBiometrics();
  }

  Future<void> _loadState() async {
    final storage = ref.read(secureStorageProvider);
    final hasPin = await storage.hasPin();
    final bioOn = await storage.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _appLockEnabled = hasPin;
        _biometricEnabled = bioOn;
        _loading = false;
      });
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final availableTypes = await _localAuth.getAvailableBiometrics();
      final supported = await _localAuth.isDeviceSupported();
      if (mounted) {
        setState(() => _biometricAvailable = canCheck && availableTypes.isNotEmpty && supported);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _biometricAvailable = false);
      }
    }
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock OfficeBuddy',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      return authenticated;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Biometric failed: $e')));
      }
      return false;
    }
  }

  Future<void> _onAppLockToggle(bool v) async {
    final storage = ref.read(secureStorageProvider);
    if (v) {
      setState(() => _isSettingPin = true);
    } else {
      await storage.deletePin();
      await storage.setBiometricEnabled(false);
      if (mounted) {
        setState(() {
          _appLockEnabled = false;
          _biometricEnabled = false;
          _isSettingPin = false;
          _isConfirming = false;
          _firstPin = null;
          _pinController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App Lock disabled')));
      }
    }
  }

  Future<void> _onBiometricToggle(bool v) async {
    final storage = ref.read(secureStorageProvider);
    if (v) {
      final ok = await _authenticateWithBiometrics();
      if (ok) {
        await storage.setBiometricEnabled(true);
        if (mounted) {
          setState(() => _biometricEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric enabled'), backgroundColor: AppColors.success));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric authentication failed'), backgroundColor: AppColors.error));
      }
    } else {
      await storage.setBiometricEnabled(false);
      if (mounted) {
        setState(() => _biometricEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric disabled')));
      }
    }
  }

  Future<void> _savePin() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN must be exactly 4 digits'), backgroundColor: AppColors.error));
      return;
    }

    if (_isConfirming) {
      if (pin == _firstPin) {
        await ref.read(secureStorageProvider).savePin(pin);
        await ref.read(secureStorageProvider).setBiometricEnabled(_biometricEnabled);
        if (mounted) {
          setState(() {
            _appLockEnabled = true;
            _isSettingPin = false;
            _isConfirming = false;
            _firstPin = null;
            _pinController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN set successfully'), backgroundColor: AppColors.success));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match'), backgroundColor: AppColors.error));
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
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text(AppStrings.appLock)), body: const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appLock)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Security Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('App Lock'),
                    subtitle: const Text('Require PIN to open app'),
                    value: _appLockEnabled,
                    activeColor: AppColors.primary,
                    onChanged: _onAppLockToggle,
                  ),
                  if (_biometricAvailable)
                    SwitchListTile(
                      title: const Text('Fingerprint / Face ID'),
                      subtitle: const Text('Use biometric authentication'),
                      value: _biometricEnabled,
                      activeColor: AppColors.primary,
                      onChanged: _appLockEnabled ? _onBiometricToggle : null,
                    ),
                ],
              ),
            ),
            if (_isSettingPin) ...[
              const SizedBox(height: 24),
              Text(_isConfirming ? 'Confirm PIN' : 'Set your 4-digit PIN', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                onCompleted: (_) => _savePin(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 8),
              Text(_isConfirming ? 'Re-enter 4-digit PIN to confirm' : 'Enter 4-digit PIN', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePin,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(_isConfirming ? 'Confirm' : AppStrings.save),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSettingPin = false;
                    _isConfirming = false;
                    _firstPin = null;
                    _pinController.clear();
                  });
                },
                child: const Text('Cancel'),
              ),
            ],
            if (_appLockEnabled && !_isSettingPin) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [Icon(Icons.lock, size: 16, color: AppColors.success), const SizedBox(width: 8), Text('App Lock is enabled', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13))]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
