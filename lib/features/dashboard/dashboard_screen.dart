import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../../widgets/dashboard_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final roles = session?.roles ?? const <String>[];
    final isOperationManager = roles.contains('operation_manager');
    final isFse = roles.contains('field_sales_executive');

    final tiles = <DashboardItem>[
      if (isOperationManager)
        const DashboardItem(
          title: 'Stock In',
          subtitle: 'Receive stock quickly',
          icon: Icons.move_to_inbox_rounded,
          route: '/stock-in',
        ),
      if (isOperationManager)
        const DashboardItem(
          title: 'Daily Operations',
          subtitle: 'Dispatch and channel ops',
          icon: Icons.local_shipping_outlined,
          route: '/daily-operations',
        ),
      if (isFse)
        const DashboardItem(
          title: 'Take Order',
          subtitle: 'Create sales order',
          icon: Icons.receipt_long_outlined,
          route: '/create-order',
        ),
      if (isFse)
        const DashboardItem(
          title: 'My Orders',
          subtitle: 'Track order status',
          icon: Icons.list_alt_outlined,
          route: '/my-orders',
        ),
      if (isFse)
        const DashboardItem(
          title: 'Payments',
          subtitle: 'Capture collections',
          icon: Icons.payments_outlined,
          route: '/payments',
        ),
      if (isFse)
        const DashboardItem(
          title: 'My Commission',
          subtitle: 'Monthly performance',
          icon: Icons.currency_rupee_outlined,
          route: '/commission',
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            itemCount: tiles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final item = tiles[index];
              return DashboardTile(
                title: item.title,
                subtitle: item.subtitle,
                icon: item.icon,
                onTap: () => context.push(item.route),
              );
            },
          ),
        ),
      ),
    );
  }
}

class DashboardItem {
  const DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}
