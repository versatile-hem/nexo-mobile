class Product {
  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
  });

  final int id;
  final String name;
  final String? barcode;
  final double price;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id:
          (json['productId'] as int?) ??
          (json['id'] as int?) ??
          int.tryParse(
            json['productId']?.toString() ?? json['id']?.toString() ?? '0',
          ) ??
          0,
      name: '${json['name'] ?? ''}',
      barcode: json['barcode']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}
