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

  Future<bool> register(String name, String email, String password) async {
    status = AuthStatus.loading;
    errorMessage = null;
    _notify();

    try {
      final response = await _dio.post(
        Endpoints.register,
        data: {'name': name, 'email': email, 'password': password},
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
