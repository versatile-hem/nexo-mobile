import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_storage_service.dart';
import '../../models/auth_session.dart';
import '../../services/auth_service.dart';

final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    final localStorage = ref.read(localStorageProvider);
    return localStorage.getSession();
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(authServiceProvider);
      final storage = ref.read(localStorageProvider);

      final session = await service.login(
        username: username,
        password: password,
      );
      await storage.saveSession(session);
      return session;
    });
  }

  Future<void> logout({bool silent = false}) async {
    final storage = ref.read(localStorageProvider);
    await storage.clearSession();
    if (silent) {
      state = const AsyncData(null);
    } else {
      state = const AsyncValue.data(null);
    }
  }

  bool hasRole(String role) {
    final roles = state.valueOrNull?.roles ?? const <String>[];
    return roles.contains(role);
  }
}
