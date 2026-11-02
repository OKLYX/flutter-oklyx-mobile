import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/packing_history.dart';
import '../repositories/packing_repository.dart';

/// Packing history rows of a period (FEATURE_2611_03 / D29 · D34).
class GetPackingHistoryUseCase {
  final PackingRepository repository;

  GetPackingHistoryUseCase({required this.repository});

  Future<Either<Failure, List<PackingHistoryEntry>>> call(
          String from, String to, String keyword) =>
      repository.history(from, to, keyword);
}
