import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../bloc/reserved_shipment_bloc.dart';
import '../bloc/reserved_shipment_event.dart';
import '../bloc/reserved_shipment_state.dart';
import '../widgets/reserved_shipment_row_tile.dart';

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

class _ReservedShipmentView extends StatelessWidget {
  const _ReservedShipmentView();

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
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.actionError!),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
              ),
            );
        },
        builder: (context, state) {
          if (state.loading && state.rows.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.forbidden) {
            return const Center(child: Text('관리자만 볼 수 있습니다.'));
          }
          if (state.loadError != null && state.rows.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.loadError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<ReservedShipmentBloc>()
                        .add(const ReservedShipmentsRequested()),
                    child: const Text('재시도'),
                  ),
                ],
              ),
            );
          }
          final completed = state.rows
              .where((r) => r.result == 'SUCCEEDED' || r.result == 'EXTERNAL')
              .length;
          final failed = state.rows.where((r) => r.result == 'FAILED').length;
          return RefreshIndicator(
            onRefresh: () async => context
                .read<ReservedShipmentBloc>()
                .add(const ReservedShipmentsRequested()),
            child: state.rows.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('예약 발송이 없습니다.')),
                    ],
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      kBottomNavigationBarHeight +
                          MediaQuery.paddingOf(context).bottom +
                          16,
                    ),
                    itemCount: state.rows.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => index == 0
                        ? Text(
                            '${state.rows.length}건 중 $completed건 완료, 실패 $failed건',
                            style: const TextStyle(fontSize: 13),
                          )
                        : ReservedShipmentRowTile(
                            row: state.rows[index - 1],
                            state: state,
                            showInvoiceEdit: true,
                          ),
                  ),
          );
        },
      ),
    );
  }
}
