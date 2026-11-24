import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/features/stock_daily/presentation/widgets/fill_flow_sheet.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/stock_enums.dart';
import '../../domain/entities/stock_work.dart';
import '../bloc/claim_work_cubit.dart';
import '../bloc/outbound_work_cubit.dart';
import '../bloc/stock_intake_cubit.dart';
import '../widgets/claim_work_section.dart';
import '../widgets/intake_line_tile.dart';
import '../widgets/stock_product_picker_dialog.dart';

/// App 「입고 작업」 screen (`/stock/intake`, FEATURE_2611_33 D2 ~ D8).
///
/// - One barcode input field, no camera (D7): sent, cleared and focused
///   again after every scan.
/// - Scanned products collect into lines; [입고 저장] saves all at once.
/// - The server decides — found or not, and every save rule (D5 · D16).
/// - Tabs 「입고」 · 「반품 재입고」 keep their own lines; the one barcode
///   field goes to the current tab (FEATURE_2611_34 D1 · D2 · D36).
class StockIntakePage extends StatelessWidget {
  const StockIntakePage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<StockIntakeCubit>()..start()),
          BlocProvider(
            create: (_) =>
                getIt<ClaimWorkCubit>(param1: ClaimWorkKind.returnIntake),
          ),
        ],
        child: const _StockIntakeView(),
      );
}

class _StockIntakeView extends StatefulWidget {
  const _StockIntakeView();

  @override
  State<_StockIntakeView> createState() => _StockIntakeViewState();
}

class _StockIntakeViewState extends State<_StockIntakeView> {
  final TextEditingController _barcode = TextEditingController();
  final TextEditingController _editName = TextEditingController();
  final TextEditingController _editPrice = TextEditingController();
  final TextEditingController _newName = TextEditingController();
  final TextEditingController _newPrice = TextEditingController();
  final FocusNode _barcodeFocus = FocusNode();

  @override
  void dispose() {
    _barcode.dispose();
    _editName.dispose();
    _editPrice.dispose();
    _newName.dispose();
    _newPrice.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }

  void _submitBarcode(String value) {
    switch (context.read<StockIntakeCubit>().state.tab) {
      case IntakeTab.intake:
        context.read<StockIntakeCubit>().lookup(value);
      case IntakeTab.returnIntake:
        context.read<ClaimWorkCubit>().scan(value);
    }
    _barcode.clear();
    // The default done action drops the focus — keep scanning (D7).
    _barcodeFocus.requestFocus();
  }

