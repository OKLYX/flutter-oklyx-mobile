import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/barcode_scan_result.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/repositories/product_repository.dart';

class ScanBarcodeFromImageParams extends Equatable {
  final File image;

  const ScanBarcodeFromImageParams(this.image);

  @override
  List<Object?> get props => [image.path];
}

/// Uploads an image and returns the barcode the server read from it.
class ScanBarcodeFromImageUseCase {
  final ProductRepository repository;

  ScanBarcodeFromImageUseCase(this.repository);

  Future<Either<Failure, BarcodeScanResult>> call(
    ScanBarcodeFromImageParams params,
  ) =>
      repository.scanBarcodeFromImage(params.image);
}
