import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/sales/presentation/utils/sales_format.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_filter_chip.dart';

/// Sale-date period filter of the 「매출」 tabs (FEATURE_2610_20 / D26) — the web
/// `PeriodFilter`.
///
/// One chip: the three presets (「이번 달」 · 「지난 달」 · 「최근 7일」) and 「기간 고르기…」 (date
/// range picker). [extra] chips (seller · channel · view mode) follow in the
/// same row. Pure controlled — the BLoC owns the values.
///
/// ⚠️ This is the SALE-date axis; 「정산 추정 금액」 does not follow it (its label says
/// so).
class SalesPeriodFilter extends StatelessWidget {
  final String from;
  final String to;
  final bool disabled;
  final void Function(String from, String to) onChanged;
  final List<Widget> extra;

  const SalesPeriodFilter({
    required this.from,
    required this.to,
    required this.disabled,
    required this.onChanged,
    super.key,
    this.extra = const [],
  });

  /// Option value of 「기간 고르기…」.
  static const int _custom = -1;

  @override
  Widget build(BuildContext context) {
    final presetIndex = kSalesPeriodPresets.indexWhere((p) {
      final range = p.range();
      return range.from == from && range.to == to;
    });
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AppFilterChip<int>(
          label: '판매일 ${formatDateRange(from, to)}',
          value: presetIndex == -1 ? _custom : presetIndex,
          options: [
            for (var i = 0; i < kSalesPeriodPresets.length; i++)
              AppFilterOption(i, kSalesPeriodPresets[i].label),
            const AppFilterOption(_custom, '기간 고르기…'),
          ],
          highlighted: presetIndex != 0,
          onSelected: disabled ? null : (choice) => _choose(context, choice),
        ),
        ...extra,
      ],
    );
  }

  Future<void> _choose(BuildContext context, int choice) async {
    if (choice != _custom) {
      final range = kSalesPeriodPresets[choice].range();
      onChanged(range.from, range.to);
      return;
    }
    final now = DateTime.now();
    final start = DateTime.tryParse(from);
    final end = DateTime.tryParse(to);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: start != null &&
              end != null &&
              !start.isAfter(end) &&
              !end.isAfter(now)
          ? DateTimeRange(start: start, end: end)
          : null,
    );
    if (picked != null) {
      onChanged(toDateText(picked.start), toDateText(picked.end));
    }
  }
}
