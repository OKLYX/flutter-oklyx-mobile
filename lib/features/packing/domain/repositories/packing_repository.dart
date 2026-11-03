import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/packing.dart';
import '../entities/packing_history.dart';

/// 「포장 작업」 · 「포장 이력」 data (FEATURE_2611_03 / PLAN D27) — the same
/// calls as the data source; every judgement is the server's.
abstract class PackingRepository {
  Future<Either<Failure, PackingScan>> scan(String invoiceNumber);

  Future<Either<Failure, List<PendingParcel>>> pending();

  Future<Either<Failure, BarcodeLookup>> lookupBarcode(
    String value,
    int parcelId,
  );

  Future<Either<Failure, List<BoxCandidate>>> boxCandidates(
    List<BoxCandidateItem> items,
  );

  Future<Either<Failure, PackingCompleteResult>> complete(
    int parcelId,
    int boxPackageId,
    List<PackedItem> items,
  );

  Future<Either<Failure, PackingCloseResult>> markUnused(int parcelId);

  Future<Either<Failure, PackingCloseResult>> restore(int parcelId);

  /// Changes the box of a packed parcel (FEATURE_2611_06 / D19).
  Future<Either<Failure, PackingCompleteResult>> changeBox(
    int parcelId,
    int boxPackageId,
  );

  /// [from] · [to] = `yyyy-MM-dd`, both inclusive.
  Future<Either<Failure, List<PackingHistoryEntry>>> history(
    String from,
    String to,
    String keyword,
  );
}
