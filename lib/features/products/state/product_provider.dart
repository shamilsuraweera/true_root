import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/products_api.dart';
import '../models/product.dart';
import '../../../state/auth_state.dart';

final productsApiProvider = Provider<ProductsApi>((ref) {
  final token = ref.watch(authProvider).accessToken;
  return ProductsApi(authToken: token);
});

final productListProvider = FutureProvider<List<Product>>((ref) async {
  final api = ref.watch(productsApiProvider);
  return api.fetchProducts();
});
