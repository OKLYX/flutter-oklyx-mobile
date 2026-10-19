import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/sales/domain/entities/sales.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';

/// State of 「통합 매출 조회」 (FEATURE_2610_20 / D26) — the web
/// `SalesSummaryContainer` state.
class SalesSummaryState extends Equatable {
  final String from;
  final String to;
  final bool loading;

  /// 403 → 「관리자만 볼 수 있습니다.」 (D20).
  final bool forbidden;
  final String error;
  final List<SellerSales> rows;
  final int? expandedSellerId;
  final List<ChannelSales> channels;
  final bool channelsLoading;
  final String channelsError;

  /// Payouts of the open seller (recognition axis) — one call per seller, not
  /// per channel.
  final List<PayoutSummary> payouts;
  final bool payoutsLoading;
  final String payoutsError;
  final SavingsSummary? savings;
  final List<BoxSaving> boxSavings;
  final bool savingsLoading;
  final String savingsError;

  const SalesSummaryState({
    required this.from,
    required this.to,
    this.loading = false,
    this.forbidden = false,
    this.error = '',
    this.rows = const [],
    this.expandedSellerId,
    this.channels = const [],
    this.channelsLoading = false,
    this.channelsError = '',
    this.payouts = const [],
    this.payoutsLoading = false,
    this.payoutsError = '',
    this.savings,
    this.boxSavings = const [],
    this.savingsLoading = false,
    this.savingsError = '',
  });

  bool get invalidRange =>
      from.isNotEmpty && to.isNotEmpty && from.compareTo(to) > 0;

  SalesSummaryState copyWith({
    String? from,
    String? to,
    bool? loading,
    bool? forbidden,
    String? error,
    List<SellerSales>? rows,
    int? expandedSellerId,
    bool clearExpanded = false,
    List<ChannelSales>? channels,
    bool? channelsLoading,
    String? channelsError,
    List<PayoutSummary>? payouts,
    bool? payoutsLoading,
    String? payoutsError,
    SavingsSummary? savings,
    bool clearSavings = false,
    List<BoxSaving>? boxSavings,
    bool? savingsLoading,
    String? savingsError,
  }) =>
      SalesSummaryState(
        from: from ?? this.from,
        to: to ?? this.to,
        loading: loading ?? this.loading,
        forbidden: forbidden ?? this.forbidden,
        error: error ?? this.error,
        rows: rows ?? this.rows,
        expandedSellerId:
            clearExpanded ? null : (expandedSellerId ?? this.expandedSellerId),
        channels: channels ?? this.channels,
        channelsLoading: channelsLoading ?? this.channelsLoading,
        channelsError: channelsError ?? this.channelsError,
        payouts: payouts ?? this.payouts,
        payoutsLoading: payoutsLoading ?? this.payoutsLoading,
        payoutsError: payoutsError ?? this.payoutsError,
        savings: clearSavings ? null : (savings ?? this.savings),
        boxSavings: boxSavings ?? this.boxSavings,
        savingsLoading: savingsLoading ?? this.savingsLoading,
        savingsError: savingsError ?? this.savingsError,
      );

  @override
  List<Object?> get props => [
        from,
        to,
        loading,
        forbidden,
        error,
        rows,
        expandedSellerId,
        channels,
        channelsLoading,
        channelsError,
        payouts,
        payoutsLoading,
        payoutsError,
        savings,
        boxSavings,
        savingsLoading,
        savingsError,
      ];
}
