import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/packing.dart';
import '../repositories/packing_repository.dart';

/// [이 박스 완료] — the server checks the quantities (D27).
class CompleteParcelUseCase {
  final PackingRepository repository;

  CompleteParcelUseCase({required this.repository});

  Future<Either<Failure, PackingCompleteResult>> call(
          int parcelId, int boxPackageId, List<PackedItem> items) =>
      repository.complete(parcelId, boxPackageId, items);
}
