import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/packing.dart';
import '../repositories/packing_repository.dart';

/// Recommended boxes for a composition (FEATURE_2611_03 / D27).
class GetBoxCandidatesUseCase {
  final PackingRepository repository;

  GetBoxCandidatesUseCase({required this.repository});

  Future<Either<Failure, List<BoxCandidate>>> call(
          List<BoxCandidateItem> items) =>
      repository.boxCandidates(items);
}
