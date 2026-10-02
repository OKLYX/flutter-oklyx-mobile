import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/reserved_shipment_bloc.dart';
import '../bloc/reserved_shipment_state.dart';
import 'reserved_shipment_row_tile.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';

/// 주문 상세 「예약 발송 기록」 (FEATURE_2609_75 / D30).
///
/// **용도**: 그 주문의 예정·실행 시각과 결과(기간 제한 없음) + 행 작업([시각 변경]·[다시 시도]·[예약 취소]).
/// 행 카드는 [ReservedShipmentRowTile] 그대로, [송장 수정]은 그리지 않는다(`showInvoiceEdit: false` — 주문 상세의 송장 수정 자리는
/// 「송장」 `StoredInvoiceSection` 하나다, D18).
/// **사용처**: `OrderDetailPage` — 위에 `ReservedShipmentsRequested(externalOrderId: …)` 로 만든 [ReservedShipmentBloc] 이 있어야 한다.
/// **파일**: lib/features/shipping_label/presentation/widgets/reserved_shipment_history_section.dart
/// ⚠️ 기록이 없거나·권한이 없거나(403)·불러오지 못하면 아무것도 그리지 않는다(예약을 쓰지 않는 주문이 대부분이다).
class ReservedShipmentHistorySection extends StatelessWidget {
  const ReservedShipmentHistorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReservedShipmentBloc, ReservedShipmentState>(
      // Errors of 「송장」 are shown by that section itself
      // (errorAction == storedInvoice) — no toast is stacked on top here.
      listenWhen: (prev, curr) =>
          curr.actionError != null &&
          curr.actionError != prev.actionError &&
          curr.errorAction != ReservedAction.storedInvoice,
      listener: (context, state) {
        showErrorToast(context, state.actionError!);
      },
      builder: (context, state) {
        if (state.forbidden || state.rows.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '예약 발송 기록',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final row in state.rows) ...[
              ReservedShipmentRowTile(
                  row: row, state: state, showInvoiceEdit: false),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }
}
