import 'dart:io';

import 'package:flutter_oklyn_mobile/features/product/domain/usecases/update_product_usecase.dart';

import '../models/barcode_scan_result_model.dart';
import '../models/product_model.dart';
import '../models/product_page_model.dart';
import '../models/purchase_place_model.dart';

abstract class ProductRemoteDataSource {
  Future<ProductPageModel> getProducts({
    required int page,
    required int size,
    String? search,
  });

  Future<ProductModel> getProduct(int id);

  Future<ProductModel> registerProduct(dynamic params);

  Future<bool> checkBarcodeAvailable(String barcodeId);

  /// `POST /api/admin/products/barcode-scan` (multipart part `file`).
  /// Returns only the read value; `barcode == null` means nothing readable.
  Future<BarcodeScanResultModel> scanBarcodeFromImage(File image);

  Future<void> uploadProductImage(int productId, File imageFile);

  Future<ProductModel> updateProduct(UpdateProductParams params);

  Future<void> deleteProduct(int productId);

  Future<void> deleteProductImage(int productId);

  /// 구매처 목록 — `GET /api/admin/purchase-places`(모든 로그인 사용자, FEATURE_2609_76).
  Future<List<PurchasePlaceModel>> getPurchasePlaces();
}
