import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/endpoints.dart';
import '../core/router/router_refresh_notifier.dart';

enum AuthStatus { unauthenticated, loading, authenticated }

class AuthUser {
  final String id;
  final String name;
  final String profilePic;
  final String email;
  final String token;

  AuthUser({
    required this.id,
    required this.name,
    required this.profilePic,
    required this.email,
    required this.token,
  });

  factory AuthUser.fromJson(Map<String, dynamic>? json, String token) {
    if (json == null) {
      return AuthUser(id: '', name: 'Unknown', email: '', token: token, profilePic: '');
    }
    return AuthUser(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? 'User',
      profilePic: json['profilePicture'] as String? ?? '',
      email: json['email'] as String? ?? '',
      token: token,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({RouterRefreshNotifier? routerRefresh})
      : _routerRefresh = routerRefresh;

  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
  final RouterRefreshNotifier? _routerRefresh;

  void _notify() {
    notifyListeners();
    _routerRefresh?.refresh();
  }

  AuthStatus status = AuthStatus.unauthenticated;
  AuthUser? user;
  String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  String _humanizeApiMessage(String? raw, {required String fallback}) {
    final msg = (raw ?? '').trim();
    if (msg.isEmpty) return fallback;

    final lower = msg.toLowerCase();
    if (lower.contains('incorrect password') || lower.contains('invalid password')) {
      return 'That password does not match this account. Please try again.';
    }
    if (lower.contains('user not found') || lower.contains('email not found')) {
      return 'No account was found with this email address.';
    }
    if (lower.contains('already exists') || lower.contains('email already')) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    if (lower.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    if (lower.contains('invalid credentials')) {
      return 'Email or password is incorrect. Please try again.';
    }
    if (lower.contains('token') && lower.contains('expired')) {
      return 'Your session expired. Please sign in again.';
    }
    if (lower.contains('verify your email') || lower.contains('email not verified')) {
      return msg;
    }

    return msg;
  }

  Future<bool> login(String email, String password) async {
    status = AuthStatus.loading;
    errorMessage = null;
    _notify();

    try {
      final response = await _dio.post(
        Endpoints.login,
        data: {'email': email, 'password': password},
      );

      final result = response.data;

      if (response.statusCode == 200 && result['success'] == true) {
        final data = result['data'];
        if (data == null) {
          throw Exception('No data received from server');
        }

        // Handle both nested and direct structures
        final token = data['token']?.toString() ?? '';
        final userData = (data['user'] is Map) ? data['user'] as Map<String, dynamic> : data as Map<String, dynamic>;

        user = AuthUser.fromJson(userData, token);
        status = AuthStatus.authenticated;
        _notify();
        return true;
      } else {
        errorMessage = _humanizeApiMessage(
          result['message']?.toString(),
          fallback: 'Login failed. Please check your credentials.',
        );
        status = AuthStatus.unauthenticated;
        _notify();
        return false;
      }
    } catch (e) {
      _handleAuthError(e);
      return false;
    }
  }

  String? _registerSuccessMessage;
  String? get registerSuccessMessage => _registerSuccessMessage;

  void clearRegisterSuccess() {
    _registerSuccessMessage = null;
    notifyListeners();
  }

  Future<bool> register(String name, String email, String password) async {
    status = AuthStatus.loading;
    errorMessage = null;
    _registerSuccessMessage = null;
    _notify();

    try {
      final response = await _dio.post(
        Endpoints.register,
        data: {'name': name, 'email': email, 'password': password},
      );

      final result = response.data;

      if (response.statusCode == 200 && result['success'] == true) {
        _registerSuccessMessage = result['message']?.toString() ??
            'Account created! Check your email to verify before signing in.';
        status = AuthStatus.unauthenticated;
        _notify();
        return true;
      } else {
        errorMessage = _humanizeApiMessage(
          result['message']?.toString(),
          fallback: 'Registration failed. Please try again.',
        );
        status = AuthStatus.unauthenticated;
        _notify();
        return false;
      }
    } catch (e) {
      _handleAuthError(e);
      return false;
    }
  }

  // ── Email verification ──

  bool _verifyEmailLoading = false;
  bool get verifyEmailLoading => _verifyEmailLoading;

  String? _verifyEmailMessage;
  String? get verifyEmailMessage => _verifyEmailMessage;

  bool? _verifyEmailSuccess;
  bool? get verifyEmailSuccess => _verifyEmailSuccess;

  Future<bool> verifyEmail(String token) async {
    _verifyEmailLoading = true;
    _verifyEmailSuccess = null;
    _verifyEmailMessage = null;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _dio.post(
        Endpoints.verifyEmail,
        data: {'token': token},
      );

      final result = response.data;

      if (response.statusCode == 200 && result['success'] == true) {
        _verifyEmailSuccess = true;
        _verifyEmailMessage =
            result['message']?.toString() ?? 'Email verified successfully!';
        _verifyEmailLoading = false;
        notifyListeners();
        return true;
      } else {
        _verifyEmailSuccess = false;
        _verifyEmailMessage = result['message']?.toString() ??
            'Verification failed. The link may be invalid or expired.';
        _verifyEmailLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _verifyEmailSuccess = false;
      _verifyEmailLoading = false;
      if (e is DioException && e.response?.data is Map) {
        _verifyEmailMessage = e.response?.data['message']?.toString() ??
            'Verification failed. Please try again.';
      } else {
        _verifyEmailMessage = 'Could not connect to server. Please try again.';
      }
      notifyListeners();
      return false;
    }
  }

  bool _resendLoading = false;
  bool get resendLoading => _resendLoading;

  String? _resendMessage;
  String? get resendMessage => _resendMessage;

  Future<bool> resendVerificationEmail(String email) async {
    _resendLoading = true;
    _resendMessage = null;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _dio.post(
        Endpoints.resendVerificationEmail,
        data: {'email': email},
      );

      final result = response.data;

      if (response.statusCode == 200 && result['success'] == true) {
        _resendMessage = result['message']?.toString() ??
            'Verification email sent. Check your inbox.';
        _resendLoading = false;
        notifyListeners();
        return true;
      } else {
        _resendMessage = result['message']?.toString() ??
            'Could not send verification email.';
        _resendLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _resendLoading = false;
      if (e is DioException && e.response?.data is Map) {
        _resendMessage = e.response?.data['message']?.toString() ??
            'Failed to resend. Please try again.';
      } else {
        _resendMessage = 'Could not connect to server. Please try again.';
      }
      notifyListeners();
      return false;
    }
  }

  void clearResendState() {
    _resendLoading = false;
    _resendMessage = null;
    notifyListeners();
  }

  void clearVerifyEmailState() {
    _verifyEmailLoading = false;
    _verifyEmailSuccess = null;
    _verifyEmailMessage = null;
    notifyListeners();
  }

  void _handleAuthError(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timed out. Please check your internet.';
      } else if (e.response?.data != null && e.response?.data is Map) {
        errorMessage = _humanizeApiMessage(
          e.response?.data['message']?.toString(),
          fallback: 'Server error: ${e.response?.statusCode}',
        );
      } else {
        errorMessage = 'Network error: ${e.message}';
      }
    } else if (e is TypeError) {
      errorMessage = 'Data parsing error. Please contact support.';
      debugPrint('Parsing error: $e');
    } else {
      errorMessage = 'An unexpected error occurred: ${e.toString()}';
    }
    status = AuthStatus.unauthenticated;
    _notify();
  }

  // ── Forgot-password flow ──

  bool _forgotLoading = false;
  bool get forgotLoading => _forgotLoading;

  String? _forgotSuccessMessage;
  String? get forgotSuccessMessage => _forgotSuccessMessage;

  Future<bool> requestPasswordReset(String email) async {
    _forgotLoading = true;
    _forgotSuccessMessage = null;
    errorMessage = null;
    _notify();

    try {
      final response = await _dio.post(
        Endpoints.forgetPassword,
        data: {'email': email},
      );

      final result = response.data;

      if (response.statusCode == 200 && result['success'] == true) {
        _forgotSuccessMessage =
            result['message']?.toString() ?? 'Check your email for a reset link.';
        _forgotLoading = false;
        _notify();
        return true;
      } else {
        errorMessage = _humanizeApiMessage(
          result['message']?.toString(),
          fallback: 'Could not send reset email. Please try again.',
        );
        _forgotLoading = false;
        _notify();
        return false;
      }
    } catch (e) {
      _forgotLoading = false;
      _handleAuthError(e);
      return false;
    }
  }

  Future<bool> verifyResetToken(String token) async {
    _forgotLoading = true;
    errorMessage = null;
    _notify();

    try {
      final response = await _dio.post(
        Endpoints.verifyResetToken,
        data: {'token': token},
      );

      final result = response.data;

      if (response.statusCode == 200 && result['success'] == true) {
        _forgotLoading = false;
        _notify();
        return true;
      } else {
        errorMessage = _humanizeApiMessage(
          result['message']?.toString(),
          fallback: 'Invalid or expired token.',
        );
        _forgotLoading = false;
        _notify();
        return false;
      }
    } catch (e) {
      _forgotLoading = false;
      _handleAuthError(e);
      return false;
    }
  }

  Future<bool> changePassword(String token, String newPassword) async {
    _forgotLoading = true;
    errorMessage = null;
    _notify();

    try {
      final response = await _dio.post(
        Endpoints.changePassword,
        data: {'token': token, 'newPassword': newPassword},
      );

      final result = response.data;

      if (response.statusCode == 200 && result['success'] == true) {
        _forgotSuccessMessage =
            result['message']?.toString() ?? 'Password changed successfully.';
        _forgotLoading = false;
        _notify();
        return true;
      } else {
        errorMessage = _humanizeApiMessage(
          result['message']?.toString(),
          fallback: 'Could not change password. Please try again.',
        );
        _forgotLoading = false;
        _notify();
        return false;
      }
    } catch (e) {
      _forgotLoading = false;
      _handleAuthError(e);
      return false;
    }
  }

  void clearForgotState() {
    _forgotLoading = false;
    _forgotSuccessMessage = null;
    notifyListeners();
  }

  // ── General ──

  void logout() {
    user = null;
    status = AuthStatus.unauthenticated;
    errorMessage = null;
    _notify();
  }

  void clearError() {
    errorMessage = null;
    _notify();
  }
}
