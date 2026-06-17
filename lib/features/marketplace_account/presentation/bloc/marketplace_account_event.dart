import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/repositories/marketplace_account_repository.dart';

abstract class MarketplaceAccountEvent extends Equatable {
  const MarketplaceAccountEvent();

  @override
  List<Object?> get props => [];
}

/// 해당 판매자의 판매채널 목록을 불러온다.
class LoadChannels extends MarketplaceAccountEvent {
  const LoadChannels();
}

class CreateChannelRequested extends MarketplaceAccountEvent {
  final CreateMarketplaceAccountParams params;

  const CreateChannelRequested(this.params);

  @override
  List<Object?> get props => [
        params.sellerId,
        params.platform,
        params.accountAlias,
        params.vendorId,
        params.accessKey,
        params.secretKey,
      ];
}

class UpdateChannelRequested extends MarketplaceAccountEvent {
  final int id;
  final UpdateMarketplaceAccountParams params;

  const UpdateChannelRequested(this.id, this.params);

  @override
  List<Object?> get props => [
        id,
        params.platform,
        params.accountAlias,
        params.vendorId,
        params.accessKey,
        params.secretKey,
      ];
}

class DeleteChannelRequested extends MarketplaceAccountEvent {
  final int id;

  const DeleteChannelRequested(this.id);

  @override
  List<Object?> get props => [id];
}
