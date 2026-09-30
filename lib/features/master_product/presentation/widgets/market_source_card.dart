import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/market_source.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/master_format.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

// Status enum → display text (enum names are never shown to users). Kept
// local on purpose, same as the web — importing the import sheet's map would
// couple two screens.
const Map<String, String> _statusLabel = {
  'DRAFT': '미전송',
  'SUBMITTED': '승인 대기중',
  'SELLING': '판매중',
  'REJECTED': '승인 반려',
  'SUSPENDED': '판매 중지',
};

/// Starting marketplace product summary of the create page in "new master"
/// mode (2609_79 / UX D77) — port of web
/// `master-products/new/components/MarketSourceCard.tsx` (@09208a0).
///
/// **File**: lib/features/master_product/presentation/widgets/market_source_card.dart
///
/// Per-option price and stock are **read only** — the server reads the
/// marketplace again when the listing is attached.
///
/// **Usage**:
/// ```dart
/// MarketSourceCard(market: market)
/// ```
///
/// ❌ Never add price or stock inputs here.
class MarketSourceCard extends StatelessWidget {
  final MarketSource market;

  const MarketSourceCard({required this.market, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = market.preview;
    final label = kPlatformLabel[market.platform] ?? market.platform;
    final muted = TextStyle(fontSize: 14, color: scheme.onSurfaceVariant);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '마켓 상품',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: preview.productName ?? '(이름 없음)',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: ' · $label 상품 ID ${market.platformProductId} · '
                        '${_statusLabel[preview.status] ?? preview.status} · '
                        '옵션 ${preview.options.length}개',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 14),
            ),
            if (preview.reusesExistingListing) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.infoSurface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '이 $label 상품에는 마스터 연결이 끊긴 판매상품이 있습니다. 새로 만들지 않고 그 판매상품을 이 '
                  '마스터에 붙입니다 — 주문·고객문의·정산 기록이 함께 따라옵니다.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.infoForeground,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Web option table → one card per row (R7).
            for (var i = 0; i < preview.options.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preview.options[i].itemName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '판매가: ${koNumber(preview.options[i].salePrice)}',
                        style: muted,
                      ),
                      Text(
                        '재고: ${preview.options[i].stockQuantity ?? '—'}',
                        style: muted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '옵션은 $label 상품 그대로 만들어지고 이름을 바꿀 수 없습니다 — 옵션마다 구성 수량만 입력하세요. '
              '판매가·재고는 $label 값을 그대로 씁니다. 사진은 채우지 않으니 이미지 칸에 직접 올리세요. 저장하면 '
              '마스터를 만든 뒤 이 상품을 판매상품으로 붙입니다.',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
