import 'package:dio/dio.dart';
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
    final response = await _dio.post(
      '/api/auth/login',
      data: {'username': username, 'password': password},
    );

    final payload = _asMap(response.data);
    final token =
        payload['token']?.toString() ?? payload['jwt']?.toString() ?? '';
    final roleValues = (payload['roles'] as List<dynamic>?) ?? const [];
    final roles = roleValues.map((e) => e.toString()).toList();
    final userId =
        payload['userId']?.toString() ??
        payload['username']?.toString() ??
        username;

    if (token.isEmpty || roles.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Invalid login response. Expected token and roles.',
      );
    }

    return AuthSession(
      token: token,
      userId: userId,
      username: username,
      roles: roles,
    );
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {};
  }
}
