import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/marketplace_account.dart';

/// Channel create parameters. FEATURE_2610_13 / D5: vendorId · accessKey · secretKey are the Coupang fields,
/// apiKey is the 11st key — the fields of the other platform stay null.
class CreateMarketplaceAccountParams {
  final int sellerId;
  final String platform;
  final String? accountAlias;
  final String? vendorId;
  final String? accessKey;
  final String? secretKey;
  final String? apiKey;

  const CreateMarketplaceAccountParams({
    required this.sellerId,
    required this.platform,
    this.accountAlias,
    this.vendorId,
    this.accessKey,
    this.secretKey,
    this.apiKey,
  });
}

/// Channel update parameters.
///
/// secretKey and apiKey are optional — left blank, the backend keeps the stored key. FEATURE_2610_13 / D5: an 11st
/// channel sends no Coupang field.
class UpdateMarketplaceAccountParams {
  final int sellerId;
  final String platform;
  final String? accountAlias;
  final String? vendorId;
  final String? accessKey;
  final String? secretKey;
  final String? apiKey;

  const UpdateMarketplaceAccountParams({
    required this.sellerId,
    required this.platform,
    this.accountAlias,
    this.vendorId,
    this.accessKey,
    this.secretKey,
    this.apiKey,
  });
}

abstract class MarketplaceAccountRepository {
  Future<Either<Failure, List<MarketplaceAccount>>> getBySeller(int sellerId);

  Future<Either<Failure, MarketplaceAccount>> create(CreateMarketplaceAccountParams params);

  Future<Either<Failure, MarketplaceAccount>> update(int id, UpdateMarketplaceAccountParams params);

  Future<Either<Failure, void>> delete(int id);
}
