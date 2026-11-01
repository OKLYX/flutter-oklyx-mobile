import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import 'package:flutter_oklyn_mobile/features/stock_ledger/domain/entities/stock_enums.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/stock_daily.dart';
import '../bloc/stock_daily_bloc.dart';
import '../widgets/receipt_assign_sheet.dart';

/// 「일별 입출고 내역」 (`/stock/daily`, FEATURE_2610_19 D119 · D122 · D123 ·
/// D124 · D128 · D130 · D147), shown in the drawer right after 「재고 조회」
/// while the stock link is on (D148 ①).
///
/// - One day (today first): every ledger row moved that day with its count and
///   purchase-price amount (「미기입」 when empty). No selling price (D122).
/// - Undecided intake rows show their owners 「○○ 4」 and 「영수증 미등록 N개
///   남음」; outbound rows show the order seller and 「{seller} 재고 사용」 ·
///   「영수증 미등록 재고 사용」.
/// - 「영수증 미등록 N건」 + [영수증 올리기] opens [ReceiptAssignSheet] for that
///   day (D118 · D121 ⑨).
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
  DateTime _date = DateTime.now();
  List<Seller> _sellers = const [];

  String get _day => DateFormat('yyyy-MM-dd').format(_date);

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
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _date = picked);
    context.read<StockDailyBloc>().add(LoadStockDaily(_day));
  }

  Future<void> _openAssign(List<UnregisteredProduct> products) async {
    final bloc = context.read<StockDailyBloc>();
    final saved = await showAppSheet<bool>(
      context,
      builder: (sheetContext) => ReceiptAssignSheet(
        date: _day,
        products: products,
        sellers: _sellers,
      ),
    );
    if (saved == true && mounted) {
      showSuccessToast(context, '영수증을 배정했습니다.');
      bloc.add(LoadStockDaily(_day));
    }
  }

  @override
  Widget build(BuildContext context) => ScaffoldWithNavBar(
        title: '일별 입출고 내역',
        navBarIndex: 2,
        showAppBarDrawerButton: false,
        body: BlocBuilder<StockDailyBloc, StockDailyState>(
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
            final daily = (state as StockDailyLoaded).daily;
            return AppPageBody(
              children: [
                AppCard(
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_day),
                      ),
                      const Spacer(),
                      if (daily.unregisteredProductCount > 0) ...[
                        Text(
                          '영수증 미등록 ${daily.unregisteredProductCount}건',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.warningForeground,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => _openAssign(daily.unregistered),
                          child: const Text('영수증 올리기'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (daily.rows.isEmpty)
                  const AppEmpty('그날 입출고가 없습니다.')
                else
                  for (final row in daily.rows) _rowCard(context, row),
              ],
            );
          },
        ),
      );

  Widget _rowCard(BuildContext context, StockDailyRow row) {
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
    return AppCard.row(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text('${row.quantity}개 · $amount'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (reason == null) type else '$type · $reason',
              if (seller.isNotEmpty) seller,
              if (row.orderNumber != null) '주문 ${row.orderNumber}',
            ].join(' · '),
            style: TextStyle(fontSize: 12, color: muted),
          ),
          if (row.tags.isNotEmpty)
            Text(
              row.tags.join(' · '),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.warningForeground),
            ),
        ],
      ),
    );
  }
}
