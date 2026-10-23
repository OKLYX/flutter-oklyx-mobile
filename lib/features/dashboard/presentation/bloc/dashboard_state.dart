import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/utils/dashboard_layout.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';

/// Load state of the stored cards.
enum DashboardStatus { loading, error, ready }

/// Result of the last save — the page shows a toast when
/// `DashboardState.saveVersion` changes.
enum DashboardSaveResult { none, saved, failed }

/// State of the dashboard (FEATURE_2610_29) — the web `DashboardHome` state,
/// plus the seller picked on each chart card (the web keeps that in each
/// chart card, FEATURE_2610_30 / D36).
class DashboardState extends Equatable {
  final DashboardStatus status;

  /// true = ADMIN — the admin cards may be added (D9).
  final bool admin;
  final List<MobileCard> cards;
  final bool editing;
  final bool saving;

  /// +1 on a failed save and on a save of [편집 완료].
  final int saveVersion;
  final DashboardSaveResult saveResult;

  /// Failure text of the last save; empty on success.
  final String saveMessage;

  /// Seller list of the chart cards' selectors (FEATURE_2610_30 / D37); empty
  /// until read and after a failed read.
  final List<Seller> sellers;

  /// Seller picked on each chart card; a card that is not here shows 「전체」
  /// (FEATURE_2610_30 / D34 · D35 · D36).
  final Map<DashboardCardType, int> chartSellers;

  const DashboardState({
    this.status = DashboardStatus.loading,
    this.admin = false,
    this.cards = const [],
    this.editing = false,
    this.saving = false,
    this.saveVersion = 0,
    this.saveResult = DashboardSaveResult.none,
    this.saveMessage = '',
    this.sellers = const [],
    this.chartSellers = const {},
  });

  DashboardState copyWith({
    DashboardStatus? status,
    bool? admin,
    List<MobileCard>? cards,
    bool? editing,
    bool? saving,
    int? saveVersion,
    DashboardSaveResult? saveResult,
    String? saveMessage,
    List<Seller>? sellers,
    Map<DashboardCardType, int>? chartSellers,
  }) =>
      DashboardState(
        status: status ?? this.status,
        admin: admin ?? this.admin,
        cards: cards ?? this.cards,
        editing: editing ?? this.editing,
        saving: saving ?? this.saving,
        saveVersion: saveVersion ?? this.saveVersion,
        saveResult: saveResult ?? this.saveResult,
        saveMessage: saveMessage ?? this.saveMessage,
        sellers: sellers ?? this.sellers,
        chartSellers: chartSellers ?? this.chartSellers,
      );

  @override
  List<Object?> get props => [
        status,
        admin,
        cards,
        editing,
        saving,
        saveVersion,
        saveResult,
        saveMessage,
        sellers,
        chartSellers,
      ];
}
