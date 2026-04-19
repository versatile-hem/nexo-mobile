import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sales_order.dart';
import '../../services/sales_order_service.dart';
import '../../widgets/app_shell.dart';
import '../auth/auth_controller.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  List<SalesOrder> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final userId = ref.read(authControllerProvider).valueOrNull?.userId;
    if (userId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final data = await ref
          .read(salesOrderServiceProvider)
          .getMyOrders(userId);
      if (!mounted) {
        return;
      }
      setState(() => _orders = data);
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'My Orders',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: _orders.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 140),
                        Center(child: Text('No orders found.')),
                      ],
                    )
                  : ListView.separated(
                      itemCount: _orders.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return Card(
                          child: ListTile(
                            title: Text('Order #${order.id}'),
                            subtitle: Text(
                              'Amount: Rs ${order.amount.toStringAsFixed(2)}\n'
                              'Status: ${order.status} | Payment: ${order.paymentStatus}',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  void _showError(Object error) {
    final message = error is DioException
        ? (error.response?.data?['message']?.toString() ?? error.message)
        : 'Something went wrong';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? 'Something went wrong')));
  }
}
