import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/packing.dart';
import '../repositories/packing_repository.dart';

/// Opens a box by its invoice number (FEATURE_2611_03 / D27).
class ScanParcelUseCase {
  final PackingRepository repository;

  ScanParcelUseCase({required this.repository});

  Future<Either<Failure, PackingScan>> call(String invoiceNumber) =>
      repository.scan(invoiceNumber);
}
