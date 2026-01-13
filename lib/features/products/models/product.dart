class Product {
  final int id;
  final String name;

  Product({
    required this.id,
    required this.name,
  });

  factory Product.fromApi(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
    );
  }
}
