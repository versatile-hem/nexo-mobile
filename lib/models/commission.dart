class CommissionSummary {
  const CommissionSummary({required this.total, required this.items});

  final double total;
  final List<CommissionItem> items;

  factory CommissionSummary.fromJson(Map<String, dynamic> json) {
    final itemsRaw =
        (json['orders'] as List<dynamic>? ??
        json['items'] as List<dynamic>? ??
        []);
    return CommissionSummary(
      total:
          (json['totalCommission'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble() ??
          0,
      items: itemsRaw
          .map((e) => CommissionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class CommissionItem {
  const CommissionItem({
    required this.orderId,
    required this.amount,
    required this.commission,
  });

  final String orderId;
  final double amount;
  final double commission;

  factory CommissionItem.fromJson(Map<String, dynamic> json) {
    return CommissionItem(
      orderId: '${json['orderId'] ?? ''}',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0,
    );
  }
}
