import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/barcode_scan_result.dart';
import '../entities/product.dart';
import '../entities/product_image.dart';
import '../entities/product_page.dart';
import '../entities/purchase_place.dart';
import '../usecases/update_product_usecase.dart';

abstract class ProductRepository {
  Future<Either<Failure, ProductPage>> getProducts({
    required int page,
    int size = 20,
    String? search,
  });

  Future<Either<Failure, Product>> getProduct(int id);

  Future<Either<Failure, Product>> registerProduct(dynamic params);

  Future<Either<Failure, bool>> checkBarcodeAvailable(String barcodeId);

  /// Reads a barcode from [image]; the server never stores the image.
  Future<Either<Failure, BarcodeScanResult>> scanBarcodeFromImage(File image);

  Future<Either<Failure, Product>> updateProduct(UpdateProductParams params);

  Future<Either<Failure, void>> deleteProduct(int productId);

  // Photo gallery — `/api/admin/products/{productId}/images`.
  Future<Either<Failure, List<ProductImage>>> listProductImages(int productId);

  Future<Either<Failure, List<ProductImage>>> addProductImages(
    int productId,
    List<File> files,
  );

  Future<Either<Failure, void>> replaceProductImage(
    int productId,
    int imageId,
    File file,
  );

  Future<Either<Failure, List<ProductImage>>> reorderProductImages(
    int productId,
    List<int> imageIds,
  );

  Future<Either<Failure, void>> removeProductImage(int productId, int imageId);

  Future<Either<Failure, List<PurchasePlace>>> getPurchasePlaces();
}
