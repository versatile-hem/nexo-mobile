import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
import '../../services/daily_operations_service.dart';
import '../../services/master_data_service.dart';
import '../../widgets/app_shell.dart';

class DailyOperationsScreen extends ConsumerStatefulWidget {
  const DailyOperationsScreen({super.key});

  @override
  ConsumerState<DailyOperationsScreen> createState() =>
      _DailyOperationsScreenState();
}

class _DailyOperationsScreenState extends ConsumerState<DailyOperationsScreen> {
  static const _channels = ['Meesho', 'Flipkart'];

  final List<_DailyRow> _rows = [const _DailyRow(channel: 'Meesho')];
  List<Product> _products = [];
  List<String> _couriers = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final products = await ref.read(masterDataServiceProvider).getProducts();
      final couriers = await ref.read(masterDataServiceProvider).getCouriers();
      if (!mounted) {
        return;
      }
      setState(() {
        _products = products;
        _couriers = couriers;
      });
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
    final totalQty = _rows.fold<int>(0, (sum, row) => sum + row.quantity);

    return AppShell(
      title: 'Daily Operations',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSubmitting ? null : _submit,
        icon: const Icon(Icons.send_rounded),
        label: _isSubmitting
            ? const Text('Submitting...')
            : const Text('Submit'),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Card(
                  child: ListTile(
                    title: const Text('Summary Preview'),
                    subtitle: Text(
                      'Rows: ${_rows.length} | Quantity: $totalQty',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < _rows.length; i++) ...[
                  _buildRow(i),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  onPressed: () => setState(
                    () => _rows.add(const _DailyRow(channel: 'Meesho')),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Row'),
                ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _buildRow(int index) {
    final row = _rows[index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: row.channel,
              items: _channels
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _rows[index] = row.copyWith(channel: value));
                }
              },
              decoration: const InputDecoration(labelText: 'Channel'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: row.courier,
              items: _couriers
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _rows[index] = row.copyWith(courier: value)),
              decoration: const InputDecoration(labelText: 'Courier'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: row.productId,
              items: _products
                  .map(
                    (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _rows[index] = row.copyWith(productId: value)),
              decoration: const InputDecoration(labelText: 'Product'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: row.quantity == 0 ? '' : row.quantity.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
              onChanged: (value) => setState(() {
                _rows[index] = row.copyWith(quantity: int.tryParse(value) ?? 0);
              }),
            ),
            if (_rows.length > 1)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => setState(() => _rows.removeAt(index)),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final validRows = _rows
        .where(
          (row) =>
              row.productId != null && row.courier != null && row.quantity > 0,
        )
        .map(
          (row) => {
            'type': 'ORDER',
            'channel': row.channel,
            'courier': row.courier,
            'productId': row.productId,
            'quantity': row.quantity.toDouble(),
            'unit': 'UNIT',
          },
        )
        .toList();

    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill at least one complete row.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(dailyOperationsServiceProvider)
          .submitDailyOperations(validRows);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily operations submitted.')),
      );
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

class _DailyRow {
  const _DailyRow({
    required this.channel,
    this.courier,
    this.productId,
    this.quantity = 0,
  });

  final String channel;
  final String? courier;
  final int? productId;
  final int quantity;

  _DailyRow copyWith({
    String? channel,
    String? courier,
    int? productId,
    int? quantity,
  }) {
    return _DailyRow(
      channel: channel ?? this.channel,
      courier: courier ?? this.courier,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
    );
  }
}
