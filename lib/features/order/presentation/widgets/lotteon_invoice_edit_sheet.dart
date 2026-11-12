import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';
import '../../../shipping_label/data/models/carrier_option.dart';
import '../../data/models/lotteon_invoice_records.dart';
import '../../domain/entities/order_item.dart';
import '../bloc/lotteon_invoice_edit_cubit.dart';

/// Opens the LotteON 「송장 수정」 sheet of a shipped LotteON order and tells
/// whether at least one record was updated (FEATURE_2611_23 / D19 ⑥ · R52).
///
/// The function holds the Cubit so its result can be read after the sheet
/// closes — every way of closing (drag, tap outside, back, [취소]) is read
/// the same way. A new Cubit for every open (R57).
///
/// ```dart
/// if (await showLotteonInvoiceEditSheet(context,
///     order: order, carrierOptions: options)) {
///   await detail.reload();
/// }
/// ```
Future<bool> showLotteonInvoiceEditSheet(
  BuildContext context, {
  required OrderItem order,
  required List<CarrierOption> carrierOptions,
}) async {
  // ignore: unawaited_futures
  final cubit = getIt<LotteonInvoiceEditCubit>()..open(order.id);
  await showAppSheet<void>(
    context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: LotteonInvoiceEditSheet(
        order: order,
        carrierOptions: carrierOptions,
      ),
    ),
  );
  final changed = (cubit.state.result?.succeeded ?? 0) > 0;
  await cubit.close();
  return changed;
}

/// The LotteON 「송장 수정」 sheet (FEATURE_2611_23 / D19 ⑥ · R52).
///
/// **Purpose**: one carrier + one new invoice on top, then every product of
/// the delivery with its LotteON records as checkboxes; [수정] sends the
/// checked records only.
/// **File**:
/// lib/features/order/presentation/widgets/lotteon_invoice_edit_sheet.dart
///
/// **Usage**: open it with [showLotteonInvoiceEditSheet] only.
///
/// ⚠️ Only records in status 13 · 14 · 15 can be checked; all of them are
/// checked on open (D19 ⑥-8 · ⑥-10).
/// ⚠️ A 200 locks the inputs and shows the outcome next to each record; the
/// sheet stays open. To fix again, close and open it again.
/// ⚠️ The record time is cut from the server text — never parsed into a date
/// (R52).
/// ❌ Not for Coupang · 11st orders — Coupang edits inline, 11st has no
/// update.
class LotteonInvoiceEditSheet extends StatelessWidget {
  final OrderItem order;
  final List<CarrierOption> carrierOptions;

  const LotteonInvoiceEditSheet({
    required this.order,
    required this.carrierOptions,
    super.key,
  });

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LotteonInvoiceEditCubit, LotteonInvoiceEditState>(
        builder: (context, state) {
          final cubit = context.read<LotteonInvoiceEditCubit>();
          final colorScheme = Theme.of(context).colorScheme;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      '송장 수정',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('주문 ${order.externalOrderId}'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: carrierOptions.any(
                              (o) => o.deliveryCompanyCode == state.carrierCode)
                          ? state.carrierCode
                          : null,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: '택배사'),
                      items: carrierOptions
                          .map((o) => DropdownMenuItem<String>(
                                value: o.deliveryCompanyCode,
                                child: Text(o.carrierName,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: state.locked
                          ? null
                          : (value) {
                              if (value != null) {
                                cubit.selectCarrier(value);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      maxLength: 50,
                      enabled: !state.locked,
                      onChanged: cubit.setInvoiceNumber,
                      decoration: const InputDecoration(labelText: '새 송장'),
                    ),
                    if (state.loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else if (state.loadError != null)
                      Text(
                        state.loadError!,
                        style: TextStyle(color: colorScheme.error),
                      )
                    else
                      for (final line in state.lines)
                        ..._buildLine(context, state, line),
                    if (state.submitError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.submitError!,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: state.canSubmit
                            ? () => cubit.submit(order.id)
                            : null,
                        child: state.submitting
                            ? const AppBusyLabel('수정')
                            : const Text('수정'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );

  /// One product block — the bold name, then its records (D19 ⑥-1).
  List<Widget> _buildLine(
    BuildContext context,
    LotteonInvoiceEditState state,
    LotteonInvoiceRecords line,
  ) {
    final cubit = context.read<LotteonInvoiceEditCubit>();
    final colorScheme = Theme.of(context).colorScheme;
    return [
      const SizedBox(height: 16),
      Text(
        line.productName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      if (line.records.isEmpty)
        Text(
          '롯데ON 에 발송 기록이 없어 고칠 수 없습니다.',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      for (final record in line.records)
        CheckboxListTile(
          value:
              state.checked.contains('${line.orderItemId}:${record.procSeq}'),
          onChanged: record.pickable && !state.locked
              ? (_) => cubit.toggle(line.orderItemId, record.procSeq)
              : null,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(_recordText(record)),
          subtitle: _outcomeText(context, state, line, record),
        ),
    ];
  }

  /// The outcome next to a sent record (D19 ⑥-7), null before a 200.
  Widget? _outcomeText(
    BuildContext context,
    LotteonInvoiceEditState state,
    LotteonInvoiceRecords line,
    LotteonInvoiceRecord record,
  ) {
    final outcome = state.outcomeOf(line.orderItemId, record.procSeq);
    if (outcome == null) {
      return null;
    }
    final sentInvoice = state.invoiceNumber.trim();
    return Text(
      outcome.succeeded
          ? '✅ $sentInvoice으로 수정됨'
          : '❌ ${outcome.message ?? '-'}',
      style: TextStyle(
        color: outcome.succeeded
            ? AppColors.successForeground
            : Theme.of(context).colorScheme.error,
      ),
    );
  }
}

/// 「{invoice} · {carrier} · {status} · {MM/dd HH:mm}」 (D19 ⑥-2 · R52).
String _recordText(LotteonInvoiceRecord record) {
  final invoice = record.invoiceNumber;
  final invoiceText = invoice == null || invoice.isEmpty ? '송장 없음' : invoice;
  return '$invoiceText · ${record.carrierName ?? '-'} · '
      '${record.statusName} · ${_timeText(record.statusAt)}';
}

/// 'yyyy-MM-ddTHH:mm:ss' → 'MM/dd HH:mm' by cutting the text (R52); '-' when
/// missing.
String _timeText(String? value) {
  if (value == null || value.length < 16) {
    return '-';
  }
  return '${value.substring(5, 7)}/${value.substring(8, 10)} '
      '${value.substring(11, 16)}';
}
