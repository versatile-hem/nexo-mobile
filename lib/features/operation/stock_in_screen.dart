import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/product.dart';
import '../../services/master_data_service.dart';
import '../../services/stock_in_service.dart';
import '../../widgets/app_shell.dart';

class StockInScreen extends ConsumerStatefulWidget {
  const StockInScreen({super.key});

  @override
  ConsumerState<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockInScreen> {
  final List<_StockInRow> _rows = [const _StockInRow()];
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final data = await ref.read(masterDataServiceProvider).getProducts();
      if (!mounted) {
        return;
      }
      setState(() {
        _products = data;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Stock In',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSubmitting ? null : _submit,
        label: _isSubmitting
            ? const Text('Submitting...')
            : const Text('Submit'),
        icon: const Icon(Icons.send_rounded),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                for (var i = 0; i < _rows.length; i++) ...[
                  _buildRow(i),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _rows.add(const _StockInRow())),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
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
            DropdownButtonFormField<int>(
              initialValue: row.productId,
              items: _products
                  .map(
                    (p) =>
                        DropdownMenuItem<int>(value: p.id, child: Text(p.name)),
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
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _scanAndSelect(index),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scan Barcode'),
                  ),
                ),
                if (_rows.length > 1) ...[
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => setState(() => _rows.removeAt(index)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanAndSelect(int index) async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _BarcodeScannerSheet(),
    );

    if (code == null || !mounted) {
      return;
    }

    final match = _products.where((p) => p.barcode == code).toList();
    if (match.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No product mapped with this barcode.')),
      );
      return;
    }

    setState(() {
      _rows[index] = _rows[index].copyWith(productId: match.first.id);
    });
  }

  Future<void> _submit() async {
    final validRows = _rows
        .where((r) => r.productId != null && r.quantity > 0)
        .map(
          (r) => {
            'productId': r.productId,
            'quantity': r.quantity.toDouble(),
            'unit': 'UNIT',
          },
        )
        .toList();

    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one valid stock item.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(stockInServiceProvider).submitStockIn(validRows);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock in submitted successfully.')),
      );
      setState(() {
        _rows
          ..clear()
          ..add(const _StockInRow());
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error);
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

class _StockInRow {
  const _StockInRow({this.productId, this.quantity = 0});

  final int? productId;
  final int quantity;

  _StockInRow copyWith({int? productId, int? quantity}) {
    return _StockInRow(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
    );
  }
}

class _BarcodeScannerSheet extends StatefulWidget {
  const _BarcodeScannerSheet();

  @override
  State<_BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<_BarcodeScannerSheet> {
  bool _captured = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: MobileScanner(
        onDetect: (capture) {
          if (_captured) {
            return;
          }
          final value = capture.barcodes.first.rawValue;
          if (value != null && value.isNotEmpty) {
            _captured = true;
            Navigator.of(context).pop(value);
          }
        },
      ),
    );
  }
}
