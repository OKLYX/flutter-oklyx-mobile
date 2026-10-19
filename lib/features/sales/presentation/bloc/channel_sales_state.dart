import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';

/// State of 「채널별 매출」 (FEATURE_2610_20 / D26) — the web `ChannelSalesContainer`
/// state.
class ChannelSalesState extends Equatable {
  final String from;
  final String to;
  final int? accountId;
  final bool loading;

  /// 403 → 「관리자만 볼 수 있습니다.」 (D20).
  final bool forbidden;
  final String error;
  final List<ChannelSales> channels;

  /// Products per channel (`crossChannel=false`) — filtered on screen by the
  /// chosen channel.
  final List<ProductProfit> products;
  final bool productsLoading;
  final String productsError;
  final List<SalesLine> records;
  final bool recordsLoading;
  final String recordsError;
  final bool hideCanceled;
  final bool hidePending;

  const ChannelSalesState({
    required this.from,
    required this.to,
    this.accountId,
    this.loading = false,
    this.forbidden = false,
    this.error = '',
    this.channels = const [],
    this.products = const [],
    this.productsLoading = false,
    this.productsError = '',
    this.records = const [],
    this.recordsLoading = false,
    this.recordsError = '',
    this.hideCanceled = false,
    this.hidePending = false,
  });

  bool get invalidRange =>
      from.isNotEmpty && to.isNotEmpty && from.compareTo(to) > 0;

  ChannelSales? get selected =>
      channels.where((c) => c.accountId == accountId).firstOrNull;

  /// The order lines left after the two checkboxes.
  List<SalesLine> get visibleRecords => records
      .where((r) =>
          !(hideCanceled && r.cancelQty > 0) && !(hidePending && r.holdQty > 0))
      .toList();

  ChannelSalesState copyWith({
    String? from,
    String? to,
    int? accountId,
    bool clearAccount = false,
    bool? loading,
    bool? forbidden,
    String? error,
    List<ChannelSales>? channels,
    List<ProductProfit>? products,
    bool? productsLoading,
    String? productsError,
    List<SalesLine>? records,
    bool? recordsLoading,
    String? recordsError,
    bool? hideCanceled,
    bool? hidePending,
  }) =>
      ChannelSalesState(
        from: from ?? this.from,
        to: to ?? this.to,
        accountId: clearAccount ? null : (accountId ?? this.accountId),
        loading: loading ?? this.loading,
        forbidden: forbidden ?? this.forbidden,
        error: error ?? this.error,
        channels: channels ?? this.channels,
        products: products ?? this.products,
        productsLoading: productsLoading ?? this.productsLoading,
        productsError: productsError ?? this.productsError,
        records: records ?? this.records,
        recordsLoading: recordsLoading ?? this.recordsLoading,
        recordsError: recordsError ?? this.recordsError,
        hideCanceled: hideCanceled ?? this.hideCanceled,
        hidePending: hidePending ?? this.hidePending,
      );

  @override
  List<Object?> get props => [
        from,
        to,
        accountId,
        loading,
        forbidden,
        error,
        channels,
        products,
        productsLoading,
        productsError,
        records,
        recordsLoading,
        recordsError,
        hideCanceled,
        hidePending,
      ];
}
