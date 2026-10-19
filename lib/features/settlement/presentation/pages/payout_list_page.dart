import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/bloc/payout_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/bloc/payout_list_event.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/bloc/payout_list_state.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/first_month_question_bar.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/payout_filter_row.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/payout_tile.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/sale_month_list.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/settlement_backfill_sheet.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/settlement_message_box.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/settlement_sync_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

/// 「정산 내역」 page (FEATURE_2610_20 / D18 · D19 · D20 · D24 · D25 · D45 ⑦) — the
/// mobile twin of the web `PayoutListContainer`.
///
/// 🔴 Entry calls lookups only; the three buttons of [SettlementSyncBar] are
/// the only market calls (D19).
/// ⚠️ The app going to the background stops a running backfill (D25) —
/// [PayoutBackfillStopped].
class PayoutListPage extends StatelessWidget {
  const PayoutListPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<PayoutListBloc>()..add(const PayoutListStarted()),
        child: const _PayoutListView(),
      );
}

class _PayoutListView extends StatefulWidget {
  const _PayoutListView();

  @override
  State<_PayoutListView> createState() => _PayoutListViewState();
}

class _PayoutListViewState extends State<_PayoutListView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.paused) {
      context.read<PayoutListBloc>().add(const PayoutBackfillStopped());
    }
  }

  /// The latest of every channel's value — the bar shows one time per kind.
  static String? _latest(List<SettlementSyncTarget> channels,
      String? Function(SettlementSyncTarget) pick) {
    String? result;
    for (final channel in channels) {
      final value = pick(channel);
      if (value != null && (result == null || value.compareTo(result) > 0)) {
        result = value;
      }
    }
    return result;
  }

  Future<void> _openBackfill(BuildContext context) async {
    final bloc = context.read<PayoutListBloc>();
    await showAppSheet<void>(
      context,
      builder: (_) => BlocProvider.value(
          value: bloc, child: const SettlementBackfillSheet()),
    );
  }

  @override
  Widget build(BuildContext context) => ScaffoldWithNavBar(
        title: '정산 내역',
        navBarIndex: 2,
        showAppBarDrawerButton: false,
        body: BlocBuilder<PayoutListBloc, PayoutListState>(
          builder: (context, state) {
            final bloc = context.read<PayoutListBloc>();
            if (state.forbidden) {
              return const AppPageBody(children: [AppEmpty('관리자만 볼 수 있습니다.')]);
            }
            final saleMonthReady = state.accountId != null &&
                state.from.isNotEmpty &&
                state.to.isNotEmpty;
            return AppPageBody(
              children: [
                FirstMonthQuestionBar(
                  questions: state.questions,
                  answeringLinkId: state.answeringLinkId,
                  error: state.questionError,
                  onAnswer: (linkId, {required charged}) => bloc.add(
                      PayoutFirstMonthAnswered(
                          linkId: linkId, charged: charged)),
                ),
                SettlementSyncBar(
                  lastSyncedAt:
                      _latest(state.channels, (t) => t.lastSettlementSyncAt),
                  lastPayoutSyncedAt:
                      _latest(state.channels, (t) => t.lastPayoutSyncAt),
                  syncing: state.syncing,
                  payoutSyncing: state.payoutSyncing,
                  backfillRunning: state.backfillRunning,
                  rateLimitedMessage: state.rateLimited,
                  notice: state.syncNotice,
                  error: state.syncError,
                  onSync: () => bloc.add(const PayoutRevenueSyncRequested()),
                  onSyncPayout: () =>
                      bloc.add(const PayoutPayoutSyncRequested()),
                  onBackfill: () => _openBackfill(context),
                ),
                const SizedBox(height: 12),
                SegmentedButton<PayoutViewMode>(
                  segments: const [
                    ButtonSegment(
                        value: PayoutViewMode.payout, label: Text('정산 기준')),
                    ButtonSegment(
                        value: PayoutViewMode.saleMonth, label: Text('판매월 기준')),
                  ],
                  selected: {state.viewMode},
                  onSelectionChanged: (selected) =>
                      bloc.add(PayoutViewModeChanged(selected.first)),
                ),
                const SizedBox(height: 4),
                Text(
                  state.viewMode == PayoutViewMode.payout
                      ? '정산 건에서 어떤 판매였는지 내려다봅니다.'
                      : '판매에서 언제 정산됐는지 올려다봅니다.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                PayoutFilterRow(
                  sellers: state.sellers,
                  channels: state.channels,
                  sellerId: state.sellerId,
                  accountId: state.accountId,
                  from: state.from,
                  to: state.to,
                  disabled: state.loading,
                  onSellerChanged: (id) => bloc.add(PayoutSellerChanged(id)),
                  onChannelChanged: (id) => bloc.add(PayoutChannelChanged(id)),
                  onPeriodChanged: (from, to) =>
                      bloc.add(PayoutPeriodChanged(from: from, to: to)),
                ),
                if (state.invalidRange) ...[
                  const SizedBox(height: 8),
                  const SettlementMessageBox(
                      tone: SettlementMessageTone.error,
                      message: '시작일이 종료일보다 뒤입니다.'),
                ],
                const SizedBox(height: 12),
                if (state.viewMode == PayoutViewMode.payout)
                  ..._payoutRows(context, state)
                else if (!saleMonthReady)
                  const AppEmpty('판매월 기준으로 보려면 채널과 기간을 모두 골라 주세요.')
                else
                  SaleMonthList(
                    rows: state.saleMonths,
                    loading: state.saleMonthsLoading,
                    error: state.saleMonthsError,
                    onRetry: () => bloc.add(const PayoutListRetried()),
                  ),
              ],
            );
          },
        ),
      );

  List<Widget> _payoutRows(BuildContext context, PayoutListState state) {
    if (state.loading && state.rows.isEmpty) {
      return const [AppLoading()];
    }
    if (state.error.isNotEmpty) {
      return [
        AppErrorBox(
          message: state.error,
          action: TextButton(
            onPressed: () =>
                context.read<PayoutListBloc>().add(const PayoutListRetried()),
            child: const Text('다시 시도'),
          ),
        ),
      ];
    }
    if (state.rows.isEmpty) {
      return const [AppEmpty('아직 수신된 정산 내역이 없습니다. [갱신] 을 눌러 불러오세요.')];
    }
    return [
      for (var i = 0; i < state.rows.length; i++) ...[
        if (i > 0) const AppRowGap(),
        PayoutTile(
          row: state.rows[i],
          onOpen: () => context.goNamed(
            Routes.settlementPayoutDetail,
            pathParameters: {'id': '${state.rows[i].payoutId}'},
          ),
        ),
      ],
    ];
  }
}
