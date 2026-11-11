import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/stock_fill.dart';
import '../repositories/stock_daily_repository.dart';

/// The 「채울까요?」 sheets after an intake save (FEATURE_2611_22 D3 ① · D31) —
/// one per product of the saved lots with an order outbound row to fill.
class GetFillCandidatesUseCase {
  final StockDailyRepository repository;

  GetFillCandidatesUseCase({required this.repository});

  Future<Either<Failure, List<FillCandidate>>> call(List<int> lotIds) =>
      repository.fillCandidates(lotIds);
}
