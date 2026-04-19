import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_provider.dart';
import '../models/commission.dart';

final commissionServiceProvider = Provider<CommissionService>((ref) {
  return CommissionService(ref.watch(dioProvider));
});

class CommissionService {
  CommissionService(this._dio);

  final Dio _dio;

  Future<CommissionSummary> getCommission({required String month}) async {
    final response = await _dio.get(
      '/api/commission',
      queryParameters: {'month': month},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return CommissionSummary.fromJson(data);
    }
    return const CommissionSummary(total: 0, items: []);
  }
}
