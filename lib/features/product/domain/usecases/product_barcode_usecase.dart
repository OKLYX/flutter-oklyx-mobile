import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/repositories/product_repository.dart';

/// Barcode calls of the 「입고 작업」 screen (FEATURE_2611_33 D5 · D6) —
/// thin delegate to [ProductRepository].
///
/// Sends only name · barcode · price; purchase places and count stay as
/// they are on the server (D6).
class ProductBarcodeUseCase {
  final ProductRepository repository;

  ProductBarcodeUseCase(this.repository);

  /// Puts [barcodeId] on an existing product.
  Future<Either<Failure, Product>> saveBarcode({
    required int productId,
    required String barcodeId,
    String? productName,
    int? price,
  }) =>
      repository.saveProductBarcode(
        productId: productId,
        barcodeId: barcodeId,
        productName: productName,
        price: price,
      );

  /// Registers a new product holding [barcodeId].
  Future<Either<Failure, Product>> create({
    required String productName,
    required String barcodeId,
    int? price,
  }) =>
      repository.createProductWithBarcode(
        productName: productName,
        barcodeId: barcodeId,
        price: price,
      );
}
