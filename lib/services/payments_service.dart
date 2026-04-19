import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/network/dio_provider.dart';

final paymentsServiceProvider = Provider<PaymentsService>((ref) {
  return PaymentsService(ref.watch(dioProvider));
});

class PaymentsService {
  PaymentsService(this._dio);

  final Dio _dio;

  Future<void> addPayment({
    required int orderId,
    required double amount,
    required String mode,
  }) async {
    final normalizedMode = mode.toUpperCase();
    await _dio.post(
      '/api/payments',
      data: {
        'orderId': orderId,
        'amount': amount,
        'mode': normalizedMode,
        'paymentDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      },
    );
  }
}
