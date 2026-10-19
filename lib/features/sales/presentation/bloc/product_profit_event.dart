import 'package:flutter_oklyn_mobile/features/sales/presentation/bloc/product_profit_state.dart';

/// Events of the 「상품별 매출」 BLoC (FEATURE_2610_20 / D26).
sealed class ProductProfitEvent {
  const ProductProfitEvent();
}

/// Screen entry — sellers, product rows and option savings of this month.
class ProductProfitStarted extends ProductProfitEvent {
  const ProductProfitStarted();
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

/// [다시 시도].
class ProductProfitRetried extends ProductProfitEvent {
  const ProductProfitRetried();
}
