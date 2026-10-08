import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import '../../domain/entities/purchase_line.dart';
import '../../domain/entities/purchase_list_item.dart';
import 'product_thumbnail.dart';
import 'purchase_intake_card.dart';
import 'purchase_line_tile.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// 구매목록 상품(물품) 카드 (펼침 가능).
///
/// 접힘: 썸네일 + 상품명 + 브랜드 / 필요 수량 / 매입 완료 수량(한 줄에 하나)
/// + 오른쪽 아래 강조된 매입 필요 수량.
/// 🔴 세 숫자는 **전체 기준**이다 — 판매자로 쪼개지 않는다(PLAN 2609_29 D6).
///
/// 펼침([expanded]) 내용물은 **구매목록 탭과 완료 탭이 동일하다**(D21):
/// ① 입고 카드(`PurchaseIntakeCard`) ② 최근 구매이력(카드 안) ③ 채널 칩 + 주문 줄.
/// ❌ 완료탭용 카드를 복제하지 말 것 — 두 탭의 차이는 그룹 필터와 기간 필터뿐이다.
///
/// 채널 칩은 **표시 필터일 뿐** 헤더 숫자에 영향이 없다(D10).
class PurchaseProductCard extends StatefulWidget {
  final PurchaseListItem item;
  final bool expanded;
  final bool busy;

  /// 입고 카드 판매자 드롭다운용 목록(툴바 필터가 아니다, D11).
  final List<Seller> sellers;
  final VoidCallback onToggle;

  /// 입고 제출 — productId 는 이 카드의 물품이다.
  final void Function({
    required int productId,
    required int sellerId,
    required String purchasedOn,
    required int quantity,
    double? totalAmount,
    double? unitPrice,
    required bool reflectToBasePrice,
  }) onRecordPurchase;

  /// Removes a manual line of this product (manualQty → 0).
  final void Function(int itemId) onRemoveManualLine;

  const PurchaseProductCard({
    required this.item,
    required this.expanded,
    required this.busy,
    required this.sellers,
    required this.onToggle,
    required this.onRecordPurchase,
    required this.onRemoveManualLine,
    super.key,
  });

  @override
  State<PurchaseProductCard> createState() => _PurchaseProductCardState();
}

class _PurchaseProductCardState extends State<PurchaseProductCard> {
  /// 선택된 채널 칩. null = 전체(기본).
  /// 수동 칩은 marketplaceAccountId 가 없으므로 [_manualChip] 로 표현한다.
  Object? _selectedChannel;

  static const Object _manualChip = 'MANUAL';

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return AppCard.flush(
      child: Column(
        children: [
          InkWell(
            onTap: widget.onToggle,
            child: Padding(
              padding: const EdgeInsets.all(12),
              // IntrinsicHeight + stretch lets the right column span the row so
              // the emphasised remaining quantity sits at the bottom-right.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Align keeps the fixed-size thumbnail from being
                    // stretched to the row height.
                    Align(
                      alignment: Alignment.topCenter,
                      child: ProductThumbnail(
                        productId: item.productId,
                        size: 104,
                        zoomable: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // One metric per line: full-word labels read
                          // unambiguously on a narrow screen.
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _labelLine(
                                '브랜드',
                                (item.brand?.trim().isNotEmpty ?? false)
                                    ? item.brand!.trim()
                                    : '-',
                                Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              _metric(
                                '필요 수량',
                                item.neededQty,
                                Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              _metric(
                                '매입 완료 수량',
                                item.purchasedQty,
                                Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(widget.expanded
                            ? Icons.expand_less
                            : Icons.expand_more),
                        _remaining(context, item.remainingQty),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PurchaseIntakeCard(
                    productId: item.productId,
                    sellers: widget.sellers,
                    busy: widget.busy,
                    onSubmit: ({
                      required int sellerId,
                      required String purchasedOn,
                      required int quantity,
                      double? totalAmount,
                      double? unitPrice,
                      required bool reflectToBasePrice,
                    }) =>
                        widget.onRecordPurchase(
                      productId: item.productId,
                      sellerId: sellerId,
                      purchasedOn: purchasedOn,
                      quantity: quantity,
                      totalAmount: totalAmount,
                      unitPrice: unitPrice,
                      reflectToBasePrice: reflectToBasePrice,
                    ),
                  ),
                  _channelChips(),
                  ..._visibleLines().map((line) => PurchaseLineTile(
                        line: line,
                        busy: widget.busy,
                        onRemove: () => widget.onRemoveManualLine(line.itemId),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 그 그룹 lines 에 실제로 등장하는 채널만 칩으로 낸다(marketplaceAccountId dedupe).
  Widget _channelChips() {
    final lines = widget.item.lines;
    final seen = <int>{};
    final channels = <MapEntry<Object, String>>[];
    var hasManual = false;
    for (final line in lines) {
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
    if (channels.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      children: [
        _chip(null, '전체'),
        ...channels.map((e) => _chip(e.key, e.value)),
      ],
    );
  }

  Widget _chip(Object? value, String label) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _selectedChannel == value,
      visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
      onSelected: (_) => setState(() => _selectedChannel = value),
    );
  }

  List<PurchaseLine> _visibleLines() {
    final lines = widget.item.lines;
    final selected = _selectedChannel;
    if (selected == null) return lines;
    final filtered = selected == _manualChip
        ? lines.where((l) => l.marketplaceAccountId == null).toList()
        : lines.where((l) => l.marketplaceAccountId == selected).toList();
    // 재조회로 그 채널이 사라졌으면 전체로 되돌아간다(빈 목록을 보여주지 않는다).
    return filtered.isEmpty ? lines : filtered;
  }

  /// The number the user acts on — emphasised at the card's bottom-right.
  /// Amber while something is left to buy, green once covered.
  Widget _remaining(BuildContext context, int value) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '매입 필요 수량',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.bold,
              color: value > 0
                  ? AppColors.warningForeground
                  : AppColors.successForeground,
            ),
          ),
        ],
      );

  Widget _metric(String label, int value, Color? color) =>
      _labelLine(label, '$value', color);

  Widget _labelLine(String label, String value, Color? color) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '$label : $value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}
