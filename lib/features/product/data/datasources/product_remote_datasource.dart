import 'dart:io';

import 'package:flutter_oklyn_mobile/features/product/domain/usecases/update_product_usecase.dart';

import '../models/barcode_scan_result_model.dart';
import '../models/product_image_model.dart';
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

  Future<ProductModel> updateProduct(UpdateProductParams params);

  Future<void> deleteProduct(int productId);

  // Photo gallery — `/api/admin/products/{productId}/images` (same calls as
  // the web `ProductImageRepositoryImpl`). 4xx throws `ServerException` with
  // the server message (empty when the body has none).
  Future<List<ProductImageModel>> listProductImages(int productId);

  /// One POST with every file under the part name `files`.
  Future<List<ProductImageModel>> addProductImages(
    int productId,
    List<File> files,
  );

  Future<void> replaceProductImage(int productId, int imageId, File file);

  Future<List<ProductImageModel>> reorderProductImages(
    int productId,
    List<int> imageIds,
  );

  Future<void> removeProductImage(int productId, int imageId);

  /// 구매처 목록 — `GET /api/admin/purchase-places`(모든 로그인 사용자, FEATURE_2609_76).
  Future<List<PurchasePlaceModel>> getPurchasePlaces();
}
