import 'package:flutter/material.dart';

/// 「출고 전 주문 제외」 switch (FEATURE_2611_04 / D10 · D11 · D12) — the last item
/// of the sales period row (`SalesPeriodFilter.extra`) on the three 「매출」
/// screens. Off = today's numbers; on = orders not yet shipped are left out.
class ShippedOnlySwitch extends StatelessWidget {
  final bool value;

  /// True while the screen is loading — the switch cannot be tapped.
  final bool disabled;
  final ValueChanged<bool> onChanged;

  const ShippedOnlySwitch({
    required this.value,
    required this.disabled,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('출고 전 주문 제외', style: TextStyle(fontSize: 13)),
          Switch(value: value, onChanged: disabled ? null : onChanged),
        ],
      );
}
