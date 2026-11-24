import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import '../../../settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/stock_enums.dart';
import '../bloc/outbound_work_cubit.dart';
import '../widgets/outbound_work_line_tile.dart';

/// App 「출고 작업」 screen (`/stock/outbound-work`, FEATURE_2611_34 D3 · D4 ·
/// D36).
///
/// - Tabs 「폐기」 · 「매입처 반품」 keep their own values (R12).
/// - One barcode input field, no camera (D36): sent, cleared and focused
///   again after every scan.
/// - [폐기 저장] · [매입처 반품 저장] save the current tab's lines at once.
class StockOutboundWorkPage extends StatelessWidget {
  const StockOutboundWorkPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<OutboundWorkCubit>()..start(),
        child: const _OutboundWorkView(),
      );
}

class _OutboundWorkView extends StatefulWidget {
  const _OutboundWorkView();

  @override
  State<_OutboundWorkView> createState() => _OutboundWorkViewState();
}

class _OutboundWorkViewState extends State<_OutboundWorkView> {
  final TextEditingController _barcode = TextEditingController();
  final FocusNode _barcodeFocus = FocusNode();

  @override
  void dispose() {
    _barcode.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }

  void _submitBarcode(String value) {
    context.read<OutboundWorkCubit>().scan(value);
    _barcode.clear();
    // The default done action drops the focus — keep scanning (D36).
    _barcodeFocus.requestFocus();
  }

  Future<void> _pickDate(OutboundBasket basket) async {
    final cubit = context.read<OutboundWorkCubit>();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(basket.movedOn) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && mounted) {
      cubit.changeMovedOn(toDateText(picked));
    }
  }

  void _showNotice(BuildContext context, StockWorkNotice notice) {
    switch (notice.kind) {
      case StockWorkNoticeKind.success:
        showSuccessToast(context, notice.message);
      case StockWorkNoticeKind.error:
        showErrorToast(context, notice.message);
      case StockWorkNoticeKind.input:
        showInputNoticeToast(context, notice.message);
    }
  }

  @override
  Widget build(BuildContext context) => ScaffoldWithNavBar(
        title: '출고 작업',
        navBarIndex: 2,
        showAppBarDrawerButton: false,
        body: BlocConsumer<OutboundWorkCubit, OutboundWorkState>(
          listenWhen: (p, c) => p.notice != c.notice,
          listener: (context, state) {
            final notice = state.notice;
            if (notice != null) {
              _showNotice(context, notice);
            }
          },
          builder: (context, state) {
            final cubit = context.read<OutboundWorkCubit>();
            final basket = state.basketOf(state.tab);
            final disposal = state.tab == OutboundWorkTab.disposal;
            final saveLabel = disposal ? '폐기 저장' : '매입처 반품 저장';
            return AppPageBody.scroll(
              child: Column(
                // Tab values are drawn again on every tab change.
                key: ValueKey(state.tab),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tabs(cubit, state),
                  const SizedBox(height: 12),
                  _barcodeField(state),
                  const SizedBox(height: 12),
                  _movedOnField(basket, disposal),
                  const SizedBox(height: 12),
                  _sellerField(cubit, state, basket),
                  if (disposal) ...[
                    const SizedBox(height: 12),
                    _reasonField(cubit, basket),
                  ],
                  const SizedBox(height: 12),
                  ..._lineList(cubit, state, basket, disposal),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: state.busy || basket.lines.isEmpty
                          ? null
                          : cubit.save,
                      child: state.busy
                          ? AppBusyLabel(saveLabel)
                          : Text(saveLabel),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

  Widget _tabs(OutboundWorkCubit cubit, OutboundWorkState state) =>
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<OutboundWorkTab>(
          segments: const [
            ButtonSegment(
              value: OutboundWorkTab.disposal,
              label: Text('폐기'),
            ),
            ButtonSegment(
              value: OutboundWorkTab.supplierReturn,
              label: Text('매입처 반품'),
            ),
          ],
          selected: {state.tab},
          showSelectedIcon: false,
          onSelectionChanged: (set) => cubit.changeTab(set.first),
        ),
      );

  Widget _barcodeField(OutboundWorkState state) => TextField(
        controller: _barcode,
        focusNode: _barcodeFocus,
        autofocus: true,
        // Not `enabled: false` — that drops the focus for good.
        readOnly: state.busy,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          hintText: '상품 바코드를 스캔하거나 입력하세요',
        ),
        onSubmitted: _submitBarcode,
      );

  Widget _movedOnField(OutboundBasket basket, bool disposal) => InkWell(
        onTap: () => _pickDate(basket),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: disposal ? '폐기일' : '반품일',
          ),
          child: Text(basket.movedOn),
        ),
      );

  Widget _sellerField(
    OutboundWorkCubit cubit,
    OutboundWorkState state,
    OutboundBasket basket,
  ) {
    final soleSeller = state.soleSeller;
    if (soleSeller != null) {
      return InputDecorator(
        decoration: const InputDecoration(labelText: '판매자'),
        child: Text(soleSeller.sellerName),
      );
    }
    return DropdownButtonFormField<int>(
      initialValue: basket.screenSellerId,
      isExpanded: true,
      hint: const Text('판매자를 고르세요'),
      decoration: const InputDecoration(labelText: '판매자'),
      items: [
        for (final s in state.sellers)
          DropdownMenuItem<int>(
            value: s.id,
            child: Text(s.sellerName, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) =>
          cubit.changeScreen(sellerId: v, reason: basket.screenReason),
    );
  }

  Widget _reasonField(OutboundWorkCubit cubit, OutboundBasket basket) =>
      DropdownButtonFormField<StockReason>(
        initialValue: basket.screenReason,
        isExpanded: true,
        decoration: const InputDecoration(labelText: '사유'),
        items: [
          for (final r in StockReason.outboundWorkDisposalReasons)
            DropdownMenuItem(
              value: r,
              child: Text(r.label, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (v) {
          if (v != null) {
            cubit.changeScreen(sellerId: basket.screenSellerId, reason: v);
          }
        },
      );

  List<Widget> _lineList(
    OutboundWorkCubit cubit,
    OutboundWorkState state,
    OutboundBasket basket,
    bool disposal,
  ) {
    if (basket.lines.isEmpty) {
      return const [AppEmpty('바코드를 스캔하면 여기에 담깁니다.')];
    }
    return [
      for (var i = 0; i < basket.lines.length; i++) ...[
        if (i > 0) const AppRowGap(),
        _lineTile(cubit, state, basket.lines[i], disposal),
      ],
    ];
  }

  Widget _lineTile(
    OutboundWorkCubit cubit,
    OutboundWorkState state,
    OutboundWorkLine line,
    bool disposal,
  ) =>
      OutboundWorkLineTile(
        key: ValueKey(line.key),
        line: line,
        sellers: state.sellers,
        soleSeller: state.soleSeller,
        showReason: disposal,
        onSellerChanged: (v) => cubit.changeLineSeller(line.key, v),
        onReasonChanged: (r) => cubit.changeLineReason(line.key, r),
        onNoteChanged: (t) => cubit.changeLineNote(line.key, t),
        onQuantityChanged: (t) => cubit.changeLineQuantity(line.key, t),
        onRemove: () => cubit.removeLine(line.key),
      );
}
