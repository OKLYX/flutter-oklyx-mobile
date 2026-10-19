import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';

/// State of the payout detail screen (FEATURE_2610_20 / D22 · D23 · D34 · D39)
/// — the mobile twin of the web `PayoutDetailContainer` state.
class PayoutDetailState extends Equatable {
  final bool loading;

  /// 403 → 「관리자만 볼 수 있습니다.」 (D20).
  final bool forbidden;
  final String error;
  final ReconReport? report;

  /// The one expanded cause label; empty = none.
  final String expandedLabel;
  final bool unmatchedOnly;

  /// Lines of [expandedLabel] or of 「미분류」 — kept apart from [orderLines] (web
  /// keeps two lists too).
  final List<ReconLineView> lines;
  final bool linesLoading;
  final String linesError;

  /// Every line of the payout (「이 정산에 포함된 주문」).
  final List<ReconLineView> orderLines;
  final bool orderLinesLoading;
  final String orderLinesError;
  final bool exporting;

  /// Bytes of the last export; [exportTick] changes once per export so the page
  /// saves it once.
  final Uint8List? exportBytes;
  final int exportTick;

  /// 「지급 완료」 / 「지급 완료 취소」 running.
  final bool marking;

  /// One-shot toast — the page shows it when [toastTick] changes.
  final String toastMessage;
  final bool toastIsError;
  final int toastTick;

  const PayoutDetailState({
    this.loading = true,
    this.forbidden = false,
    this.error = '',
    this.report,
    this.expandedLabel = '',
    this.unmatchedOnly = false,
    this.lines = const [],
    this.linesLoading = false,
    this.linesError = '',
    this.orderLines = const [],
    this.orderLinesLoading = false,
    this.orderLinesError = '',
    this.exporting = false,
    this.exportBytes,
    this.exportTick = 0,
    this.marking = false,
    this.toastMessage = '',
    this.toastIsError = false,
    this.toastTick = 0,
  });

  PayoutDetailState copyWith({
    bool? loading,
    bool? forbidden,
    String? error,
    ReconReport? report,
    String? expandedLabel,
    bool? unmatchedOnly,
    List<ReconLineView>? lines,
    bool? linesLoading,
    String? linesError,
    List<ReconLineView>? orderLines,
    bool? orderLinesLoading,
    String? orderLinesError,
    bool? exporting,
    Uint8List? exportBytes,
    int? exportTick,
    bool? marking,
    String? toastMessage,
    bool? toastIsError,
    int? toastTick,
  }) =>
      PayoutDetailState(
        loading: loading ?? this.loading,
        forbidden: forbidden ?? this.forbidden,
        error: error ?? this.error,
        report: report ?? this.report,
        expandedLabel: expandedLabel ?? this.expandedLabel,
        unmatchedOnly: unmatchedOnly ?? this.unmatchedOnly,
        lines: lines ?? this.lines,
        linesLoading: linesLoading ?? this.linesLoading,
        linesError: linesError ?? this.linesError,
        orderLines: orderLines ?? this.orderLines,
        orderLinesLoading: orderLinesLoading ?? this.orderLinesLoading,
        orderLinesError: orderLinesError ?? this.orderLinesError,
        exporting: exporting ?? this.exporting,
        exportBytes: exportBytes ?? this.exportBytes,
        exportTick: exportTick ?? this.exportTick,
        marking: marking ?? this.marking,
        toastMessage: toastMessage ?? this.toastMessage,
        toastIsError: toastIsError ?? this.toastIsError,
        toastTick: toastTick ?? this.toastTick,
      );

  @override
  List<Object?> get props => [
        loading,
        forbidden,
        error,
        report,
        expandedLabel,
        unmatchedOnly,
        lines,
        linesLoading,
        linesError,
        orderLines,
        orderLinesLoading,
        orderLinesError,
        exporting,
        exportTick,
        marking,
        toastMessage,
        toastIsError,
        toastTick,
      ];
}
