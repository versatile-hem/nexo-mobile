import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../constants/app_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        if (session != null) 'Authorization': 'Bearer ${session.token}',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final latestSession = ref.read(authControllerProvider).valueOrNull;
        if (latestSession != null) {
          options.headers['Authorization'] = 'Bearer ${latestSession.token}';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          ref.read(authControllerProvider.notifier).logout(silent: true);
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
