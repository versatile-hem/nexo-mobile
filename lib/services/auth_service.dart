import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_provider.dart';
import '../models/auth_session.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioProvider));
});

class AuthService {
  AuthService(this._dio);

  final Dio _dio;

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    if (kDebugMode) {
      debugPrint('[AUTH] login request username=$username');
    }

    final response = await _dio.post(
      '/api/auth/login',
      data: {'username': username, 'password': password},
    );

    if (kDebugMode) {
      debugPrint('[AUTH] login response status=${response.statusCode}');
      debugPrint('[AUTH] login response data=${response.data}');
    }

    final payload = _asMap(response.data);
    final token =
        payload['token']?.toString() ?? payload['jwt']?.toString() ?? '';
    final roles = _extractRoles(payload);
    final userId =
        payload['userId']?.toString() ??
        payload['username']?.toString() ??
        username;

    if (token.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Invalid login response. Expected token.',
      );
    }

    // Some backends return roles in alternative fields or omit them at login.
    // Fall back to a neutral role so authentication can proceed.
    final safeRoles = roles.isEmpty ? const ['user'] : roles;

    if (kDebugMode) {
      debugPrint('[AUTH] normalized roles=$safeRoles');
    }

    return AuthSession(
      token: token,
      userId: userId,
      username: username,
      roles: safeRoles,
    );
  }

  List<String> _extractRoles(Map<String, dynamic> payload) {
    final directRoles = payload['roles'];
    if (directRoles is List) {
      final values = directRoles
          .map((e) => _normalizeRole(e.toString()))
          .where((e) => e.isNotEmpty)
          .toList();
      if (values.isNotEmpty) {
        return values;
      }
    }

    final authorities = payload['authorities'];
    if (authorities is List) {
      final values = authorities
          .map((e) => _normalizeRole(e.toString()))
          .where((e) => e.isNotEmpty)
          .toList();
      if (values.isNotEmpty) {
        return values;
      }
    }

    final role = payload['role'];
    if (role != null && role.toString().isNotEmpty) {
      final normalized = _normalizeRole(role.toString());
      if (normalized.isNotEmpty) {
        return [normalized];
      }
    }

    return const [];
  }

  String _normalizeRole(String role) {
    final trimmed = role.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final withoutPrefix = trimmed.startsWith('ROLE_')
        ? trimmed.substring(5)
        : trimmed;
    return withoutPrefix.toLowerCase();
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }
}
