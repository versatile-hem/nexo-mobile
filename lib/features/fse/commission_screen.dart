import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/commission.dart';
import '../../services/commission_service.dart';
import '../../widgets/app_shell.dart';

class CommissionScreen extends ConsumerStatefulWidget {
  const CommissionScreen({super.key});

  @override
  ConsumerState<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends ConsumerState<CommissionScreen> {
  late DateTime _selectedMonth;
  CommissionSummary _summary = const CommissionSummary(total: 0, items: []);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _loadCommission();
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);
    return AppShell(
      title: 'My Commission',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Card(
                  child: ListTile(
                    title: const Text('Month'),
                    subtitle: Text(monthLabel),
                    trailing: IconButton(
                      onPressed: _pickMonth,
                      icon: const Icon(Icons.calendar_month),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    title: const Text('Total Commission'),
                    subtitle: Text('Rs ${_summary.total.toStringAsFixed(2)}'),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Order-wise Breakdown',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_summary.items.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No commission records available.'),
                    ),
                  )
                else
                  ..._summary.items.map(
                    (item) => Card(
                      child: ListTile(
                        title: Text('Order #${item.orderId}'),
                        subtitle: Text(
                          'Order Amount: Rs ${item.amount.toStringAsFixed(2)}\n'
                          'Commission: Rs ${item.commission.toStringAsFixed(2)}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      initialDate: _selectedMonth,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month, 1);
    });
    await _loadCommission();
  }

  Future<void> _loadCommission() async {
    setState(() => _isLoading = true);
    try {
      final formatted = DateFormat('yyyy-MM').format(_selectedMonth);
      final data = await ref
          .read(commissionServiceProvider)
          .getCommission(month: formatted);
      if (!mounted) {
        return;
      }
      setState(() => _summary = data);
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

  void _showError(Object error) {
    final message = error is DioException
        ? (error.response?.data?['message']?.toString() ?? error.message)
        : 'Something went wrong';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? 'Something went wrong')));
  }
}
