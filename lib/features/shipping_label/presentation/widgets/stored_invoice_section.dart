import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/order/presentation/widgets/internal_stage_badge.dart';
import '../../data/models/stored_invoice.dart';
import '../bloc/reserved_shipment_bloc.dart';
import '../bloc/reserved_shipment_event.dart';
import '../bloc/reserved_shipment_state.dart';
import 'reserved_shipment_row_tile.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';

/// 출고관리 내부 단계 주문 카드의 [송장 수정] — 그 주문의 「송장」을 바텀시트로 연다 (FEATURE_2609_75 / D18).
///
/// **파일**: lib/features/shipping_label/presentation/widgets/stored_invoice_section.dart
/// ⚠️ 시트마다 [ReservedShipmentBloc] 을 새로 만든다(그 주문 범위). 닫으면 폐기된다.
Future<void> showStoredInvoiceSheet(BuildContext context, String externalOrderId) =>
    showAppSheet<void>(
      context,
      builder: (_) => BlocProvider(
        create: (_) => getIt<ReservedShipmentBloc>()
          ..add(ReservedShipmentsRequested(externalOrderId: externalOrderId)),
        child: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: StoredInvoiceSection(inSheet: true),
          ),
        ),
      ),
    );

/// 「송장」 — one internal-stage shipment bundle = one row (shipment number ·
/// stage badge · carrier · invoice number · [송장 수정])
/// (FEATURE_2609_75 / D18).
///
/// **Purpose**: during 「내부 상품준비중」 · 「발송대기중」 the carrier and invoice
/// number can be entered or corrected at any time (E14 fetch · E12 save).
/// The invoice stays even when the reservation is cancelled —
/// [저장된 송장으로 발송] sends with this invoice.
/// **Used in**: order detail (above 「예약 발송 기록」) ·
/// [showStoredInvoiceSheet] (shipment management [송장 수정]).
/// ⚠️ A [ReservedShipmentBloc] of that order's scope
/// (`ReservedShipmentsRequested(externalOrderId: …)`) must be above it.
/// ⚠️ Errors are shown as red text inside the section.
/// With [inSheet] = true, loading · no permission · no target are also shown
/// as text (so the sheet is not empty). With false nothing is drawn in those
/// cases.
/// ❌ Do not save by the result row id — the path variable is the shipment
/// bundle id.
class StoredInvoiceSection extends StatelessWidget {
  final bool inSheet;

  const StoredInvoiceSection({super.key, this.inSheet = false});

  String _carrierName(ReservedShipmentState state, String? code) {
    if (code == null) return '-';
    for (final option in state.carrierOptions) {
      if (option.deliveryCompanyCode == code) return option.carrierName;
    }
    return code;
  }

  Future<void> _edit(
    BuildContext context,
    ReservedShipmentState state,
    StoredInvoice invoice,
  ) async {
    final bloc = context.read<ReservedShipmentBloc>();
    final picked = await showDialog<InvoiceEditInput>(
      context: context,
      builder: (_) => InvoiceEditDialog(
        options: state.carrierOptions,
        carrierCode: invoice.carrierCode,
        invoiceNumber: invoice.invoiceNumber,
      ),
    );
    if (picked == null || bloc.isClosed) return;
    bloc.add(StoredInvoiceChanged(
        invoice, picked.deliveryCompanyCode, picked.invoiceNumber));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReservedShipmentBloc, ReservedShipmentState>(
      builder: (context, state) {
        if (state.storedInvoices.isEmpty) {
          if (!inSheet) return const SizedBox.shrink();
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Text(state.forbidden
              ? '관리자만 볼 수 있습니다.'
              : '송장을 넣을 내부 단계 배송건이 없습니다.');
        }
        final muted = Theme.of(context).colorScheme.onSurfaceVariant;
        final anyBusy = state.busyId != null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '송장',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            if (state.errorAction == ReservedAction.storedInvoice &&
                state.actionError != null) ...[
              const SizedBox(height: 4),
              Text(
                state.actionError!,
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 8),
            for (final invoice in state.storedInvoices) ...[
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  invoice.externalShipmentId,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                InternalStageBadge(stage: invoice.internalStage),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_carrierName(state, invoice.carrierCode)} · '
                              '${invoice.invoiceNumber ?? '-'}',
                              style: TextStyle(fontSize: 12, color: muted),
                            ),
                          ],
                        ),
                      ),
                      if (state.carrierOptions.isNotEmpty)
                        OutlinedButton(
                          onPressed: anyBusy
                              ? null
                              : () => _edit(context, state, invoice),
                          child: state.busyAction ==
                                      ReservedAction.storedInvoice &&
                                  state.busyId == invoice.orderShipmentId
                              ? const AppBusyLabel('송장 수정')
                              : const Text('송장 수정'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}
