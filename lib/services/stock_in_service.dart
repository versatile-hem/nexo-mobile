import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_provider.dart';

final stockInServiceProvider = Provider<StockInService>((ref) {
  return StockInService(ref.watch(dioProvider));
});

class StockInService {
  StockInService(this._dio);

  final Dio _dio;

  Future<void> submitStockIn(List<Map<String, dynamic>> items) async {
    await _dio.post('/api/stock-in', data: items);
  }
}
