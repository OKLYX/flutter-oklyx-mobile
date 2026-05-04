import 'dart:io';

import '../models/product_model.dart';
import '../models/product_page_model.dart';

abstract class ProductRemoteDataSource {
  Future<ProductPageModel> getProducts({
    required int page,
    required int size,
    String? search,
  });

  Future<ProductModel> getProduct(int id);

  Future<ProductModel> registerProduct(dynamic params);

  Future<bool> checkBarcodeAvailable(String barcodeId);

  Future<void> uploadProductImage(int productId, File imageFile);
}
