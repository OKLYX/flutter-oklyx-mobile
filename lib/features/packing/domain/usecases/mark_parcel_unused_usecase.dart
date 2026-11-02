import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/packing.dart';
import '../repositories/packing_repository.dart';

/// Closes a box as unused (FEATURE_2611_03).
class MarkParcelUnusedUseCase {
  final PackingRepository repository;

  MarkParcelUnusedUseCase({required this.repository});

  Future<Either<Failure, PackingCloseResult>> call(int parcelId) =>
      repository.markUnused(parcelId);
}
