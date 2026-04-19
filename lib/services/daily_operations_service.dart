import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_provider.dart';

final dailyOperationsServiceProvider = Provider<DailyOperationsService>((ref) {
  return DailyOperationsService(ref.watch(dioProvider));
});

class DailyOperationsService {
  DailyOperationsService(this._dio);

  final Dio _dio;

  Future<void> submitDailyOperations(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _dio.post('/api/daily-operations', data: row);
    }
  }
}
