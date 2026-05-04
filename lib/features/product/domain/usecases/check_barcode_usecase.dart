import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/repositories/product_repository.dart';

class CheckBarcodeParams extends Equatable {
  final String barcodeId;

  const CheckBarcodeParams(this.barcodeId);

  @override
  List<Object?> get props => [barcodeId];
}

class CheckBarcodeUseCase {
  final ProductRepository repository;

  CheckBarcodeUseCase(this.repository);

  Future<Either<Failure, bool>> call(CheckBarcodeParams params) =>
      repository.checkBarcodeAvailable(params.barcodeId);
}
