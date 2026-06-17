import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/marketplace_account.dart';

/// 판매채널 생성 요청 파라미터.
class CreateMarketplaceAccountParams {
  final int sellerId;
  final String platform;
  final String? accountAlias;
  final String vendorId;
  final String accessKey;
  final String secretKey;

  const CreateMarketplaceAccountParams({
    required this.sellerId,
    required this.platform,
    this.accountAlias,
    required this.vendorId,
    required this.accessKey,
    required this.secretKey,
  });
}

/// 판매채널 수정 요청 파라미터.
///
/// secretKey 는 선택값 — 비워두면 백엔드가 기존 값을 유지한다.
class UpdateMarketplaceAccountParams {
  final int sellerId;
  final String platform;
  final String? accountAlias;
  final String vendorId;
  final String accessKey;
  final String? secretKey;

  const UpdateMarketplaceAccountParams({
    required this.sellerId,
    required this.platform,
    this.accountAlias,
    required this.vendorId,
    required this.accessKey,
    this.secretKey,
  });
}

abstract class MarketplaceAccountRepository {
  Future<Either<Failure, List<MarketplaceAccount>>> getBySeller(int sellerId);

  Future<Either<Failure, MarketplaceAccount>> create(CreateMarketplaceAccountParams params);

  Future<Either<Failure, MarketplaceAccount>> update(int id, UpdateMarketplaceAccountParams params);

  Future<Either<Failure, void>> delete(int id);
}
