import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_filter_chip.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_search_field.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/packing_history.dart';
import '../bloc/packing_history_bloc.dart';
import '../widgets/box_change_sheet.dart';

/// App 「포장 이력」 screen (`/stock/packing-history`, FEATURE_2611_03 /
/// PLAN D29 ~ D32): read-only rows of packing actions of a period (today ·
/// last 7 days · last 30 days) with an invoice / order number search.
/// **File**: lib/features/packing/presentation/pages/packing_history_page.dart
///
/// ⚠️ The time is the server KST wall clock — printed as is (D40).
/// ❌ No row tap, no edit, no delete on the rows themselves (D32 ·
///    FEATURE_2611_06 / D18) · no date picker (D29). The only action is
///    [상자 변경] at the bottom of a 「포장 완료」 card — it opens the box
///    change sheet for that parcel (FEATURE_2611_06 / D15 · D19).
class PackingHistoryPage extends StatelessWidget {
  const PackingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<PackingHistoryBloc>()
          ..add(LoadPackingHistory(days: 1, keyword: '')),
        child: const _PackingHistoryView(),
      );
}

class _PackingHistoryView extends StatefulWidget {
  const _PackingHistoryView();

  @override
  State<_PackingHistoryView> createState() => _PackingHistoryViewState();
}

class _PackingHistoryViewState extends State<_PackingHistoryView> {
  final TextEditingController _search = TextEditingController();

  static const List<AppFilterOption<int>> _periods = [
    AppFilterOption(1, '오늘'),
    AppFilterOption(7, '최근 7일'),
    AppFilterOption(30, '최근 30일'),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _load(int days) => context
      .read<PackingHistoryBloc>()
      .add(LoadPackingHistory(days: days, keyword: _search.text));

  @override
  Widget build(BuildContext context) => ScaffoldWithNavBar(
        title: '포장 이력',
        navBarIndex: 2,
        showAppBarDrawerButton: false,
        body: BlocBuilder<PackingHistoryBloc, PackingHistoryState>(
          builder: (context, state) {
            final loading = state is PackingHistoryLoading;
            return AppPageBody(
              children: [
                AppSearchField(
                  controller: _search,
                  hintText: '송장번호 또는 주문번호',
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _load(state.days),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppFilterChip<int>(
                    label: _periods
                        .firstWhere(
                          (option) => option.value == state.days,
                          orElse: () => _periods.first,
                        )
                        .label,
                    value: state.days,
                    options: _periods,
                    highlighted: state.days != 1,
                    onSelected: loading ? null : _load,
                  ),
                ),
                const SizedBox(height: 16),
                ..._body(state),
              ],
            );
          },
        ),
      );

  List<Widget> _body(PackingHistoryState state) {
    switch (state) {
      case PackingHistoryLoading():
        return const [AppLoading()];
      case PackingHistoryError(:final message):
        return [
          AppErrorBox(
            message: message,
            action: FilledButton(
              onPressed: () => _load(state.days),
              child: const Text('다시 시도'),
            ),
          ),
        ];
      case PackingHistoryLoaded(:final entries):
        if (entries.isEmpty) {
          return const [AppEmpty('이 기간에 포장 이력이 없습니다.')];
        }
        return [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const AppRowGap(),
            _row(entries[i]),
          ],
        ];
    }
  }

  Widget _row(PackingHistoryEntry entry) => AppCard.row(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field('처리 시각', formatOrderDateTime(entry.changedAt)),
            _field('송장번호', entry.invoiceNumber),
            _field('택배사', entry.carrierName ?? '-'),
            _field('주문번호', entry.externalOrderId),
            _field('판매자', entry.sellerName ?? '-'),
            _field('동작', entry.actionLabel),
            _field('상자', entry.boxName ?? '-'),
            _field('처리자', entry.changedBy ?? '-'),
            if (entry.isPackedRow) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _changeBox(entry),
                child: const Text('상자 변경'),
              ),
            ],
          ],
        ),
      );

  /// The sheet changes the box on the server and closes — reload the same
  /// period and search text, then the toast (FEATURE_2611_06 / D19 · D20).
  Future<void> _changeBox(PackingHistoryEntry entry) async {
    final box = await showBoxChangeSheet(
      context,
      parcelId: entry.parcelId,
      selectedPackageId: entry.boxPackageId,
    );
    if (box == null || !mounted) {
      return;
    }
    _load(context.read<PackingHistoryBloc>().state.days);
    showSuccessToast(context, '상자를 바꿨습니다 — ${box.type}');
  }

  Widget _field(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 72, child: Text(label)),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
