import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/presentation/widgets/product_thumbnail.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import 'package:flutter_oklyn_mobile/features/stock_ledger/domain/entities/stock_enums.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_filter_chip.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/stock_daily.dart';
import '../bloc/date_move_cubit.dart';
import '../bloc/purchase_price_cubit.dart';
import '../bloc/row_edit_cubit.dart';
import '../bloc/stock_daily_bloc.dart';
import '../widgets/date_move_sheet.dart';
import '../widgets/purchase_price_sheet.dart';
import '../widgets/receipt_assign_sheet.dart';
import '../widgets/row_edit_sheet.dart';
import '../widgets/seller_change_sheet.dart';

/// 「일별 입출고 내역」 (`/stock/daily`, FEATURE_2610_19 D119 · D122 · D123 ·
/// D124 · D128 · D130 · D147), shown in the drawer right after 「재고 조회」
/// while the stock link is on (D148 ①).
///
/// - One day (today first): every ledger row moved that day with its count and
///   purchase-price amount (「미기입」 when empty). No selling price (D122).
/// - Undecided intake rows show their owners 「○○」 and 「영수증 미등록 N개
///   남음」; outbound rows show the order seller and 「{seller} 재고 사용」 ·
///   「영수증 미등록 재고 사용」.
/// - 「영수증 미등록 N건」 + [영수증 올리기] opens [ReceiptAssignSheet] for that
///   day (D118 · D121 ⑨); [영수증 없이 판매자 정하기] opens the same sheet
///   without a photo (FEATURE_2611_01 D2 · D4).
/// - One check per card for four buttons (FEATURE_2611_01 D14): an undecided
///   row with a quantity left, a decided incoming row without a receipt, a row
///   with a purchase record to retype and each share (a line under its
///   undecided row). Only undecided rows checked → the receipt buttons open
///   with those products at their remaining quantity · only 「영수증 없음」
///   rows and shares → [판매자 바꾸기] ([SellerChangeSheet], D7 · D15) ·
///   nothing checked → the receipt buttons open with every product of the day
///   at 0.
/// - [매입가 넣기] (FEATURE_2611_16 D7 · D8): on when every checked row and
///   share is a purchase-price target → [PurchasePriceSheet] with those
///   targets in table order (a row, then its checked shares).
/// - FEATURE_2611_17: the chip 「전체」/「입고」/「출고」 and the boxes
///   「판매자 미정 상품」 · 「영수증 미등록 상품」 filter the list on screen
///   (D4 · D11 · D28) · tapping a card or a share line with a sheet target
///   opens [RowEditSheet] (D12 · D24); the check box only checks (D7).
/// - FEATURE_2611_21: a card without a sheet target opens [DateMoveSheet]
///   (D9) · a corrected row shows 「날짜 고침」 (D24) · 「입고로 이동」 sends
///   [GoToStockDailyRow] — the lot's row sheet opens, or the lot is highlighted
///   (D19). The screen day is [StockDailyBloc.day].
class StockDailyPage extends StatelessWidget {
  const StockDailyPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<StockDailyBloc>()
          ..add(
            LoadStockDaily(DateFormat('yyyy-MM-dd').format(DateTime.now())),
          ),
        child: const _StockDailyView(),
      );
}

class _StockDailyView extends StatefulWidget {
  const _StockDailyView();

  @override
  State<_StockDailyView> createState() => _StockDailyViewState();
}

class _StockDailyViewState extends State<_StockDailyView> {
  List<Seller> _sellers = const [];

  String get _day => context.read<StockDailyBloc>().day;

  @override
  void initState() {
    super.initState();
    _loadSellers();
  }

