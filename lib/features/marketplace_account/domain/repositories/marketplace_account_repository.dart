import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/marketplace_account.dart';

/// Channel create parameters. FEATURE_2610_13 / D5: vendorId · accessKey · secretKey are the Coupang fields,
/// apiKey is the 11st key, and FEATURE_2610_26 / D4 · D5: esmMasterId ·
/// esmSecretKey · gmarketSellerId · auctionSellerId are the ESM fields — the
/// fields of the other platforms stay null.
class CreateMarketplaceAccountParams {
  final int sellerId;
  final String platform;
  final String? accountAlias;
  final String? vendorId;
  final String? accessKey;
  final String? secretKey;
  final String? apiKey;
  final String? esmMasterId;
  final String? esmSecretKey;
  final String? gmarketSellerId;
  final String? auctionSellerId;

  const CreateMarketplaceAccountParams({
    required this.sellerId,
    required this.platform,
    this.accountAlias,
    this.vendorId,
    this.accessKey,
    this.secretKey,
    this.apiKey,
    this.esmMasterId,
    this.esmSecretKey,
    this.gmarketSellerId,
    this.auctionSellerId,
  });
}

/// Channel update parameters.
///
/// secretKey, apiKey and esmSecretKey are optional — left blank, the backend
/// keeps the stored key. FEATURE_2610_13 / D5: an 11st channel sends no Coupang
/// field; FEATURE_2610_26 / D4: an ESM channel sends only the ESM fields.
class UpdateMarketplaceAccountParams {
  final int sellerId;
  final String platform;
  final String? accountAlias;
  final String? vendorId;
  final String? accessKey;
  final String? secretKey;
  final String? apiKey;
  final String? esmMasterId;
  final String? esmSecretKey;
  final String? gmarketSellerId;
  final String? auctionSellerId;

  const UpdateMarketplaceAccountParams({
    required this.sellerId,
    required this.platform,
    this.accountAlias,
    this.vendorId,
    this.accessKey,
    this.secretKey,
    this.apiKey,
    this.esmMasterId,
    this.esmSecretKey,
    this.gmarketSellerId,
    this.auctionSellerId,
  });
}

abstract class MarketplaceAccountRepository {
  Future<Either<Failure, List<MarketplaceAccount>>> getBySeller(int sellerId);

  Future<Either<Failure, MarketplaceAccount>> create(CreateMarketplaceAccountParams params);

  Future<Either<Failure, MarketplaceAccount>> update(int id, UpdateMarketplaceAccountParams params);

  Future<Either<Failure, void>> delete(int id);
}
