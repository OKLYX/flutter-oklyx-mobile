import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/packing.dart';
import '../repositories/packing_repository.dart';

/// The work list of boxes left to pack (FEATURE_2611_03 / D27).
class GetPendingParcelsUseCase {
  final PackingRepository repository;

  GetPendingParcelsUseCase({required this.repository});

  Future<Either<Failure, List<PendingParcel>>> call() => repository.pending();
}
