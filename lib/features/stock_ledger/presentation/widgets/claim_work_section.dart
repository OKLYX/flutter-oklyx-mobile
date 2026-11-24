import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/utils/platform_display.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/name_text.dart';
import '../../../claim/domain/entities/claim.dart';
import '../../../settlement/presentation/utils/settlement_format.dart';
import '../../domain/entities/stock_work.dart';
import '../bloc/claim_work_cubit.dart';
import 'claim_work_card.dart';

/// Date text of a server ISO value, 「-」 when unreadable (R21).
String _dateText(String? iso) {
  final date = DateTime.tryParse(iso ?? '');
  return date == null ? '-' : toDateText(date);
}

/// Body of one claim work tab under the barcode field (FEATURE_2611_34 D16
/// ~ D33 · D42).
///
/// **Purpose**: 「송장 대기」 = the list to pick from (shipped orders or
/// exchanges to send); 「담는 중」 = [다른 송장], the opened claims, the date
/// and the save button.
/// **File**: stock_ledger/presentation/widgets/claim_work_section.dart
/// **Used by**: 「입고 작업」 「반품 재입고」 tab and
/// 「출고 작업」 「교환 발송」 tab, under a `BlocProvider<ClaimWorkCubit>`.
///
/// ```dart
/// if (state.tab == IntakeTab.returnIntake) const ClaimWorkSection()
/// ```
///
/// ⚠️ The barcode field stays on the page — this widget has none (D36).
/// ❌ Do not write the tab texts here — read `ClaimWorkCubit.text`.
class ClaimWorkSection extends StatelessWidget {
  const ClaimWorkSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ClaimWorkCubit>().state;
    final cubit = context.read<ClaimWorkCubit>();
    if (state.phase == ClaimWorkPhase.items) {
      return _items(context, cubit, state);
    }
    if (cubit.kind == ClaimWorkKind.exchangeShip) {
      return _exchangeList(cubit, state);
    }
    return _returnWaiting(cubit, state);
  }

  Widget _returnWaiting(ClaimWorkCubit cubit, ClaimWorkState state) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton(
            onPressed: cubit.toggleNoInvoice,
            child: Text(
              state.noInvoice ? '반품 송장으로 찾기' : '송장 없이 반품 완료',
            ),
          ),
          if (state.noInvoice) ...[
            const SizedBox(height: 8),
            const Text(kNoInvoiceGuide),
            const SizedBox(height: 12),
            const Text(
              '최근 14일 출고 주문',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._orderList(cubit, state),
          ],
        ],
      );

  List<Widget> _orderList(ClaimWorkCubit cubit, ClaimWorkState state) {
    if (state.listLoading) {
      return const [AppLoading()];
    }
    if (state.orders.isEmpty) {
      return const [AppEmpty('최근 14일 동안 출고된 주문이 없습니다.')];
    }
    return [
      for (var i = 0; i < state.orders.length; i++) ...[
        if (i > 0) const AppRowGap(),
        _orderRow(cubit, state, state.orders[i]),
      ],
    ];
  }

  Widget _orderRow(
    ClaimWorkCubit cubit,
    ClaimWorkState state,
    ShippedOrder order,
  ) =>
      AppCard.row(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                Text(_dateText(order.orderedAt)),
                Text(order.externalOrderId),
                if (order.claimPending)
                  const Text(
                    '반품·교환 접수',
                    style: TextStyle(color: AppColors.warningForeground),
                  ),
              ],
            ),
            Text(
              '${salesChannelLabel(order.platform, order.accountAlias)}'
              ' · ${order.sellerName ?? '-'}',
              style: const TextStyle(fontSize: 12),
            ),
            NameText(
              name: order.itemName,
              kind: NameKind.product,
              expandable: true,
            ),
            const SizedBox(height: 4),
            OutlinedButton(
              onPressed: state.busy ? null : () => cubit.pickOrder(order),
              child: const Text('고르기'),
            ),
          ],
        ),
      );

  Widget _exchangeList(ClaimWorkCubit cubit, ClaimWorkState state) {
    final List<Widget> rows;
    if (state.listLoading) {
      rows = const [AppLoading()];
    } else if (state.exchanges.isEmpty) {
      rows = const [AppEmpty('보낼 교환이 없습니다.')];
    } else {
      rows = [
        for (var i = 0; i < state.exchanges.length; i++) ...[
          if (i > 0) const AppRowGap(),
          _exchangeRow(cubit, state.exchanges[i]),
        ],
      ];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '보낼 교환',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }

  Widget _exchangeRow(ClaimWorkCubit cubit, ClaimWork claim) {
    final status = getClaimStatusLabel(parseClaimStatus(claim.claimStatus));
    return AppCard.row(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_dateText(claim.receivedAt)} · ${claim.externalOrderId} · '
            '${salesChannelLabel(claim.platform, claim.accountAlias)}',
            style: const TextStyle(fontSize: 12),
          ),
          NameText(
            name: claim.itemName,
            kind: NameKind.product,
            expandable: true,
          ),
          Text(
            '교환 수량 ${claim.claimQty} · 상태 $status',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          OutlinedButton(
            onPressed: () => cubit.pickExchange(claim),
            child: const Text('고르기'),
          ),
        ],
      ),
    );
  }

  Future<void> _otherInvoice(
    BuildContext context,
    ClaimWorkCubit cubit,
    int count,
  ) async {
    if (count == 0) {
      cubit.reset();
      return;
    }
    final ok = await showAppConfirmDialog(
      context,
      title: '다른 송장',
      message: '담은 $count줄을 버리고 다른 송장을 찍을까요?',
    );
    if (ok) {
      cubit.reset();
    }
  }

  Future<void> _pickDate(
    BuildContext context,
    ClaimWorkCubit cubit,
    String movedOn,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(movedOn) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      cubit.changeMovedOn(toDateText(picked));
    }
  }

  Widget _items(
    BuildContext context,
    ClaimWorkCubit cubit,
    ClaimWorkState state,
  ) {
    final text = cubit.text;
    final count = state.enteredCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton(
          onPressed: () => _otherInvoice(context, cubit, count),
          child: const Text('다른 송장'),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < state.claims.length; i++) ...[
          if (i > 0) const AppRowGap(),
          ClaimWorkCard(
            key: ValueKey(state.claims[i].orderClaimId),
            claim: state.claims[i],
            text: text,
            entered: state.entered,
            onChanged: cubit.changeEntered,
          ),
        ],
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _pickDate(context, cubit, state.movedOn),
          child: InputDecorator(
            decoration: InputDecoration(labelText: text.dateLabel),
            child: Text(state.movedOn),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: count == 0 || state.busy ? null : cubit.save,
            child: state.busy
                ? AppBusyLabel(text.saveLabel)
                : Text(text.saveLabel),
          ),
        ),
      ],
    );
  }
}
