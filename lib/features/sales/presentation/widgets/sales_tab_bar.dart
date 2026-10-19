import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';

/// The three 「매출」 tabs (FEATURE_2610_20 / D26) — the web `SalesTabs`. A tab = a
/// route, so each tab opens with its own period.
///
/// ⚠️ 「정산 내역」 is not a tab here — it is a separate menu item (different axis).
class SalesTabBar extends StatelessWidget {
  /// 0 = 「통합 매출 조회」 · 1 = 「채널별 매출」 · 2 = 「상품별 매출」.
  final int current;

  const SalesTabBar({required this.current, super.key});

  static const List<({String label, String route})> _tabs = [
    (label: '통합 매출 조회', route: Routes.salesSummary),
    (label: '채널별 매출', route: Routes.salesByChannel),
    (label: '상품별 매출', route: Routes.salesByProduct),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant))),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Expanded(
              child: InkWell(
                onTap:
                    i == current ? null : () => context.goNamed(_tabs[i].route),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: i == current
                              ? scheme.primary
                              : Colors.transparent,
                          width: 2),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _tabs[i].label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: i == current
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
