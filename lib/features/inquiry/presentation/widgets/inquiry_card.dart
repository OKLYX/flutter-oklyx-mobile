import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import '../../domain/entities/inquiry.dart';

/// 문의 1건 카드 (고객문의 목록의 행 하나).
///
/// **용도**: 문의일 + 상태 / 상품명 / 문의 본문 2줄 / 채널명 + 답변일 을 보여준다.
/// **필수 규칙**: 문의 목록을 그리는 새 화면은 이 위젯을 쓴다. 화면별로 카드를 다시 만들지 말 것.
/// **파일**: lib/features/inquiry/presentation/widgets/inquiry_card.dart
///
/// **사용 예제**:
/// ```dart
/// InquiryCard(
///   inquiry: inquiries[index],
///   onTap: () => context.push(Routes.inquiryDetailPath, extra: inquiries[index]),
/// )
/// ```
///
/// ⚠️ 상세 이동은 **호출자가 [onTap] 으로 준다** — `ClaimCard` 가 내부에서 `context.push` 를
/// 하는 것과 다른 점이고, 상세 라우트의 소유자가 페이지 쪽이기 때문이다.
/// ⚠️ 상태 라벨·날짜 포맷을 위젯이 직접 만들지 않는다 — [getInquiryStatusLabel] ·
/// `formatOrderDateTime` 를 쓴다.
/// ⚠️ 플랫폼 원문 상태(`platformStatus`)는 카드에 노출하지 않는다 — 상세 전용이다.
/// ❌ `linked == false` 배지 금지 — 상품문의는 주문 없는 질문이 다수라 정상이고(D15),
/// 배지를 달면 대부분의 카드에 경고가 붙는다.
/// ❌ 답변 버튼·입력 자리 금지 — 답변은 상세 화면의 몫이다.
class InquiryCard extends StatelessWidget {
  final Inquiry inquiry;
  final VoidCallback? onTap;

  const InquiryCard({super.key, required this.inquiry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = inquiry.content?.trim();
    final answeredAt = inquiry.answeredAt;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatOrderDateTime(inquiry.inquiredAt.toIso8601String()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _Badge(
                    text: getInquiryStatusLabel(inquiry.status),
                    // 미답변만 눈에 띄게 — 나머지는 회색이라 처리할 건이 먼저 보인다
                    // (웹 목록과 같은 규칙).
                    color: inquiry.status == InquiryStatus.unanswered
                        ? AppColors.foregroundLight
                        : scheme.onSurfaceVariant,
                    background: inquiry.status == InquiryStatus.unanswered
                        ? AppColors.brandMain
                        : scheme.surfaceContainerHighest,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                inquiry.itemName ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              // 본문은 2줄 말줄임 — 전문은 상세가 그린다.
              Text(
                (content == null || content.isEmpty) ? '-' : content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    inquiryChannelLabel(
                      inquiry.marketplaceAccountId,
                      inquiry.accountAlias,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (answeredAt != null)
                    Text(
                      '답변일 '
                      '${formatOrderDateTime(answeredAt.toIso8601String())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
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
  Widget build(BuildContext context) => Container(
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
