import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_provider.dart';
import '../models/customer.dart';
import '../models/product.dart';

final masterDataServiceProvider = Provider<MasterDataService>((ref) {
  return MasterDataService(ref.watch(dioProvider));
});

class MasterDataService {
  MasterDataService(this._dio);

  final Dio _dio;

  Future<List<Product>> getProducts() async {
    final response = await _dio.get('/api/products');
    final list = _asList(response.data);
    return list
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Customer>> getCustomers() async {
    final response = await _dio.get('/api/customers');
    final list = _asList(response.data);
    return list
        .map((e) => Customer.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<String>> getCouriers() async {
    return const ['Delhivery', 'BlueDart', 'XpressBees', 'Ekart'];
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
