import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/packing.dart';
import '../repositories/packing_repository.dart';

/// Asks the server about a barcode the screen could not match (D27).
class LookupPackingBarcodeUseCase {
  final PackingRepository repository;

  LookupPackingBarcodeUseCase({required this.repository});

  Future<Either<Failure, BarcodeLookup>> call(String value, int parcelId) =>
      repository.lookupBarcode(value, parcelId);
}
