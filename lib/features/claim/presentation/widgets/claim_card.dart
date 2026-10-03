import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import '../../domain/entities/claim.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// Card for one claim (one row of the return / exchange list).
///
/// **Purpose**: shows order number + status / product name /
/// quantity · reason / received date.
/// **Required rule**: a new screen that draws a claim list uses this widget. Do
/// not build the card again per screen.
/// **File**: lib/features/claim/presentation/widgets/claim_card.dart
///
/// **Usage**:
/// ```dart
/// SliverList.separated(
///   itemCount: claims.length,
///   separatorBuilder: (_, __) => const AppRowGap(),
///   itemBuilder: (context, index) => ClaimCard(claim: claims[index]),
/// )
/// ```
///
/// ⚠️ Tap → navigation to the detail lives inside the widget (`context.push` +
/// `extra`) — the same idiom as `OrderCard`. Switching to `pushNamed` or
/// `context.go` makes the back navigation differ from card to card.
/// ⚠️ The widget does not build the status label or the date format itself —
/// it uses `getClaimStatusLabel` · `formatOrderDateTime`.
/// ⚠️ The platform's raw status (`platformStatus`) is not exposed on the card —
/// it is for the detail only.
/// ⚠️ The 「우리 기록」 badge is attached only to claims whose collect invoice
/// exists **only in our own ledger** (2609_70 / D6) — when
/// `collectInvoiceSource` is null (existing rows of unknown origin) or
/// `PLATFORM`, nothing is shown.
class ClaimCard extends StatelessWidget {
  final Claim claim;

  const ClaimCard({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    return AppCard.row(
        onTap: () => context.push(Routes.claimDetailPath, extra: claim),
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      background:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ],
                  // 쿠팡엔 못 넣고 우리 장부에만 남은 회수송장(D6) — 재전송 대상이라 목록에서
                  // 바로 보이게 한다.
                  if (claim.collectInvoiceLocalOnly) ...[
                    const SizedBox(width: 6),
                    const _Badge(
                      text: '우리 기록',
                      color: AppColors.warningForeground,
                      background: AppColors.warningSurface,
                    ),
                  ],
                  const SizedBox(width: 6),
                  _Badge(
                    text: getClaimStatusLabel(claim.status),
                    color: AppColors.infoForeground,
                    background: AppColors.infoSurface,
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '사유 ${claim.reasonText ?? claim.reasonCode ?? '-'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '접수일 '
                '${formatOrderDateTime(claim.receivedAt.toIso8601String())}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
