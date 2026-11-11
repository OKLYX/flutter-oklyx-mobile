import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import '../../domain/entities/stock_daily.dart';
import '../../domain/entities/stock_fill.dart';
import '../bloc/date_move_cubit.dart';
import 'date_edit_history.dart';

/// What the 「날짜 바꾸기」 sheet ended with (FEATURE_2611_21 D9 · D19):
/// [movedOn] = the row moved there · [lotId] + [lotDay] = 「입고로 이동」 ·
/// [fill] = [입고로 채우기] (FEATURE_2611_22 D3 ②).
class DateMoveResult {
  final String? movedOn;
  final int? lotId;
  final String? lotDay;
  final bool fill;

  const DateMoveResult(
      {this.movedOn, this.lotId, this.lotDay, this.fill = false});
}

/// 「날짜 바꾸기」 sheet of 「일별 입출고 내역」 (FEATURE_2611_21 D9 · D17 · D20 ·
/// D21 · D24), shown with `showAppSheet` when a card without a row sheet is
/// tapped (order outbound · return · disposal · adjust − · undecided intake).
///
/// - Open it inside a `BlocProvider` of a new [DateMoveCubit] opened with
///   [date]; it pops a [DateMoveResult] (null = closed or the same day).
/// - Read only: 「주문번호」 (order outbound) · 「상품」 · 「수량」 · 「단가」 ·
///   「금액」, then 「새 날짜」 and the row's day corrections.
/// - An undecided row with a share on a receipt with its photo: 「새 날짜」 is
///   off with [receiptShareDateMessage] (D13).
/// - An outgoing row: with a lot → 「○월 ○일 입고로 이동」, plus
///   [sourceFixedMessage] when that lot has no value to fix · without a lot →
///   [noSourceMessage] (D20), with [입고로 채우기] under it when the row is
///   `fillable` (FEATURE_2611_22 D3 ② · D27).
///
/// ⚠️ Refusals and failures are shown inside the sheet in red.
class DateMoveSheet extends StatelessWidget {
  final String date;
  final StockDailyRow row;

  const DateMoveSheet({required this.date, required this.row, super.key});

  Future<void> _pickDay(BuildContext context, DateMoveCubit cubit) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(cubit.state.movedOn),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    cubit.setMovedOn(DateFormat('yyyy-MM-dd').format(picked));
  }

  static String _amount(double? amount) => amount == null
      ? '미기입'
      : '₩${NumberFormat('#,##0', 'ko_KR').format(amount)}';

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<DateMoveCubit, DateMoveState>(
        listenWhen: (previous, current) => !previous.saved && current.saved,
        listener: (context, state) {
          final movedTo = state.movedTo;
          Navigator.of(context)
              .pop(movedTo == null ? null : DateMoveResult(movedOn: movedTo));
        },
        builder: (context, state) {
          final cubit = context.read<DateMoveCubit>();
          final colorScheme = Theme.of(context).colorScheme;
          final muted = colorScheme.onSurfaceVariant;
          final locked = row.undecidedLeft != null &&
              row.shares.any((s) => s.receiptKind == ReceiptKind.receipt);
          final lotId = row.sourceMovementId;
          final lotDay = row.sourceMovedOn;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '날짜 바꾸기',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          state.busy ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (row.orderNumber != null)
                      Text('주문번호 ${row.orderNumber}'),
                    Text('상품 ${row.productName}'),
                    Text('수량 ${row.quantity}'),
                    Text('단가 ${unitPriceText(row.unitPrices)}'),
                    Text('금액 ${_amount(row.amount)}'),
                    const SizedBox(height: 16),
                    const Text('새 날짜',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: state.busy || locked
                          ? null
                          : () => _pickDay(context, cubit),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(state.movedOn),
                    ),
                    if (locked)
                      Text(
                        receiptShareDateMessage,
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    if (row.quantity < 0) ...[
                      const SizedBox(height: 16),
                      if (lotId != null && lotDay != null) ...[
                        OutlinedButton(
                          onPressed: state.busy
                              ? null
                              : () => Navigator.of(context).pop(
                                    DateMoveResult(
                                        lotId: lotId, lotDay: lotDay),
                                  ),
                          child: Text(goToIntakeLabel(lotDay)),
                        ),
                        if (!row.sourcePriceEditable)
                          Text(
                            sourceFixedMessage,
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                      ] else ...[
                        Text(
                          noSourceMessage,
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                        if (row.fillable)
                          OutlinedButton(
                            onPressed: state.busy
                                ? null
                                : () => Navigator.of(context)
                                    .pop(const DateMoveResult(fill: true)),
                            child: const Text(fillButtonLabel),
                          ),
                      ],
                    ],
                    DateEditHistory(edits: row.dateEdits),
                    if (state.error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(state.error,
                          style: TextStyle(color: colorScheme.error)),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state.busy
                        ? null
                        : () => cubit.save(
                              movementId: row.movementId,
                              date: date,
                            ),
                    child: state.busy
                        ? const AppBusyLabel('저장')
                        : const Text('저장'),
                  ),
                ),
              ),
            ],
          );
        },
      );
}
