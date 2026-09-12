import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import '../../domain/entities/inquiry.dart';
import '../../domain/entities/inquiry_detail.dart';

/// 문의 답변 스레드 — 역할별로 좌/우와 배경색을 나눈 말풍선 목록.
///
/// **용도**: 상세 화면의 대화 이력. 시간순은 **서버가 정렬해 준다**(다시 정렬하지 않는다).
/// **필수 규칙**: 고객 문의 본문을 여기에 말풍선으로 넣지 말 것 — 본문은 상세의 별도 섹션이
/// 소유한다(중복 표시).
/// **파일**: lib/features/inquiry/presentation/widgets/inquiry_thread.dart
///
/// | 역할 | 정렬 | 라벨 |
/// |------|------|------|
/// | SELLER | 오른쪽 | 판매자 |
/// | CS_AGENT | 왼쪽 | 쿠팡 상담사 (+ 이름) |
///
/// **사용 예제**:
/// ```dart
/// InquiryThread(replies: detail.replies)
/// ```
///
/// ⚠️ `transferStatus` 는 화면에 쓰지 않는다(디버깅용 보관 필드다).
/// ❌ 답변 입력·전송 버튼 금지 — 쓰기는 이 위젯의 범위가 아니다.
class InquiryThread extends StatelessWidget {
  final List<InquiryReply> replies;

  const InquiryThread({super.key, required this.replies});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (replies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            '아직 답변이 없습니다.',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Column(
      children: replies
          .map((reply) => _Bubble(
                author: _authorLabel(reply),
                content: reply.content,
                at: reply.repliedAt,
                isMine: reply.authorRole == InquiryAuthorRole.seller,
              ))
          .toList(),
    );
  }

  /// 상담사 이름은 고객 PII 가 아니다(2609_23 D13) — 있으면 함께 보여준다.
  String _authorLabel(InquiryReply reply) {
    if (reply.authorRole == InquiryAuthorRole.seller) return '판매자';
    final name = reply.authorName?.trim();
    return (name == null || name.isEmpty) ? '쿠팡 상담사' : '쿠팡 상담사 $name';
  }
}

class _Bubble extends StatelessWidget {
  final String author;
  final String? content;
  final DateTime? at;

  /// true = 판매자(우리) 답변 → 오른쪽 정렬.
  final bool isMine;

  const _Bubble({
    required this.author,
    required this.content,
    required this.at,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final alignment = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final body = content?.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(
            author,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isMine
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                (body == null || body.isEmpty) ? '-' : body,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          // 시각이 없으면 줄을 만들지 않는다(빈 '-' 를 남기지 않는다).
          if (at != null) ...[
            const SizedBox(height: 4),
            Text(
              formatOrderDateTime(at!.toIso8601String()),
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