  Future<void> _pickDate(StockIntakeState state) async {
    final cubit = context.read<StockIntakeCubit>();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(state.movedOn) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && mounted) {
      cubit.changeMovedOn(toDateText(picked));
    }
  }

  Future<void> _pickProduct() async {
    final cubit = context.read<StockIntakeCubit>();
    final product = await showDialog<Product>(
      context: context,
      builder: (_) => const StockProductPickerDialog(),
    );
    if (product != null && mounted) {
      cubit.pickProduct(product);
      _editName.text = product.productName;
    }
  }

  Future<void> _saveOnPicked() async {
    final ok = await context.read<StockIntakeCubit>().saveBarcodeOnPicked(
          productName: _editName.text,
          priceText: _editPrice.text,
        );
    if (ok && mounted) {
      _barcodeFocus.requestFocus();
    }
  }

  Future<void> _createNew() async {
    final ok = await context.read<StockIntakeCubit>().createWithBarcode(
          productName: _newName.text,
          priceText: _newPrice.text,
        );
    if (ok && mounted) {
      _barcodeFocus.requestFocus();
    }
  }

  void _showNotice(BuildContext context, StockIntakeNotice notice) {
    switch (notice.kind) {
      case StockIntakeNoticeKind.success:
        showSuccessToast(context, notice.message);
      case StockIntakeNoticeKind.error:
        showErrorToast(context, notice.message);
      case StockIntakeNoticeKind.input:
        showInputNoticeToast(context, notice.message);
    }
    if (notice.lotIds.isNotEmpty) {
      showFillFlow(context, notice.lotIds);
    }
  }

  void _showWorkNotice(BuildContext context, StockWorkNotice notice) {
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
        title: '입고 작업',
        navBarIndex: 2,
        showAppBarDrawerButton: false,
        body: MultiBlocListener(
          listeners: [
            BlocListener<StockIntakeCubit, StockIntakeState>(
              // Every unknown barcode, the same value too, clears the box
              // (R16).
              listenWhen: (p, c) => p.unknownScan != c.unknownScan,
              listener: (_, __) {
                _editName.clear();
                _editPrice.clear();
                _newName.clear();
                _newPrice.clear();
              },
            ),
            BlocListener<ClaimWorkCubit, ClaimWorkState>(
              listenWhen: (p, c) => p.notice != c.notice,
              listener: (context, state) {
                final notice = state.notice;
                if (notice != null) {
                  _showWorkNotice(context, notice);
                }
              },
            ),
          ],
          child: BlocConsumer<StockIntakeCubit, StockIntakeState>(
            listenWhen: (p, c) => p.notice != c.notice,
            listener: (context, state) {
              final notice = state.notice;
              if (notice != null) {
                _showNotice(context, notice);
              }
            },
            builder: (context, state) {
              final cubit = context.read<StockIntakeCubit>();
              final claimWork = context.watch<ClaimWorkCubit>();
              final intake = state.tab == IntakeTab.intake;
              return AppPageBody.scroll(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tabs(cubit, state),
                    const SizedBox(height: 12),
                    _barcodeField(state, claimWork),
                    const SizedBox(height: 12),
                    if (!intake) const ClaimWorkSection(),
                    if (intake) ...[
                      _movedOnField(state),
                      const SizedBox(height: 12),
                      _sellerField(cubit, state),
                      const SizedBox(height: 12),
                      _reasonField(cubit, state),
                      const SizedBox(height: 12),
                      if (state.unknownBarcode != null) ...[
                        _unknownBox(state),
                        const SizedBox(height: 12),
                      ],
                      ..._lineList(cubit, state),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: state.busy || state.lines.isEmpty
                              ? null
                              : cubit.save,
                          child: state.busy
                              ? const AppBusyLabel('입고 저장')
                              : const Text('입고 저장'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      );

  Widget _tabs(StockIntakeCubit cubit, StockIntakeState state) => SizedBox(
        width: double.infinity,
        child: SegmentedButton<IntakeTab>(
          segments: const [
            ButtonSegment(value: IntakeTab.intake, label: Text('입고')),
            ButtonSegment(
              value: IntakeTab.returnIntake,
              label: Text('반품 재입고'),
            ),
          ],
          selected: {state.tab},
          showSelectedIcon: false,
          onSelectionChanged: (set) => cubit.changeTab(set.first),
        ),
      );

  Widget _barcodeField(StockIntakeState state, ClaimWorkCubit claimWork) {
    final intake = state.tab == IntakeTab.intake;
    return TextField(
      controller: _barcode,
      focusNode: _barcodeFocus,
      autofocus: true,
      // Not `enabled: false` — that drops the focus for good.
      readOnly: intake ? state.busy : claimWork.state.busy,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: intake ? '상품 바코드를 스캔하거나 입력하세요' : claimWork.hint,
      ),
      onSubmitted: _submitBarcode,
    );
  }

  Widget _movedOnField(StockIntakeState state) => InkWell(
        onTap: () => _pickDate(state),
        child: InputDecorator(
          decoration: const InputDecoration(labelText: '입고일'),
          child: Text(state.movedOn),
        ),
      );

  Widget _sellerField(StockIntakeCubit cubit, StockIntakeState state) {
    final soleSeller = state.soleSeller;
    if (soleSeller != null) {
      return InputDecorator(
        decoration: const InputDecoration(labelText: '판매자'),
        child: Text(soleSeller.sellerName),
      );
    }
    return DropdownButtonFormField<int?>(
      initialValue: state.screenSellerId,
      isExpanded: true,
      decoration: const InputDecoration(labelText: '판매자'),
      items: [
        DropdownMenuItem<int?>(
          enabled: state.screenReason != StockReason.opening,
          child: const Text(
            kUndecidedSellerLabel,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        for (final s in state.sellers)
          DropdownMenuItem<int?>(
            value: s.id,
            child: Text(s.sellerName, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) =>
          cubit.changeScreen(sellerId: v, reason: state.screenReason),
    );
  }

  Widget _reasonField(StockIntakeCubit cubit, StockIntakeState state) {
    final hasSeller = (state.soleSeller?.id ?? state.screenSellerId) != null;
    return DropdownButtonFormField<StockReason>(
      initialValue: state.screenReason,
      isExpanded: true,
      decoration: const InputDecoration(labelText: '사유'),
      items: [
        DropdownMenuItem(
          value: StockReason.purchase,
          child: Text(
            StockReason.purchase.label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: StockReason.opening,
          enabled: hasSeller,
          child: Text(
            hasSeller ? StockReason.opening.label : kOpeningNeedsSellerLabel,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      onChanged: (v) {
        if (v != null) {
          cubit.changeScreen(sellerId: state.screenSellerId, reason: v);
        }
      },
    );
  }

  Widget _unknownBox(StockIntakeState state) {
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '등록 안 된 바코드: ${state.unknownBarcode}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.warningForeground,
            ),
          ),
          const SizedBox(height: 8),
          const Text('있는 상품에 이 바코드 넣기'),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickProduct,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: '상품'),
              child: Text(state.picked?.productName ?? '검색 선택'),
            ),
          ),
          if (state.picked != null) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _editName,
              decoration: const InputDecoration(labelText: '상품 이름'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _editPrice,
              keyboardType: TextInputType.number,
              inputFormatters: digits,
              decoration: const InputDecoration(
                labelText: '등록가 (비우면 그대로)',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: state.busy ? null : _saveOnPicked,
              child: const Text('이 상품에 바코드 저장'),
            ),
          ],
          const Divider(height: 24),
          TextField(
            controller: _newName,
            decoration: const InputDecoration(labelText: '새 상품 이름'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _newPrice,
            keyboardType: TextInputType.number,
            inputFormatters: digits,
            decoration: const InputDecoration(labelText: '등록가'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: state.busy ? null : _createNew,
            child: const Text('새 상품으로 등록'),
          ),
        ],
      ),
    );
  }

  List<Widget> _lineList(StockIntakeCubit cubit, StockIntakeState state) {
    if (state.lines.isEmpty) {
      return const [AppEmpty('바코드를 스캔하면 여기에 담깁니다.')];
    }
    return [
      for (var i = 0; i < state.lines.length; i++) ...[
        if (i > 0) const AppRowGap(),
        _lineTile(cubit, state, state.lines[i]),
      ],
    ];
  }

  Widget _lineTile(
    StockIntakeCubit cubit,
    StockIntakeState state,
    IntakeLine line,
  ) =>
      IntakeLineTile(
        key: ValueKey(line.key),
        line: line,
        sellers: state.sellers,
        soleSeller: state.soleSeller,
        onSellerChanged: (v) => cubit.changeLineSeller(line.key, v),
        onReasonChanged: (r) => cubit.changeLineReason(line.key, r),
        onQuantityChanged: (t) => cubit.changeLineQuantity(line.key, t),
        onRemove: () => cubit.removeLine(line.key),
      );
}
