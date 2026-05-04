import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/repositories/product_repository.dart';

class UploadProductImageParams extends Equatable {
  final int productId;
  final File imageFile;

  const UploadProductImageParams({
    required this.productId,
    required this.imageFile,
  });

  @override
  List<Object?> get props => [productId, imageFile];
}

class UploadProductImageUseCase {
  final ProductRepository repository;

  UploadProductImageUseCase(this.repository);

  Future<Either<Failure, void>> call(UploadProductImageParams params) =>
      repository.uploadProductImage(params.productId, params.imageFile);
}
