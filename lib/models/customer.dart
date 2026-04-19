class Customer {
  const Customer({required this.id, required this.name});

  final int id;
  final String name;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id:
          (json['id'] as int?) ??
          int.tryParse(json['id']?.toString() ?? '0') ??
          0,
      name: '${json['name'] ?? ''}',
    );
  }
}
