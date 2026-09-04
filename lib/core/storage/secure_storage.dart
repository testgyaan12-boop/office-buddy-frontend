import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

class SecureStorage {
  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';
  static const _pinKey = 'app_pin';
  static const _biometricEnabled = 'biometric_enabled';
  static const _onboardingSeen = 'onboarding_seen';

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveUserData(String data) =>
      _storage.write(key: _userKey, value: data);

  Future<String?> getUserData() => _storage.read(key: _userKey);

  Future<void> savePin(String pin) =>
      _storage.write(key: _pinKey, value: pin);

  Future<String?> getPin() => _storage.read(key: _pinKey);

  Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null;
  }

  Future<void> deletePin() => _storage.delete(key: _pinKey);

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _biometricEnabled, value: enabled.toString());

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _biometricEnabled);
    return val == 'true';
  }

  Future<void> setOnboardingSeen() =>
      _storage.write(key: _onboardingSeen, value: 'true');

  Future<bool> hasSeenOnboarding() async {
    final val = await _storage.read(key: _onboardingSeen);
    return val == 'true';
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    // Keep refresh token, user_data, pin & biometric for PIN login (Option A)
  }
}
