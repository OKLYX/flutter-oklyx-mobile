import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/entities/marketplace_account.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';

/// Arguments for the **pages** that port master detail input windows (web `ui/Modal`) (FEATURE_2609_80 / 08 · PLAN R-d).
///
/// **File**: lib/features/master_product/presentation/master_tool_args.dart
/// Open a page with `context.pushNamed<Result>(name, extra: args)` and close it with `context.pop(result)`.
/// Result `null` = closed without saving (web `onClose`).

/// `Routes.masterChannelFieldValues` — result: the saved `GeneratedProduct`.
class ChannelFieldValuesArgs {
  final int listingId;

  const ChannelFieldValuesArgs({required this.listingId});
}

/// `Routes.masterChannelStock` · `masterChannelPrice` · `masterChannelOptionName` — result: `true` (saved).
class ChannelOptionsArgs {
  final int listingId;
  final String channelLabel;

  const ChannelOptionsArgs({required this.listingId, required this.channelLabel});
}

/// `Routes.masterChannelShipping` — result: the saved `GeneratedProduct`.
class ChannelShippingArgs {
  final int listingId;
  final int accountId;
  final String platform;
  final String channelLabel;
  final Map<String, String>? initialOverride;

  const ChannelShippingArgs({
    required this.listingId,
    required this.accountId,
    required this.platform,
    required this.channelLabel,
    this.initialOverride,
  });
}

/// `Routes.masterMarketProductAdd` (「마켓 상품 추가하기」, UX D42 · D76 · D78).
class MarketProductAddArgs {
  final int masterId;
  final int sellerId;
  final String platform;
  final String sellerName;
  final List<MasterOption> masterOptions;
  final String? initialProductId;

  const MarketProductAddArgs({
    required this.masterId,
    required this.sellerId,
    required this.platform,
    required this.sellerName,
    required this.masterOptions,
    this.initialProductId,
  });
}

/// Result of `Routes.masterMarketProductAdd` — attach succeeded (web `onDone(categoryWarning)`).
class MarketProductAddResult {
  final String? categoryWarning;

  const MarketProductAddResult({this.categoryWarning});
}

/// `Routes.masterShippingConfig` (shipping config window — UX D83). No result (the caller re-reads on close).
class ShippingConfigArgs {
  final MarketplaceAccount account;

  const ShippingConfigArgs({required this.account});
}
