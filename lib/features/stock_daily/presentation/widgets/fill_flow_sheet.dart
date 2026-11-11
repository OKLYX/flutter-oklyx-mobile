import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import '../../domain/entities/stock_daily.dart';
import '../../domain/entities/stock_fill.dart';
import '../bloc/fill_flow_cubit.dart';

/// Shows the 「채울까요?」 sheets of one intake save (FEATURE_2611_22 D3 ① ·
/// D31 · D39) — call it after the save succeeded, with the stock rows the save
/// wrote. No product with an order outbound row to fill = no sheet; a failed
/// load = an error toast.
///
/// **File**: lib/features/stock_daily/presentation/widgets/fill_flow_sheet.dart
///
/// **Usage**:
/// ```dart
/// final lotId = result.lotId;
/// if (lotId != null) showFillFlow(context, [lotId]);
/// ```
///
/// ⚠️ The intake is saved before any sheet shows (D39) — never call it before.
Future<void> showFillFlow(BuildContext context, List<int> lotIds) async {
  if (lotIds.isEmpty) {
    return;
  }
  final cubit = getIt<FillFlowCubit>();
  await cubit.load(lotIds);
  if (!context.mounted) {
    await cubit.close();
    return;
  }
  if (cubit.state.loadError.isNotEmpty) {
    showErrorToast(context, cubit.state.loadError);
  } else if (cubit.state.windows.isNotEmpty) {
    await showAppSheet<void>(
      context,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const FillFlowSheet()),
    );
  }
  await cubit.close();
}

/// 「채울까요?」 sheet (FEATURE_2611_22 D19 · D23 · D27 · D30 · D32 · D39), shown
/// by [showFillFlow] — one product at a time.
///
/// - Title = the product; head = [fillWindowHead]; one part per saved lot
///   ([fillLotLabel]), each row with a check, 「주문번호」 · 「출고 날짜」 ·
///   「판매자」 · 「빈 개수」 and 「채울 개수」.
/// - [채우기] saves the shown product; [건너뛰기] shows the next product; ✕
///   closes every sheet left (D39).
///
/// ⚠️ Refusals and failures are shown inside the sheet in red.
class FillFlowSheet extends StatelessWidget {
  const FillFlowSheet({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<FillFlowCubit, FillFlowState>(
        listenWhen: (previous, current) => !previous.done && current.done,
        listener: (context, state) => Navigator.of(context).pop(),
        builder: (context, state) {
          final cubit = context.read<FillFlowCubit>();
          final window = state.current;
          if (window == null) {
            return const SizedBox.shrink();
          }
          final colorScheme = Theme.of(context).colorScheme;
          final muted = colorScheme.onSurfaceVariant;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        window.productName,
                        style: const TextStyle(
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
                    Text(fillWindowHead(window.rowCount, window.emptyQuantity)),
                    for (final lot in window.lots) ...[
                      const SizedBox(height: 16),
                      Text(
                        fillLotLabel(lot.movedOn, lot.sellerName, lot.quantity),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      for (final row in lot.rows)
                        _FillRowTile(
                          lotId: lot.lotId,
                          row: row,
                          draft: state
                              .drafts[fillDraftKey(lot.lotId, row.movementId)],
                          busy: state.busy,
                          muted: muted,
                          windowIndex: state.index,
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
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.busy ? null : cubit.skip,
                        child: const Text('건너뛰기'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: state.busy ? null : cubit.submit,
                        child: state.busy
                            ? const AppBusyLabel('채우기')
                            : const Text('채우기'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
}

/// One row of a lot's part: check · 「주문번호」 · 「출고 날짜」 · 「판매자」 ·
/// 「빈 개수」 · 「채울 개수」.
class _FillRowTile extends StatelessWidget {
  final int lotId;
  final FillRow row;
  final FillDraft? draft;
  final bool busy;
  final Color muted;
  final int windowIndex;

  const _FillRowTile({
    required this.lotId,
    required this.row,
    required this.draft,
    required this.busy,
    required this.muted,
    required this.windowIndex,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FillFlowCubit>();
    final checked = draft?.checked ?? false;
    return Row(
      children: [
        Checkbox(
          value: checked,
          onChanged: busy
              ? null
              : (value) => cubit.toggle(lotId, row, checked: value ?? false),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('주문번호 ${row.orderNumber}'),
              Text(
                '출고 날짜 ${monthDayText(row.movedOn)} · 판매자 ${row.sellerName}'
                ' · 빈 개수 ${row.emptyQuantity}',
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 72,
          child: TextFormField(
            // A new field when the sheet or the check changes, so it starts at
            // the count the cubit set.
            key: ValueKey('$windowIndex:$lotId:${row.movementId}:$checked'),
            initialValue: draft?.quantity ?? '',
            enabled: !busy && checked,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.right,
            decoration: const InputDecoration(labelText: '채울 개수'),
            onChanged: (value) =>
                cubit.setQuantity(lotId, row.movementId, value),
          ),
        ),
      ],
    );
  }
}
