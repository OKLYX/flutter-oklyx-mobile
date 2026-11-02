import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/packing.dart';
import '../repositories/packing_repository.dart';

/// Restores an unused box to pending (FEATURE_2611_03 / D26).
class RestoreParcelUseCase {
  final PackingRepository repository;

  RestoreParcelUseCase({required this.repository});

  Future<Either<Failure, PackingCloseResult>> call(int parcelId) =>
      repository.restore(parcelId);
}
