import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import '../../domain/entities/purchase_line.dart';
import 'purchase_line_tile.dart';
import 'purchase_share_actions.dart';

/// The 「채널 칩 + 주문 줄」 block of the product detail.
///
/// **Purpose**: shows the lines (order + manual) of a product and filters them
/// by channel chip. A manual line takes quantity · [판매자 바꾸기] · [제거]
/// (FEATURE_2610_09 D23 · D24 · D77).
/// **File**: lib/features/purchase_list/presentation/widgets/purchase_line_section.dart
///
/// **Usage**:
/// ```dart
/// PurchaseLineSection(
///   lines: item.lines,
///   sellers: state.sellers,
///   busy: busy,
///   onSaveManualQty: (itemId, qty) =>
///       bloc.add(AdjustManualQty(itemId: itemId, manualQty: qty)),
///   onChangeManualSeller: (itemId, sellerId) =>
///       bloc.add(ChangeManualSeller(itemId: itemId, sellerId: sellerId)),
///   onRemoveManualLine: (itemId) => bloc.add(DeleteManualLine(itemId: itemId)),
/// )
/// ```
///
/// ⚠️ Channel chips filter the lines only — the header numbers do not change
/// (PLAN 2609_29 D10).
/// ⚠️ When a reload drops the chosen channel, the chips fall back to 「전체」
/// (never an empty list).
/// ⚠️ One seller only (D53): [판매자 바꾸기] is not shown.
class PurchaseLineSection extends StatefulWidget {
  final List<PurchaseLine> lines;
  final List<Seller> sellers;
  final bool busy;
  final void Function(int itemId, int manualQty) onSaveManualQty;
  final void Function(int itemId, int sellerId) onChangeManualSeller;
  final void Function(int itemId) onRemoveManualLine;

  const PurchaseLineSection({
    required this.lines,
    required this.sellers,
    required this.busy,
    required this.onSaveManualQty,
    required this.onChangeManualSeller,
    required this.onRemoveManualLine,
    super.key,
  });

  @override
  State<PurchaseLineSection> createState() => _PurchaseLineSectionState();
}

class _PurchaseLineSectionState extends State<PurchaseLineSection> {
  /// Chosen channel chip. null = 「전체」 (default). An order line's chip is its
  /// account id; a manual line's chip is `MANUAL-{sellerId}` (D17).
  Object? _selectedChannel;

  static Object _chipKey(PurchaseLine line) =>
      line.marketplaceAccountId ?? 'MANUAL-${line.sellerId}';

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _channelChips(),
          ..._visibleLines().map(
            (line) => PurchaseLineTile(
              key: ValueKey('${line.itemId}-${line.manualQty}'),
              line: line,
              busy: widget.busy,
              onSaveQty: (qty) => widget.onSaveManualQty(line.itemId, qty),
              onChangeSeller:
                  widget.sellers.length == 1 ? null : () => _changeSeller(line),
              onRemove: () => widget.onRemoveManualLine(line.itemId),
            ),
          ),
        ],
      );

  Future<void> _changeSeller(PurchaseLine line) async {
    final sellerId = await pickSellerSheet(
      context,
      widget.sellers,
      exceptId: line.sellerId,
    );
    if (sellerId != null) {
      widget.onChangeManualSeller(line.itemId, sellerId);
    }
  }

  /// Chips = the channels that actually appear in the lines; manual lines get
  /// one chip per seller (D17).
  Widget _channelChips() {
    final seen = <Object>{};
    final channels = <MapEntry<Object, String>>[];
    for (final line in widget.lines) {
      final key = _chipKey(line);
      if (seen.add(key)) {
        channels.add(MapEntry(key, channelLabel(line)));
      }
    }
    if (channels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      children: [
        _chip(null, '전체'),
        ...channels.map((e) => _chip(e.key, e.value)),
      ],
    );
  }

  Widget _chip(Object? value, String label) => ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: _selectedChannel == value,
        visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
        onSelected: (_) => setState(() => _selectedChannel = value),
      );

  List<PurchaseLine> _visibleLines() {
    final lines = widget.lines;
    final selected = _selectedChannel;
    if (selected == null) {
      return lines;
    }
    final filtered = lines.where((l) => _chipKey(l) == selected).toList();
    return filtered.isEmpty ? lines : filtered;
  }
}
