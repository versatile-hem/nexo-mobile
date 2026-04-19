import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sales_order.dart';
import '../../services/payments_service.dart';
import '../../services/sales_order_service.dart';
import '../../widgets/app_shell.dart';
import '../auth/auth_controller.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  static const _modes = ['CASH', 'UPI', 'BANK'];

  final _amountCtrl = TextEditingController();
  List<SalesOrder> _orders = [];
  int? _orderId;
  String _mode = 'CASH';
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
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
      final orders = await ref
          .read(salesOrderServiceProvider)
          .getMyOrders(userId);
      if (!mounted) {
        return;
      }
      setState(() => _orders = orders);
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
      title: 'Payments',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _orderId,
                  items: _orders
                      .map(
                        (o) => DropdownMenuItem(
                          value: int.tryParse(o.id) ?? 0,
                          child: Text(
                            'Order ${o.id} | Rs ${o.amount.toStringAsFixed(2)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _orderId = value),
                  decoration: const InputDecoration(labelText: 'Select Order'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Payment Amount',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _mode,
                  items: _modes
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _mode = value);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Payment Mode'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add Payment'),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (_orderId == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose order and enter valid amount.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(paymentsServiceProvider)
          .addPayment(orderId: _orderId!, amount: amount, mode: _mode);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment submitted successfully.')),
      );
      _amountCtrl.clear();
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
