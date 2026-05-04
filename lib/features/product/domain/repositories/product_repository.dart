import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/product.dart';
import '../entities/product_page.dart';

abstract class ProductRepository {
  Future<Either<Failure, ProductPage>> getProducts({
    required int page,
    int size = 20,
    String? search,
  });

  Future<Either<Failure, Product>> getProduct(int id);

  Future<Either<Failure, Product>> registerProduct(dynamic params);

  Future<Either<Failure, bool>> checkBarcodeAvailable(String barcodeId);

  Future<Either<Failure, void>> uploadProductImage(int productId, File imageFile);
}
