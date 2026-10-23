import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/utils/dashboard_layout.dart';

/// Load state of the stored cards.
enum DashboardStatus { loading, error, ready }

/// Result of the last save — the page shows a toast when
/// `DashboardState.saveVersion` changes.
enum DashboardSaveResult { none, saved, failed }

/// State of the dashboard (FEATURE_2610_29) — the web `DashboardHome` state.
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

  const DashboardState({
    this.status = DashboardStatus.loading,
    this.admin = false,
    this.cards = const [],
    this.editing = false,
    this.saving = false,
    this.saveVersion = 0,
    this.saveResult = DashboardSaveResult.none,
    this.saveMessage = '',
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
      ];
}
