import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../bloc/reserved_shipment_bloc.dart';
import '../bloc/reserved_shipment_event.dart';
import '../bloc/reserved_shipment_state.dart';
import '../widgets/reserved_filter_bar.dart';
import '../widgets/reserved_shipment_row_tile.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// 출고관리 > 예약 발송 현황 페이지 (FEATURE_2609_75 / D15·D16·D17·D18·D30).
///
/// **용도**: 한 줄 = 주문 1개(끝나지 않은 것 전부 + 끝난 것 최근 7일 — 서버 범위). 맨 위 요약
/// "N건 중 M건 완료, 실패 K건". 행 카드와 행 작업은 [ReservedShipmentRowTile]. 웹 출고관리의 「예약 발송」 카드와 같은 내용이다.
/// **진입**: 출고관리 [예약 발송 현황] 버튼(`context.push`) — 돌아가면 출고관리가 목록을 다시 불러온다.
/// **파일**: lib/features/shipping_label/presentation/pages/reserved_shipment_page.dart
///
/// ⚠️ 권한은 백엔드 403 에 의존한다(발송처리 버튼과 같다).
/// ❌ 결과를 화면에서 다시 판정하지 않는다 — 결과 칸은 서버 `result` 그대로, 요약은 `result` 값 개수만 센다.
class ReservedShipmentPage extends StatelessWidget {
  const ReservedShipmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReservedShipmentBloc>()
        ..add(const ReservedShipmentsRequested()),
      child: const _ReservedShipmentView(),
    );
  }
}

class _ReservedShipmentView extends StatefulWidget {
  const _ReservedShipmentView();

  @override
  State<_ReservedShipmentView> createState() => _ReservedShipmentViewState();
}

class _ReservedShipmentViewState extends State<_ReservedShipmentView> {
  /// Chip choice (FEATURE_2610_07 / D1·D8). Page state only — a new visit
  /// starts at [ReservedFilter.open]; reloads and row actions keep the chip.
  ReservedFilter _filter = ReservedFilter.open;

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '예약 발송',
      navBarIndex: 2,
      showDrawer: true,
      onBackPressed: () => context.pop(),
      body: BlocConsumer<ReservedShipmentBloc, ReservedShipmentState>(
        listenWhen: (prev, curr) =>
            curr.actionError != null && curr.actionError != prev.actionError,
        listener: (context, state) {
          showErrorToast(context, state.actionError!);
        },
        builder: (context, state) {
          if (state.loading && state.rows.isEmpty) {
            return const AppPageBody(children: [AppLoading()]);
          }
          if (state.forbidden) {
            return const Center(child: Text('관리자만 볼 수 있습니다.'));
          }
          if (state.loadError != null && state.rows.isEmpty) {
            return AppPageBody(
              children: [
                AppErrorBox(
                  message: state.loadError!,
                  action: FilledButton(
                    onPressed: () => context
                        .read<ReservedShipmentBloc>()
                        .add(const ReservedShipmentsRequested()),
                    child: const Text('다시 시도'),
                  ),
                ),
              ],
            );
          }
          final completed = state.rows
              .where((r) => r.result == 'SUCCEEDED' || r.result == 'EXTERNAL')
              .length;
          final failed = state.rows.where((r) => r.result == 'FAILED').length;
          // The chip only narrows the cards; the summary line still counts
          // every row (FEATURE_2610_07 / D3).
          final shown = state.rows
              .where((r) => matchesReservedFilter(r, _filter))
              .toList();
          return RefreshIndicator(
            onRefresh: () async => context
                .read<ReservedShipmentBloc>()
                .add(const ReservedShipmentsRequested()),
            child: AppPageBody.slivers(
              slivers: [
                if (state.rows.isEmpty)
                  const SliverToBoxAdapter(child: AppEmpty('예약 발송이 없습니다.'))
                else ...[
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.rows.length}건 중 $completed건 완료, 실패 $failed건',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        ReservedFilterBar(
                          rows: state.rows,
                          selected: _filter,
                          onSelect: (filter) =>
                              setState(() => _filter = filter),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  if (shown.isEmpty)
                    SliverToBoxAdapter(
                      child: AppEmpty(
                        _filter == ReservedFilter.open
                            ? '처리할 예약 발송이 없습니다.'
                            : '완료된 예약 발송이 없습니다.',
                      ),
                    )
                  else
                    SliverList.separated(
                      itemCount: shown.length,
                      separatorBuilder: (_, __) => const AppRowGap(),
                      itemBuilder: (context, index) => ReservedShipmentRowTile(
                        row: shown[index],
                        state: state,
                        showInvoiceEdit: true,
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
