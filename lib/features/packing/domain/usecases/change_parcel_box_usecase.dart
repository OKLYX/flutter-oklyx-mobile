import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/packing.dart';
import '../repositories/packing_repository.dart';

/// Changes the box of a packed parcel (FEATURE_2611_06 / D19).
class ChangeParcelBoxUseCase {
  final PackingRepository repository;

  ChangeParcelBoxUseCase({required this.repository});

  Future<Either<Failure, PackingCompleteResult>> call(
    int parcelId,
    int boxPackageId,
  ) =>
      repository.changeBox(parcelId, boxPackageId);
}
