import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import '../../data/models/carrier_option.dart';
import '../../data/models/reserved_shipment_row.dart';
import '../bloc/reserved_shipment_bloc.dart';
import '../bloc/reserved_shipment_event.dart';
import '../bloc/reserved_shipment_state.dart';
import '../utils/reserved_time_picker.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// 예약 발송 행 1개 카드 (FEATURE_2609_75 / D15·D16·D18·D30).
///
/// **용도**: 한 줄 = 주문 1개 — 주문번호 · 결과(+처리 중/자동 재시도 중단/지연 실행 칩) · 예정·실행 시각 · 송장 · 사유 +
/// [시각 변경]·[송장 수정]·[다시 시도]·[예약 취소].
/// **사용처**: `ReservedShipmentPage`(전체, [showInvoiceEdit] true) · 주문 상세의 「예약 발송 기록」(그 주문, false).
/// **파일**: lib/features/shipping_label/presentation/widgets/reserved_shipment_row_tile.dart
/// ⚠️ 위에 [ReservedShipmentBloc] 이 있어야 한다. 시각은 [formatOrderDateTime]·[pickReservedExecuteAt] 만 쓴다.
/// ❌ 예약(묶음) 단위로 묶어 그리지 않는다(D30). ❌ [지금 실행] 버튼을 두지 않는다(D21 🔁).
class ReservedShipmentRowTile extends StatelessWidget {
  final ReservedShipmentRow row;
  final ReservedShipmentState state;

  /// false = [송장 수정]을 그리지 않는다(주문 상세 — 그 화면의 송장 수정 자리는 「송장」 하나다, D18).
  final bool showInvoiceEdit;

  const ReservedShipmentRowTile({
    super.key,
    required this.row,
    required this.state,
    required this.showInvoiceEdit,
  });

  bool _isBusy(ReservedAction action) =>
      state.busyId == row.id && state.busyAction == action;

  Widget _chip(String text, {Color? background, Color? foreground}) => Chip(
        label: Text(text, style: TextStyle(fontSize: 12, color: foreground)),
        backgroundColor: background,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  Future<void> _changeTime(BuildContext context) async {
    final bloc = context.read<ReservedShipmentBloc>();
    final picked = await pickReservedExecuteAt(context, row.executeAt);
    if (picked == null || bloc.isClosed) return;
    bloc.add(ReservationTimeChanged(row, picked));
  }

  Future<void> _changeInvoice(BuildContext context) async {
    final bloc = context.read<ReservedShipmentBloc>();
    final picked = await showDialog<InvoiceEditInput>(
      context: context,
      builder: (_) => InvoiceEditDialog(
        options: state.carrierOptions,
        carrierCode: row.carrierCode,
        invoiceNumber: row.invoiceNumber,
      ),
    );
    if (picked == null || bloc.isClosed) return;
    bloc.add(ReservationInvoiceChanged(
        row, picked.deliveryCompanyCode, picked.invoiceNumber));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ReservedShipmentBloc>();
    final anyBusy = state.busyId != null;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return AppCard.row(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  row.externalOrderId,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                _chip(kReservedResultLabels[row.result] ?? row.result),
                if (row.isOpen &&
                    (row.status == 'RUNNING' || row.status == 'STOPPED'))
                  _chip(kReservedStatusLabels[row.status] ?? row.status),
                if (row.firstRunKind == 'DELAYED')
                  _chip('지연 실행',
                      background: AppColors.warningSurface,
                      foreground: AppColors.warningForeground),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '예정 ${formatOrderDateTime(row.executeAt)} · '
              '실행 ${formatOrderDateTime(row.lastRunAt)}',
              style: TextStyle(fontSize: 12, color: muted),
            ),
            Text(
              '송장 ${row.invoiceNumber ?? '-'}',
              style: TextStyle(fontSize: 12, color: muted),
            ),
            // D16 — 사유는 접지 않고 늘 보인다.
            if (row.failureReason != null)
              Text(
                row.failureReason!,
                style: TextStyle(
                  fontSize: 12,
                  color: row.result == 'FAILED'
                      ? Theme.of(context).colorScheme.error
                      : muted,
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (row.isEditable)
                  OutlinedButton(
                    onPressed: anyBusy ? null : () => _changeTime(context),
                    child: _isBusy(ReservedAction.time)
                        ? const AppBusyLabel('시각 변경')
                        : const Text('시각 변경'),
                  ),
                if (showInvoiceEdit &&
                    row.isInvoiceEditable &&
                    state.carrierOptions.isNotEmpty)
                  OutlinedButton(
                    onPressed: anyBusy ? null : () => _changeInvoice(context),
                    child: _isBusy(ReservedAction.invoice)
                        ? const AppBusyLabel('송장 수정')
                        : const Text('송장 수정'),
                  ),
                if (row.status == 'STOPPED' && row.result == 'FAILED')
                  FilledButton(
                    onPressed: anyBusy
                        ? null
                        : () => bloc.add(ReservationRetryRequested(row)),
                    child: _isBusy(ReservedAction.retry)
                        ? const AppBusyLabel('다시 시도')
                        : const Text('다시 시도'),
                  ),
                if (row.isOpen && row.status != 'RUNNING')
                  OutlinedButton(
                    onPressed: anyBusy
                        ? null
                        : () => bloc.add(ReservationCancelRequested(row)),
                    child: _isBusy(ReservedAction.cancel)
                        ? const AppBusyLabel('예약 취소')
                        : const Text('예약 취소'),
                  ),
              ],
            ),
          ],
        ),
    );
  }
}

