import 'package:flutter_oklyn_mobile/features/sales/presentation/bloc/product_profit_state.dart';

/// Events of the 「상품별 매출」 BLoC (FEATURE_2610_20 / D26).
sealed class ProductProfitEvent {
  const ProductProfitEvent();
}

/// Screen entry — sellers, product rows and option savings of this month.
class ProductProfitStarted extends ProductProfitEvent {
  /// The shared 「출고 전 주문 제외」 value on entry (FEATURE_2611_04 / D9).
  final bool excludeUnshipped;
  const ProductProfitStarted({this.excludeUnshipped = false});
}

/// Sale-date range `yyyy-MM-dd`. Folds the open savings row.
class ProductProfitPeriodChanged extends ProductProfitEvent {
  final String from;
  final String to;
  const ProductProfitPeriodChanged({required this.from, required this.to});
}

/// Seller chip (null = 「전체」).
class ProductProfitSellerChanged extends ProductProfitEvent {
  final int? sellerId;
  const ProductProfitSellerChanged(this.sellerId);
}

/// 「채널 합쳐 보기」 (true) / 「채널별로 보기」 (false). Folds the open savings row.
class ProductProfitCrossChannelChanged extends ProductProfitEvent {
  final bool crossChannel;
  const ProductProfitCrossChannelChanged({required this.crossChannel});
}

/// A sort key picked — the same key flips the direction, another key starts
/// descending.
class ProductProfitSortChanged extends ProductProfitEvent {
  final ProductProfitSortKey key;
  const ProductProfitSortChanged(this.key);
}

/// A row with option savings tapped — opens it, or folds it when already open.
class ProductProfitSavingsToggled extends ProductProfitEvent {
  final int masterProductId;
  const ProductProfitSavingsToggled(this.masterProductId);
}

/// 「출고 전 주문 제외」 switch (FEATURE_2611_04) — reloads the product rows only
/// (option savings do not depend on it).
class ProductProfitExcludeUnshippedChanged extends ProductProfitEvent {
  final bool excludeUnshipped;
  const ProductProfitExcludeUnshippedChanged({required this.excludeUnshipped});
}

/// [다시 시도].
class ProductProfitRetried extends ProductProfitEvent {
  const ProductProfitRetried();
}
