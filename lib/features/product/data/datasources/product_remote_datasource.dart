import 'dart:io';

import 'package:flutter_oklyn_mobile/features/product/domain/usecases/update_product_usecase.dart';

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

  Future<ProductModel> updateProduct(UpdateProductParams params);

  Future<void> deleteProduct(int productId);

  Future<void> deleteProductImage(int productId);
}
