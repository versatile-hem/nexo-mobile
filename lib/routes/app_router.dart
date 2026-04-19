import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/fse/commission_screen.dart';
import '../features/fse/create_order_screen.dart';
import '../features/fse/my_orders_screen.dart';
import '../features/fse/payments_screen.dart';
import '../features/operation/daily_operations_screen.dart';
import '../features/operation/stock_in_screen.dart';
import '../features/splash/splash_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/stock-in',
        builder: (context, state) => const StockInScreen(),
      ),
      GoRoute(
        path: '/daily-operations',
        builder: (context, state) => const DailyOperationsScreen(),
      ),
      GoRoute(
        path: '/create-order',
        builder: (context, state) => const CreateOrderScreen(),
      ),
      GoRoute(
        path: '/my-orders',
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: '/payments',
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        path: '/commission',
        builder: (context, state) => const CommissionScreen(),
      ),
    ],
    redirect: (context, state) {
      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';

      if (authState.isLoading) {
        return isSplash ? null : '/splash';
      }

      final session = authState.valueOrNull;
      if (session == null) {
        return isLogin ? null : '/login';
      }

      if (isLogin || isSplash) {
        return '/dashboard';
      }
      return null;
    },
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Route Error')),
        body: Center(child: Text(state.error.toString())),
      );
    },
  );
});
