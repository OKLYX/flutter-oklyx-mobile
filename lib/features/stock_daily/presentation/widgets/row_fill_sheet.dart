import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import '../../domain/entities/stock_daily.dart';
import '../../domain/entities/stock_fill.dart';
import '../bloc/row_fill_cubit.dart';

/// [입고로 채우기] sheet of 「일별 입출고 내역」 (FEATURE_2611_22 D3 ② · D15 ·
/// D27), shown with `showAppSheet` from the 「날짜 바꾸기」 sheet of an order
/// outbound row without a lot.
///
/// - Open it inside a `BlocProvider` of a new [RowFillCubit] opened with the
///   row; it pops `true` after a save.
/// - Read only: 「주문번호」 · 「상품」 · 「빈 개수」. 「입고」 = the lots with a piece left
///   ([fillLotLabel]), none → [noFillLotMessage]; 「개수」 = the pieces to fill.
///
/// ⚠️ Refusals and failures are shown inside the sheet in red.
class RowFillSheet extends StatelessWidget {
  final StockDailyRow row;

  const RowFillSheet({required this.row, super.key});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<RowFillCubit, RowFillState>(
        listenWhen: (previous, current) => !previous.saved && current.saved,
        listener: (context, state) => Navigator.of(context).pop(true),
        builder: (context, state) {
          final cubit = context.read<RowFillCubit>();
          final colorScheme = Theme.of(context).colorScheme;
          final muted = colorScheme.onSurfaceVariant;
          final lots = state.lots;
          final hasLots = lots != null && lots.isNotEmpty;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        fillButtonLabel,
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
                    Text('주문번호 ${row.orderNumber ?? '-'}'),
                    Text('상품 ${row.productName}'),
                    Text('빈 개수 ${-row.quantity}'),
                    const SizedBox(height: 16),
                    if (lots == null)
                      const AppLoading()
                    else if (lots.isEmpty && state.error.isEmpty)
                      Text(noFillLotMessage,
                          style: TextStyle(fontSize: 12, color: muted))
                    else if (hasLots) ...[
                      DropdownButtonFormField<int>(
                        initialValue: state.lotId,
                        decoration: const InputDecoration(labelText: '입고'),
                        items: [
                          for (final lot in lots)
                            DropdownMenuItem(
                              value: lot.lotId,
                              child: Text(fillLotLabel(
                                  lot.movedOn, lot.sellerName, lot.quantity)),
                            ),
                        ],
                        onChanged: state.busy
                            ? null
                            : (value) {
                                if (value != null) {
                                  cubit.pick(row, value);
                                }
                              },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        // A new field on every lot pick, so it starts at the
                        // count the cubit set.
                        key: ValueKey('quantity:${state.lotId}'),
                        initialValue: state.quantity,
                        enabled: !state.busy,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(labelText: '개수'),
                        onChanged: cubit.setQuantity,
                      ),
                    ],
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
                    onPressed:
                        state.busy || !hasLots ? null : () => cubit.save(row),
                    child: state.busy
                        ? const AppBusyLabel('채우기')
                        : const Text('채우기'),
                  ),
                ),
              ),
            ],
          );
        },
      );
}
