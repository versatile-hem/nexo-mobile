import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/customer.dart';
import '../../models/product.dart';
import '../../services/master_data_service.dart';
import '../../services/sales_order_service.dart';
import '../../widgets/app_shell.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  int? _customerId;
  List<Customer> _customers = [];
  List<Product> _products = [];
  final List<_OrderRow> _rows = [const _OrderRow()];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final customers = await ref
          .read(masterDataServiceProvider)
          .getCustomers();
      final products = await ref.read(masterDataServiceProvider).getProducts();
      if (!mounted) {
        return;
      }
      setState(() {
        _customers = customers;
        _products = products;
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
    final total = _calculateTotal();

    return AppShell(
      title: 'Take Order',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSubmitting ? null : _submit,
        icon: const Icon(Icons.send_rounded),
        label: _isSubmitting
            ? const Text('Submitting...')
            : const Text('Create'),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _customerId,
                  items: _customers
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _customerId = value),
                  decoration: const InputDecoration(labelText: 'Customer'),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _rows.length; i++) ...[
                  _buildItemRow(i),
                  const SizedBox(height: 10),
                ],
                OutlinedButton.icon(
                  onPressed: () => setState(() => _rows.add(const _OrderRow())),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: const Text('Order Total'),
                    subtitle: Text('Rs ${total.toStringAsFixed(2)}'),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _buildItemRow(int index) {
    final row = _rows[index];
    final selected = _products
        .where((p) => p.id == row.productId)
        .cast<Product?>()
        .firstOrNull;
    final lineTotal = (selected?.price ?? 0) * row.quantity;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              initialValue: row.productId,
              items: _products
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.name} - Rs ${p.price}'),
                    ),
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
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Line Total: Rs ${lineTotal.toStringAsFixed(2)}'),
                const Spacer(),
                if (_rows.length > 1)
                  IconButton(
                    onPressed: () => setState(() => _rows.removeAt(index)),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotal() {
    double total = 0;
    for (final row in _rows) {
      final product = _products
          .where((p) => p.id == row.productId)
          .cast<Product?>()
          .firstOrNull;
      total += (product?.price ?? 0) * row.quantity;
    }
    return total;
  }

  Future<void> _submit() async {
    final payloadItems = _rows
        .where((r) => r.productId != null && r.quantity > 0)
        .map((r) {
          final product = _products
              .where((p) => p.id == r.productId)
              .cast<Product?>()
              .firstOrNull;
          return {
            'productId': r.productId,
            'quantity': r.quantity.toDouble(),
            'price': product?.price ?? 0.0,
          };
        })
        .toList();

    if (_customerId == null || payloadItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select customer and at least one product.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(salesOrderServiceProvider)
          .createOrder(customerId: _customerId!, items: payloadItems);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sales order created successfully.')),
      );
      setState(() {
        _rows
          ..clear()
          ..add(const _OrderRow());
      });
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

class _OrderRow {
  const _OrderRow({this.productId, this.quantity = 0});

  final int? productId;
  final int quantity;

  _OrderRow copyWith({int? productId, int? quantity}) {
    return _OrderRow(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
    );
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
