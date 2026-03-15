class Product {
  final int id;
  final String name;
  final String? ownerId;
  final bool isMergedProduct;
  final List<int> sourceProductIds;

  Product({
    required this.id,
    required this.name,
    this.ownerId,
    this.isMergedProduct = false,
    this.sourceProductIds = const [],
  });

  factory Product.fromApi(Map<String, dynamic> json) {
    final source = json['sourceProductIds'];
    return Product(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      ownerId: json['ownerId']?.toString(),
      isMergedProduct: json['isMergedProduct'] == true,
      sourceProductIds: source is List
          ? source
                .map((item) => int.tryParse(item.toString()) ?? 0)
                .where((item) => item > 0)
                .toList()
          : const [],
    );
  }
}
