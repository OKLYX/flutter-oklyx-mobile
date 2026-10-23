import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/alert_usecase.dart';
import 'alert_summary_event.dart';
import 'alert_summary_state.dart';

/// Alert badge counts (FEATURE_2609_49 / D9).
///
/// **Purpose**: the to-do counts of the Drawer menu, the bell and the dashboard
/// cards C1~C4. The single source of the places that show "how many to-dos are
/// there".
/// **Rule**: a screen does not count its own list length — it uses this Bloc
/// (the lists carry filters).
/// **File**: lib/features/alert/presentation/bloc/alert_summary_bloc.dart
///
/// 🔴 **The badge numbers do not match the row count of the list screens — this
/// is normal.** A badge counts the open / unanswered items in full (regardless
/// of type and period; the real upper bound is the server's STALE 30 days),
/// while the claim and inquiry screens default to 「반품」 + the last 2 weeks.
/// Do not narrow the badge to match — old unhandled items are why the badge
/// exists.
///
/// **Usage**:
/// BlocBuilder<AlertSummaryBloc, AlertSummaryState>(
///   builder: (context, state) => AlertBadge(count: state.openClaims),
/// )
///
/// 🔴 **One per app** (`registerSingleton`). The Drawer is rebuilt each time it
/// opens, so as a factory it would restart from 0 and the number would flicker.
/// 🔴 **No timer.** Refreshed when the Drawer opens (`AppDrawer.initState`),
/// when a screen changes (`ScaffoldWithNavBar.initState`), on the notification
/// page refresh and on dashboard entry (`DashboardPage.initState`) — polling
/// while closed just spends battery.
/// ⚠️ A failure **keeps the previous value** and shows no error. Badges are
/// secondary information, and an error drawn in the Drawer would spread to the
/// screens that show it.
class AlertSummaryBloc extends Bloc<AlertSummaryEvent, AlertSummaryState> {
  final AlertUseCase alertUseCase;

  AlertSummaryBloc({required this.alertUseCase})
      : super(const AlertSummaryState()) {
    on<LoadAlertSummary>(_onLoad);
  }

  Future<void> _onLoad(
    LoadAlertSummary event,
    Emitter<AlertSummaryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await alertUseCase.getSummary();
    if (emit.isDone) return;
    // 실패는 숫자를 건드리지 않는다 — 직전 값을 그대로 둔다(위 주석).
    emit(result.fold(
      (_) => state.copyWith(isLoading: false),
      (summary) => state.copyWith(
        openClaims: summary.openClaims,
        unansweredInquiries: summary.unansweredInquiries,
        paidOrders: summary.paidOrders,
        newOrders: summary.newOrders,
        todoCount: summary.todoCount,
        isLoading: false,
      ),
    ));
  }
}
