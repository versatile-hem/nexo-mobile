import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_provider.dart';
import '../models/sales_order.dart';

final salesOrderServiceProvider = Provider<SalesOrderService>((ref) {
  return SalesOrderService(ref.watch(dioProvider));
});

class SalesOrderService {
  SalesOrderService(this._dio);

  final Dio _dio;

  Future<void> createOrder({
    required int customerId,
    required List<Map<String, dynamic>> items,
  }) async {
    await _dio.post(
      '/api/sales-orders',
      data: {'customerId': customerId, 'items': items},
    );
  }

  Future<List<SalesOrder>> getMyOrders(String userId) async {
    final response = await _dio.get(
      '/api/sales-orders',
      queryParameters: {'createdBy': userId},
    );
    final list = _asList(response.data);
    return list
        .map((e) => SalesOrder.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }
}
