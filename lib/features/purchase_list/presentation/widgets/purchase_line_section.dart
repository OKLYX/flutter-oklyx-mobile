import 'package:flutter/material.dart';

import '../../domain/entities/purchase_line.dart';
import 'purchase_line_tile.dart';

/// 상품 상세의 「채널 칩 + 주문 줄」 묶음.
///
/// **용도**: 그 상품(물품)에 기여한 줄(주문 + 수동)을 보여주고, 채널 칩으로 걸러 본다.
/// 수동 줄에는 [제거] 가 붙는다([onRemoveManualLine]).
/// **위치**: lib/features/purchase_list/presentation/widgets/purchase_line_section.dart
///
/// **사용 예제**:
/// ```dart
/// PurchaseLineSection(
///   lines: item.lines,
///   busy: busy,
///   onRemoveManualLine: (itemId) =>
///       bloc.add(AdjustManualQty(itemId: itemId, manualQty: 0)),
/// )
/// ```
///
/// ⚠️ 채널 칩은 **표시 필터일 뿐** 헤더 숫자에 영향이 없다(PLAN 2609_29 D10).
/// ⚠️ 재조회로 고른 채널이 사라지면 전체로 되돌아간다(빈 목록을 보여주지 않는다).
class PurchaseLineSection extends StatefulWidget {
  final List<PurchaseLine> lines;
  final bool busy;
  final void Function(int itemId) onRemoveManualLine;

  const PurchaseLineSection({
    required this.lines,
    required this.busy,
    required this.onRemoveManualLine,
    super.key,
  });

  @override
  State<PurchaseLineSection> createState() => _PurchaseLineSectionState();
}

class _PurchaseLineSectionState extends State<PurchaseLineSection> {
  /// 선택된 채널 칩. null = 전체(기본).
  /// 수동 칩은 marketplaceAccountId 가 없으므로 [_manualChip] 로 표현한다.
  Object? _selectedChannel;

  static const Object _manualChip = 'MANUAL';

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _channelChips(),
          ..._visibleLines().map(
            (line) => PurchaseLineTile(
              line: line,
              busy: widget.busy,
              onRemove: () => widget.onRemoveManualLine(line.itemId),
            ),
          ),
        ],
      );

  /// 그 그룹 lines 에 실제로 등장하는 채널만 칩으로 낸다(marketplaceAccountId dedupe).
  Widget _channelChips() {
    final seen = <int>{};
    final channels = <MapEntry<Object, String>>[];
    var hasManual = false;
    for (final line in widget.lines) {
      final accountId = line.marketplaceAccountId;
      if (accountId == null) {
        hasManual = true;
        continue;
      }
      if (seen.add(accountId)) {
        channels.add(MapEntry(accountId, channelLabel(line)));
      }
    }
    if (hasManual) {
      channels.add(const MapEntry(_manualChip, '수동'));
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
    final filtered = selected == _manualChip
        ? lines.where((l) => l.marketplaceAccountId == null).toList()
        : lines.where((l) => l.marketplaceAccountId == selected).toList();
    return filtered.isEmpty ? lines : filtered;
  }
}
