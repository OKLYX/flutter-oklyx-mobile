import '../models/product_page_model.dart';

abstract class ProductRemoteDataSource {
  Future<ProductPageModel> getProducts({
    required int page,
    required int size,
    String? search,
  });
}
