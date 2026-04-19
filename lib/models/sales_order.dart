class SalesOrder {
  const SalesOrder({
    required this.id,
    required this.amount,
    required this.status,
    required this.paymentStatus,
  });

  final String id;
  final double amount;
  final String status;
  final String paymentStatus;

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    return SalesOrder(
      id: '${json['id'] ?? ''}',
      amount:
          (json['totalAmount'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble() ??
          0,
      status: '${json['status'] ?? 'unknown'}',
      paymentStatus: '${json['paymentStatus'] ?? 'pending'}',
    );
  }
}
