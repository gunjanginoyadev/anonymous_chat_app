import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/endpoints.dart';

enum AuthStatus { unauthenticated, loading, authenticated }

class AuthUser {
  final String id;
  final String name;
  final String email;
  final String token;

  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.token,
  });

  factory AuthUser.fromJson(Map<String, dynamic>? json, String token) {
    if (json == null) {
      return AuthUser(id: '', name: 'Unknown', email: '', token: token);
    }
    return AuthUser(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      token: token,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  AuthStatus status = AuthStatus.unauthenticated;
  AuthUser? user;
  String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  Future<bool> login(String email, String password) async {
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();

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
        notifyListeners();
        return true;
      } else {
        errorMessage = result['message'] ?? 'Login failed. Please check your credentials.';
        status = AuthStatus.unauthenticated;
        notifyListeners();
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
    notifyListeners();

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
        notifyListeners();
        return true;
      } else {
        errorMessage = result['message'] ?? 'Registration failed. Please try again.';
        status = AuthStatus.unauthenticated;
        notifyListeners();
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
        errorMessage = e.response?.data['message'] ?? 'Server error: ${e.response?.statusCode}';
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
    notifyListeners();
  }

  void logout() {
    user = null;
    status = AuthStatus.unauthenticated;
    errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
