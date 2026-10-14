import 'package:equatable/equatable.dart';

/// 판매채널(플랫폼 계정) 도메인 엔티티.
///
/// 하나의 판매자(Seller)는 여러 개의 판매채널을 가질 수 있다.
/// secretKey 는 응답에 절대 포함되지 않으므로 엔티티에도 없다 (write-only).
class MarketplaceAccount extends Equatable {
  final int id;
  final int sellerId;
  final String platform;
  final String? accountAlias;

  /// Coupang only — null on an 11st account (FEATURE_2610_13 / D5).
  final String? vendorId;

  /// Coupang only — null on an 11st account (FEATURE_2610_13 / D5).
  final String? accessKey;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  /// FEATURE_2610_13 / D88: the server says the 11st key went unused for over 150 days (null = not 11st).
  final bool? elevenstKeyRenewalNeeded;

  const MarketplaceAccount({
    required this.id,
    required this.sellerId,
    required this.platform,
    required this.accountAlias,
    required this.vendorId,
    required this.accessKey,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.elevenstKeyRenewalNeeded,
  });

  @override
  List<Object?> get props => [
        id,
        sellerId,
        platform,
        accountAlias,
        vendorId,
        accessKey,
        isActive,
        createdAt,
        updatedAt,
        elevenstKeyRenewalNeeded,
      ];
}