/// [송장 수정] 다이얼로그 결과.
class InvoiceEditInput {
  final String deliveryCompanyCode;
  final String invoiceNumber;

  const InvoiceEditInput(this.deliveryCompanyCode, this.invoiceNumber);
}

/// [송장 수정] 다이얼로그 — 택배사 드롭다운 + 송장번호. [저장]만 값을 돌려주고 [취소]는 null (FEATURE_2609_75 / D18).
///
/// **사용처**: 현황 카드([ReservedShipmentRowTile]) · 「송장」(`StoredInvoiceSection`) — 두 곳이 같은 다이얼로그를 쓴다.
/// [carrierCode]·[invoiceNumber] = 처음 채울 값(없으면 null — 택배사 미선택·빈 칸).
/// ❌ 화면마다 송장 입력 다이얼로그 사본을 만들지 말 것.
class InvoiceEditDialog extends StatefulWidget {
  final List<CarrierOption> options;
  final String? carrierCode;
  final String? invoiceNumber;

  const InvoiceEditDialog({
    super.key,
    required this.options,
    required this.carrierCode,
    required this.invoiceNumber,
  });

  @override
  State<InvoiceEditDialog> createState() => _InvoiceEditDialogState();
}

class _InvoiceEditDialogState extends State<InvoiceEditDialog> {
  late String? _carrierCode =
      widget.options.any((o) => o.deliveryCompanyCode == widget.carrierCode)
          ? widget.carrierCode
          : null;
  late final TextEditingController _invoiceController =
      TextEditingController(text: widget.invoiceNumber ?? '');

  @override
  void dispose() {
    _invoiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave =
        _carrierCode != null && _invoiceController.text.trim().isNotEmpty;
    return AlertDialog(
      title: const Text('송장 수정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _carrierCode,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: '택배사',
            ),
            items: widget.options
                .map((o) => DropdownMenuItem<String>(
                      value: o.deliveryCompanyCode,
                      child:
                          Text(o.carrierName, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _carrierCode = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _invoiceController,
            decoration: const InputDecoration(
              labelText: '송장번호',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: canSave
              ? () => Navigator.of(context).pop(InvoiceEditInput(
                  _carrierCode!, _invoiceController.text.trim()))
              : null,
          child: const Text('저장'),
        ),
      ],
    );
  }
}