  Future<void> _loadSellers() async {
    final result = await getIt<GetSellersUseCase>()();
    if (!mounted) {
      return;
    }
    result.fold((_) {}, (sellers) => setState(() => _sellers = sellers));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_day),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    context
        .read<StockDailyBloc>()
        .add(LoadStockDaily(DateFormat('yyyy-MM-dd').format(picked)));
  }

  Future<void> _openAssign(
    List<UnregisteredProduct> products, {
    required bool withoutReceipt,
    required bool prefillRemaining,
  }) async {
    final bloc = context.read<StockDailyBloc>();
    final saved = await showAppSheet<bool>(
      context,
      builder: (sheetContext) => ReceiptAssignSheet(
        date: _day,
        products: products,
        sellers: _sellers,
        withoutReceipt: withoutReceipt,
        prefillRemaining: prefillRemaining,
      ),
    );
    if (saved == true && mounted) {
      showSuccessToast(
          context, withoutReceipt ? '판매자를 정했습니다.' : '영수증을 배정했습니다.');
      bloc.add(LoadStockDaily(_day));
    }
  }

  Future<void> _openChange(
    List<int> movementIds,
    List<int> shareRecordIds,
    List<String> labels,
  ) async {
    final bloc = context.read<StockDailyBloc>();
    final saved = await showAppSheet<bool>(
      context,
      builder: (sheetContext) => SellerChangeSheet(
        movementIds: movementIds,
        shareRecordIds: shareRecordIds,
        labels: labels,
        sellers: _sellers,
      ),
    );
    if (saved == true && mounted) {
      showSuccessToast(context, '판매자를 바꿨습니다.');
      bloc.add(LoadStockDaily(_day));
    }
  }

  Future<void> _openPurchasePrice(List<PurchasePriceTarget> targets) async {
    final bloc = context.read<StockDailyBloc>();
    final saved = await showAppSheet<bool>(
      context,
      builder: (sheetContext) => BlocProvider(
        create: (_) => getIt<PurchasePriceCubit>()..open(targets),
        child: PurchasePriceSheet(date: _day, targets: targets),
      ),
    );
    if (saved == true && mounted) {
      showSuccessToast(context, '매입가를 반영했습니다.');
      bloc.add(LoadStockDaily(_day));
    }
  }

  Future<void> _openRowEdit(RowEditTarget target) async {
    final bloc = context.read<StockDailyBloc>();
    final day = _day;
    // FEATURE_2611_21 D9: the sheet pops the day the row moved to ('' = kept).
    final movedTo = await showAppSheet<String>(
      context,
      builder: (sheetContext) => BlocProvider(
        create: (_) => getIt<RowEditCubit>()..open(target, day),
        child: RowEditSheet(date: day, target: target, sellers: _sellers),
      ),
    );
    if (movedTo != null && mounted) {
      showSuccessToast(
          context, movedTo.isEmpty ? '저장했습니다.' : movedMessage(movedTo));
      bloc.add(LoadStockDaily(day));
    }
  }

  /// FEATURE_2611_21 D9 · D19: the 「날짜 바꾸기」 sheet of a card without a row
  /// sheet — a moved day reloads the screen day, 「입고로 이동」 goes to the lot.
  Future<void> _openDateMove(StockDailyRow row) async {
    final bloc = context.read<StockDailyBloc>();
    final day = _day;
    final result = await showAppSheet<DateMoveResult>(
      context,
      builder: (sheetContext) => BlocProvider(
        create: (_) => getIt<DateMoveCubit>()..open(day),
        child: DateMoveSheet(date: day, row: row),
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    final lotId = result.lotId;
    final lotDay = result.lotDay;
    if (lotId != null && lotDay != null) {
      bloc.add(GoToStockDailyRow(lotDay, lotId));
      return;
    }
    final movedOn = result.movedOn;
    if (movedOn != null) {
      showSuccessToast(context, movedMessage(movedOn));
      bloc.add(LoadStockDaily(day));
    }
  }

  @override
  Widget build(BuildContext context) => ScaffoldWithNavBar(
        title: '일별 입출고 내역',
        navBarIndex: 2,
        showAppBarDrawerButton: false,
        body: BlocConsumer<StockDailyBloc, StockDailyState>(
          // FEATURE_2611_21 D19: the lot 「입고로 이동」 arrived at opens its sheet.
          listenWhen: (previous, current) =>
              current is StockDailyLoaded && current.focusId != null,
          listener: (context, state) {
            final loaded = state as StockDailyLoaded;
            for (final row in loaded.daily.rows) {
              final target = row.editTarget;
              if (row.movementId == loaded.focusId && target != null) {
                _openRowEdit(target);
              }
            }
          },
          builder: (context, state) {
            if (state is StockDailyLoading) {
              return const AppPageBody(children: [AppLoading()]);
            }
            if (state is StockDailyError) {
              return AppPageBody(
                children: [
                  AppErrorBox(
                    message: state.message,
                    action: FilledButton(
                      onPressed: () => context
                          .read<StockDailyBloc>()
                          .add(LoadStockDaily(_day)),
                      child: const Text('다시 시도'),
                    ),
                  ),
                ],
              );
            }
            final loaded = state as StockDailyLoaded;
            final daily = loaded.daily;
            final checked = loaded.checked;
            final visible = loaded.visibleRows;
            // D14: the checked rows and shares, split by kind.
            final checkedRows =
                daily.rows.where((row) => checked.contains(_rowKey(row)));
            final checkedShares = [
              for (final row in daily.rows)
                for (final share in row.shares)
                  if (checked.contains(_shareKey(share))) (row, share),
            ];
            final undecidedChecked = checkedRows
                .where((row) => (row.undecidedLeft ?? 0) > 0)
                .toList();
            final changeRowsChecked =
                checkedRows.where((row) => row.sellerChangeable).toList();
            final changeSharesChecked = [
              for (final (row, share) in checkedShares)
                if (share.sellerChangeable) (row, share),
            ];
            final canAssign = checked.isEmpty ||
                undecidedChecked.length == checked.length;
            final canChange = checked.isNotEmpty &&
                changeRowsChecked.length + changeSharesChecked.length ==
                    checked.length;
            // FEATURE_2611_16 D7: every checked row and share is a target.
            final priceTargets = [
              for (final row in daily.rows) ...[
                if (checked.contains(_rowKey(row)) && row.priceTarget != null)
                  row.priceTarget!,
                for (final share in row.shares)
                  if (checked.contains(_shareKey(share)))
                    share.priceTargetOf(row),
              ],
            ];
            final canRetype =
                checked.isNotEmpty && priceTargets.length == checked.length;
            final assignProducts = checked.isEmpty
                ? daily.unregistered
                : daily.unregistered
                    .where((p) => undecidedChecked
                        .any((row) => row.productId == p.productId))
                    .toList();
            final changeLabels = [
              for (final row in changeRowsChecked)
                _changeLabel(row.productName, row.quantity,
                    row.sellerName ?? '판매자 미정'),
              for (final (row, share) in changeSharesChecked)
                _changeLabel(row.productName, share.quantity,
                    '${share.sellerName} (영수증 없음)'),
            ];
            return AppPageBody(
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_day),
                      ),
                      if (daily.unregisteredProductCount > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          '영수증 미등록 ${daily.unregisteredProductCount}건',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.warningForeground,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (daily.unregisteredProductCount > 0) ...[
                            FilledButton(
                              onPressed: canAssign
                                  ? () => _openAssign(
                                        assignProducts,
                                        withoutReceipt: false,
                                        prefillRemaining: checked.isNotEmpty,
                                      )
                                  : null,
                              child: const Text('영수증 올리기'),
                            ),
                            OutlinedButton(
                              onPressed: canAssign
                                  ? () => _openAssign(
                                        assignProducts,
                                        withoutReceipt: true,
                                        prefillRemaining: checked.isNotEmpty,
                                      )
                                  : null,
                              child: const Text('영수증 없이 판매자 정하기'),
                            ),
                          ],
                          OutlinedButton(
                            onPressed: canChange
                                ? () => _openChange(
                                      [
                                        for (final row in changeRowsChecked)
                                          row.movementId,
                                      ],
                                      [
                                        for (final (_, share)
                                            in changeSharesChecked)
                                          share.recordId,
                                      ],
                                      changeLabels,
                                    )
                                : null,
                            child: const Text('판매자 바꾸기'),
                          ),
                          OutlinedButton(
                            onPressed: canRetype
                                ? () => _openPurchasePrice(priceTargets)
                                : null,
                            child: const Text('매입가 넣기'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _filterBar(context, loaded),
                const SizedBox(height: 8),
                if (daily.rows.isEmpty)
                  const AppEmpty('그날 입출고가 없습니다.')
                else if (visible.isEmpty)
                  const AppEmpty(noMatchMessage)
                else
                  for (final item in visible)
                    _rowCard(context, item.row, item.shares, checked,
                        highlighted: loaded.highlightId == item.row.movementId),
              ],
            );
          },
        ),
      );

  static String _rowKey(StockDailyRow row) => 'row-${row.movementId}';

  static String _shareKey(StockDailyShare share) => 'share-${share.recordId}';

  /// One 「판매자 바꾸기」 target as the sheet lists it: 「양말 2개 · A상사」.
  static String _changeLabel(String product, int quantity, String owner) =>
      '$product $quantity개 · $owner';

  /// FEATURE_2611_17 D4 · D24 · D28: the chip and the two boxes.
  Widget _filterBar(BuildContext context, StockDailyLoaded loaded) {
    final bloc = context.read<StockDailyBloc>();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppFilterChip<DailyChip>(
          label: loaded.chip.label,
          value: loaded.chip,
          options: [
            for (final chip in DailyChip.values)
              AppFilterOption(chip, chip.label),
          ],
          highlighted: loaded.chip != DailyChip.all,
          onSelected: (chip) => bloc.add(SelectStockDailyChip(chip)),
        ),
        _box(undecidedBoxLabel, loaded.undecidedBox,
            () => bloc.add(ToggleStockDailyBox(StockDailyBox.undecided))),
        _box(receiptPendingBoxLabel, loaded.receiptBox,
            () => bloc.add(ToggleStockDailyBox(StockDailyBox.receiptPending))),
      ],
    );
  }

  /// One box next to the chip — the text toggles it too.
  static Widget _box(String label, bool value, VoidCallback onToggle) =>
      InkWell(
        onTap: onToggle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(value: value, onChanged: (_) => onToggle()),
            Text(label),
          ],
        ),
      );

  Widget _rowCard(
    BuildContext context,
    StockDailyRow row,
    List<StockDailyShare> shares,
    Set<String> checked, {
    required bool highlighted,
  }) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final type =
        StockMovementType.fromCode(row.movementType)?.label ?? row.movementType;
    final reason = StockReason.fromCode(row.reason)?.label;
    final seller = row.undecidedLeft != null
        ? [
            ...row.owners,
            if (row.undecidedLeft! > 0) '영수증 미등록 ${row.undecidedLeft}개 남음',
          ].join(' · ')
        : (row.sellerName ?? '판매자 미정');
    final amount = row.amount == null
        ? '미기입'
        : '₩${NumberFormat('#,##0', 'ko_KR').format(row.amount)}';
    final checkable = (row.undecidedLeft ?? 0) > 0 ||
        row.sellerChangeable ||
        row.recordId != null;
    final bloc = context.read<StockDailyBloc>();
    final target = row.editTarget;
    // D1 · D2 · D16 · D22: count · unit price · amount (+ 「미기입」).
    final priceLine = '${row.quantity}개 · 단가 ${unitPriceText(row.unitPrices)}'
        ' · $amount${row.priceFromBase ? ' · $priceFromBaseLabel' : ''}';
    return AppCard.row(
      onTap: target == null
          ? () => _openDateMove(row)
          : () => _openRowEdit(target),
      child: ColoredBox(
        // FEATURE_2611_21 D19: the lot 「입고로 이동」 arrived at, without a sheet.
        color: highlighted ? AppColors.warningSurface : Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (checkable)
                  Checkbox(
                    value: checked.contains(_rowKey(row)),
                    onChanged: (_) =>
                        bloc.add(ToggleStockDailyCheck(_rowKey(row))),
                  ),
                ProductThumbnail(productId: row.productId, size: 40),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    row.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(priceLine),
            Text(
              [
                if (reason == null) type else '$type · $reason',
                if (seller.isNotEmpty) seller,
                if (row.orderNumber != null) '주문 ${row.orderNumber}',
                if (row.dateEdits.isNotEmpty) dateEditedLabel,
              ].join(' · '),
              style: TextStyle(fontSize: 12, color: muted),
            ),
            if (row.tags.isNotEmpty)
              Text(
                row.tags.join(' · '),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.warningForeground),
              ),
            // FEATURE_2611_16 D8: every share is its own line and target.
            for (final share in shares)
              Row(
                children: [
                  Checkbox(
                    value: checked.contains(_shareKey(share)),
                    onChanged: (_) =>
                        bloc.add(ToggleStockDailyCheck(_shareKey(share))),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _openRowEdit(share.editTargetOf(row)),
                      child: Text(
                        share.lineText,
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
