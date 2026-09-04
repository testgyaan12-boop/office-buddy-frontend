import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import 'models/auth_models.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error, emailUnverified }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final String? verifyEmailMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.verifyEmailMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    String? verifyEmailMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      verifyEmailMessage: verifyEmailMessage ?? this.verifyEmailMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final SecureStorage _secureStorage;

  AuthNotifier(this._apiClient, this._secureStorage)
      : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _secureStorage.getToken();
    if (token != null) {
      final userData = await _secureStorage.getUserData();
      if (userData != null) {
        final user = UserModel.fromJson(jsonDecode(userData));
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: LoginRequest(email: email, password: password).toJson(),
      );
      final authResponse = AuthResponse.fromJson(response.data);
      await _secureStorage.saveToken(authResponse.token);
      await _secureStorage.saveRefreshToken(authResponse.refreshToken);
      await _secureStorage.saveUserData(jsonEncode(authResponse.user.toJson()));
      state = AuthState(
        status: AuthStatus.authenticated,
        user: authResponse.user,
      );
    } catch (e) {
      final msg = _extractError(e);
      if (msg.toLowerCase().contains('verify')) {
        state = AuthState(
          status: AuthStatus.emailUnverified,
          error: msg,
          user: UserModel(id: '', name: '', email: email),
        );
      } else {
        state = AuthState(
          status: AuthStatus.error,
          error: msg,
        );
      }
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: RegisterRequest(name: name, email: email, password: password)
            .toJson(),
      );
      final message = response.data['message'] as String? ?? 'Registration successful';
      state = AuthState(
        status: AuthStatus.unauthenticated,
        verifyEmailMessage: message,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        error: _extractError(e),
      );
    }
  }

  Future<void> verifyEmail(String token) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _apiClient.post(
        ApiEndpoints.verifyEmail,
        data: VerifyEmailRequest(token: token).toJson(),
      );
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        verifyEmailMessage: 'Email verified successfully! You can now log in.',
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        error: _extractError(e),
      );
    }
  }

  Future<void> resendVerification(String email) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _apiClient.post(
        ApiEndpoints.resendVerification,
        data: ResendVerificationRequest(email: email).toJson(),
      );
      state = AuthState(
        status: AuthStatus.emailUnverified,
        verifyEmailMessage: response.data['message'] as String? ?? 'Verification email resent',
        user: UserModel(id: '', name: '', email: email),
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.emailUnverified,
        error: _extractError(e),
      );
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _apiClient.post(
        ApiEndpoints.forgotPassword,
        data: ForgotPasswordRequest(email: email).toJson(),
      );
      state = AuthState(
        status: AuthStatus.unauthenticated,
        verifyEmailMessage: 'If this email is registered, you will receive a password reset OTP.',
        user: UserModel(id: '', name: '', email: email),
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        error: _extractError(e),
      );
    }
  }

  Future<String> resetPassword(String email, String otp, String newPassword) async {
    try {
      await _apiClient.post(
        ApiEndpoints.resetPassword,
        data: ResetPasswordRequest(email: email, otp: otp, newPassword: newPassword).toJson(),
      );
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        verifyEmailMessage: 'Password reset successfully! You can now log in.',
      );
      return '';
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<void> updateProfile({
    required String name,
    String? headline,
    String? dateOfBirth,
    String? gender,
    String? phone,
    String? currentCompany,
    String? salary,
    String? expectedSalary,
    String? skills,
    String? address,
    String? bloodGroup,
    String? linkedInUrl,
    String? portfolioUrl,
    String? panNumber,
    String? aadhaarNumber,
    String? uanNumber,
    String? pfNumber,
    String? bankAccountNumber,
    String? ifscCode,
    String? emergencyContact,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
      };
      if (headline != null) data['headline'] = headline;
      if (dateOfBirth != null) data['dateOfBirth'] = dateOfBirth;
      if (gender != null) data['gender'] = gender;
      if (phone != null) data['phone'] = phone;
      if (currentCompany != null) data['currentCompany'] = currentCompany;
      if (salary != null) data['salary'] = salary;
      if (expectedSalary != null) data['expectedSalary'] = expectedSalary;
      if (skills != null) data['skills'] = skills;
      if (address != null) data['address'] = address;
      if (bloodGroup != null) data['bloodGroup'] = bloodGroup;
      if (linkedInUrl != null) data['linkedInUrl'] = linkedInUrl;
      if (portfolioUrl != null) data['portfolioUrl'] = portfolioUrl;
      if (panNumber != null) data['panNumber'] = panNumber;
      if (aadhaarNumber != null) data['aadhaarNumber'] = aadhaarNumber;
      if (uanNumber != null) data['uanNumber'] = uanNumber;
      if (pfNumber != null) data['pfNumber'] = pfNumber;
      if (bankAccountNumber != null) data['bankAccountNumber'] = bankAccountNumber;
      if (ifscCode != null) data['ifscCode'] = ifscCode;
      if (emergencyContact != null) data['emergencyContact'] = emergencyContact;

      final response = await _apiClient.put(
        ApiEndpoints.userProfile,
        data: data,
      );
      final updatedUser = UserModel.fromJson(response.data);
      await _secureStorage.saveUserData(jsonEncode(updatedUser.toJson()));
      state = AuthState(status: AuthStatus.authenticated, user: updatedUser);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        user: state.user,
        error: _extractError(e),
      );
    }
  }

  Future<void> uploadAvatar(Uint8List bytes, String fileName) async {
    try {
      final response = await _apiClient.uploadFile(
        '${ApiEndpoints.userProfile}/avatar',
        fileBytes: bytes,
        fileName: fileName,
        fileField: 'file',
      );
      final updatedUser = UserModel.fromJson(response.data);
      await _secureStorage.saveUserData(jsonEncode(updatedUser.toJson()));
      state = AuthState(status: AuthStatus.authenticated, user: updatedUser);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        user: state.user,
        error: _extractError(e),
      );
    }
  }

  Future<String?> changePassword(String currentPassword, String newPassword) async {
    try {
      await _apiClient.put(
        ApiEndpoints.changePassword,
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<bool> hasPinSet() => _secureStorage.hasPin();

  Future<String?> loginWithPin(String pin) async {
    final saved = await _secureStorage.getPin();
    if (saved == null || saved != pin) {
      state = const AuthState(status: AuthStatus.error, error: 'Incorrect PIN');
      return 'Incorrect PIN';
    }
    final refreshed = await _apiClient.tryRefresh();
    if (refreshed) {
      await _checkAuth();
      if (state.status == AuthStatus.authenticated) return null;
    }
    // Fallback: if refresh failed but token still valid locally, use cached user
    final token = await _secureStorage.getToken();
    if (token != null) {
      await _checkAuth();
      if (state.status == AuthStatus.authenticated) return null;
    }
    state = const AuthState(status: AuthStatus.error, error: 'Session expired, please login with password');
    return 'Session expired, please login with password';
  }

  Future<void> logout() async {
    await _secureStorage.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _extractError(Object e) {
    try {
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data['message'] is String && (data['message'] as String).isNotEmpty) return data['message'] as String;
        if (data['error'] is String && (data['error'] as String).isNotEmpty) return data['error'] as String;
        if (data['errors'] is String && (data['errors'] as String).isNotEmpty) {
          // Backend sends errors as "{field=msg, ...}" — show first msg already in 'message', keep fallback
          return data['errors'] as String;
        }
        // Handle errors as Map (rare)
        if (data['errors'] is Map && (data['errors'] as Map).isNotEmpty) {
          return (data['errors'] as Map).values.first.toString();
        }
      }
      if (e is DioException && e.response?.data is String) {
        final s = e.response!.data as String;
        if (s.isNotEmpty) return s;
      }
    } catch (_) {}
    final str = e.toString();
    final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(str);
    if (match != null) return match.group(1)!;
    final errMatch = RegExp(r'"error"\s*:\s*"([^"]+)"').firstMatch(str);
    if (errMatch != null) return errMatch.group(1)!;
    return 'Something went wrong. Please try again.';
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(apiClientProvider),
    ref.read(secureStorageProvider),
  );
});
