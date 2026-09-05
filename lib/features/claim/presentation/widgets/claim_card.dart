import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import '../../domain/entities/claim.dart';

/// 클레임 1건 카드 (반품/교환 목록의 행 하나).
///
/// **용도**: 주문번호 + 상태 / 상품명 / 수량 · 사유 / 접수일 을 보여준다.
/// **필수 규칙**: 클레임 목록을 그리는 새 화면은 이 위젯을 쓴다. 화면별로 카드를 다시 만들지 말 것.
/// **파일**: lib/features/claim/presentation/widgets/claim_card.dart
///
/// **사용 예제**:
/// ```dart
/// ListView.separated(
///   itemCount: claims.length,
///   separatorBuilder: (_, __) => const SizedBox(height: 8),
///   itemBuilder: (context, index) => ClaimCard(claim: claims[index]),
/// )
/// ```
///
/// ⚠️ 탭 → 상세 이동은 위젯 내부에 있다(`context.push` + `extra`) — `OrderCard` 와 같은
/// 관용구다. `pushNamed` 나 `context.go` 로 바꾸면 뒤로가기 동선이 카드마다 달라진다.
/// ⚠️ 상태 라벨·날짜 포맷은 위젯이 직접 만들지 않는다 — `getClaimStatusLabel` ·
/// `formatOrderDateTime` 를 쓴다.
/// ⚠️ 플랫폼 원문 상태(`platformStatus`)는 카드에 노출하지 않는다 — 상세 전용이다.
class ClaimCard extends StatelessWidget {
  final Claim claim;

  const ClaimCard({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.claimDetailPath, extra: claim),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      claim.externalOrderId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 주문 라인에 붙지 못한 클레임(D12) — 상품·판매자 정보가 비어 있을 수 있다.
                  if (!claim.linked) ...[
                    const SizedBox(width: 6),
                    _Badge(
                      text: '주문 미연결',
                      color: Colors.grey[600]!,
                      background: Colors.grey[200]!,
                    ),
                  ],
                  const SizedBox(width: 6),
                  _Badge(
                    text: getClaimStatusLabel(claim.status),
                    color: Colors.blue[800]!,
                    background: Colors.blue[50]!,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                claim.itemName ?? '-',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    '수량 ${claim.quantity}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  Text(
                    '사유 ${claim.reasonText ?? claim.reasonCode ?? '-'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '접수일 '
                '${formatOrderDateTime(claim.receivedAt.toIso8601String())}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const _Badge({
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
