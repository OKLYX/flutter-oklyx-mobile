import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/entities/marketplace_account.dart';

class MarketplaceAccountModel extends MarketplaceAccount {
  const MarketplaceAccountModel({
    required int id,
    required int sellerId,
    required String platform,
    required String? accountAlias,
    required String vendorId,
    required String accessKey,
    required bool isActive,
    required String createdAt,
    required String updatedAt,
  }) : super(
          id: id,
          sellerId: sellerId,
          platform: platform,
          accountAlias: accountAlias,
          vendorId: vendorId,
          accessKey: accessKey,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory MarketplaceAccountModel.fromJson(Map<String, dynamic> json) => MarketplaceAccountModel(
        id: json['id'] as int,
        sellerId: json['sellerId'] as int,
        platform: json['platform'] as String,
        accountAlias: json['accountAlias'] as String?,
        vendorId: json['vendorId'] as String,
        accessKey: json['accessKey'] as String,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: json['createdAt'] as String? ?? 'N/A',
        updatedAt: json['updatedAt'] as String? ?? 'N/A',
      );
}
