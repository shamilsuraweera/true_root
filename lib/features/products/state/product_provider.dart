import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/products_api.dart';
import '../models/product.dart';

final productsApiProvider = Provider<ProductsApi>((ref) {
  return ProductsApi();
});

final productListProvider = FutureProvider<List<Product>>((ref) async {
  final api = ref.read(productsApiProvider);
  return api.fetchProducts();
});
