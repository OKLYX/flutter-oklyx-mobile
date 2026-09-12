import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/inquiry.dart';
import '../bloc/inquiry_detail_bloc.dart';
import '../bloc/inquiry_detail_event.dart';
import '../bloc/inquiry_detail_state.dart';
import '../widgets/inquiry_order_panel.dart';
import '../widgets/inquiry_thread.dart';

/// 문의 상세 페이지 (FEATURE_2609_36 / 02 — **읽기 전용**).
///
/// 🔴 **진입 즉시 `GET /api/inquiries/{id}` 를 부른다**(PLAN M1). 클레임 상세는 `extra` 로
/// 받은 엔티티만 그리고 끝나지만 문의는 그렇게 하면 빈 화면이 된다 — 스레드(`replies`) ·
/// 관련 주문 · 관련 상품 · 답변 가능 여부는 **단건 조회에서만** 채워지고 목록 응답에서는
/// 항상 null 이다. `extra` 로 받은 목록 항목은 **헤더를 먼저 그리는 용도**로만 쓴다
/// (스피너만 있는 화면을 보여주지 않기 위해서다).
///
/// 화면 순서(세로 스택): 헤더 → 문의 본문 → 스레드 → 관련 주문/상품.
///
/// ⚠️ `build` 중에 `context.go`/`pop` 으로 **자동 이동하지 않는다** — 빌드 중 네비게이션은
/// 예외를 던진다. `extra` 가 없으면(딥링크·핫리로드) 안내 패널 + 복귀 버튼을 그린다.
/// ⚠️ 연락처·이메일·주소를 그리지 않는다(M8) — 서버가 내려주지 않는다.
/// ❌ 답변 작성 UI 금지 — 버튼 자리도 만들지 않는다(별도 범위).
class InquiryDetailPage extends StatelessWidget {
  /// 목록에서 `extra` 로 받은 문의. null 이면 id 를 알 수 없어 조회 자체가 불가능하다.
  final Inquiry? inquiry;

  const InquiryDetailPage({super.key, this.inquiry});

  @override
  Widget build(BuildContext context) {
    final listItem = inquiry;
    return ScaffoldWithNavBar(
      title: '문의 상세',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      // 목록의 탭·필터·스크롤 위치를 지키려면 **pop** 이어야 한다(카드가 push 로 왔다).
      // 딥링크로 진입해 pop 할 곳이 없을 때만 목록으로 보낸다.
      onBackPressed: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go(Routes.inquiryListPath);
      },
      body: listItem == null
          ? _buildMissing(context)
          : BlocProvider(
              create: (_) => getIt<InquiryDetailBloc>()
                ..add(LoadInquiry(id: listItem.id)),
              child: _InquiryDetailView(listItem: listItem),
            ),
    );
  }

  // extra 로 전달된 문의가 없는 경우(딥링크/핫리로드) 목록 복귀를 유도한다.
  Widget _buildMissing(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('문의 정보를 찾을 수 없습니다.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go(Routes.inquiryListPath),
              child: const Text('고객문의로'),
            ),
          ],
        ),
      );
}

class _InquiryDetailView extends StatelessWidget {
  /// 목록 항목 — 헤더를 즉시 그리는 데 쓴다. 조회가 끝나면 서버 값으로 교체된다.
  final Inquiry listItem;

  const _InquiryDetailView({required this.listItem});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<InquiryDetailBloc, InquiryDetailState>(
        builder: (context, state) {
          final loaded = state is InquiryDetailLoaded ? state : null;
          final detail = loaded?.detail;
          // 헤더는 서버 값이 있으면 그걸, 없으면 목록 항목을 쓴다.
          final header = detail?.inquiry ?? listItem;
          final isLoading =
              state is InquiryDetailLoading || state is InquiryDetailInitial;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  inquiry: header,
                  typeLabel: loaded?.typeLabel,
                  isLoading: isLoading,
                  onRefresh: () =>
                      context.read<InquiryDetailBloc>().add(ReloadInquiry()),
                ),
                const SizedBox(height: 12),
                _Section(
                  title: '문의 내용',
                  // 본문은 **말줄임 없이** 전문을 그린다(목록 카드와 다르다).
                  child: SelectableText(
                    (header.content?.trim().isEmpty ?? true)
                        ? '-'
                        : header.content!.trim(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 12),
                if (state is InquiryDetailError)
                  _ErrorRetry(
                    message: state.message,
                    onRetry: () =>
                        context.read<InquiryDetailBloc>().add(ReloadInquiry()),
                  )
                else if (isLoading || detail == null)
                  // 스피너는 스레드·주문 패널 자리에만 놓는다(헤더는 이미 그려져 있다).
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _Section(
                    title: '답변',
                    child: InquiryThread(replies: detail.replies),
                  ),
                  const SizedBox(height: 12),
                  InquiryOrderPanel(
                    relatedOrder: detail.relatedOrder,
                    relatedListing: detail.relatedListing,
                  ),
                ],
                // ScaffoldWithNavBar 는 내비바를 오버레이하므로 하단 여백을 확보한다.
                SizedBox(
                  height: kBottomNavigationBarHeight +
                      MediaQuery.paddingOf(context).bottom +
                      16,
                ),
              ],
            ),
          );
        },
      );
}

/// 헤더 — 유형·상태·문의일·채널·답변일 + [새로고침].
///
/// 🔴 [새로고침] 은 답변 전송(03)의 회복 경로가 가리키는 유일한 수단이다 — 전송 결과를 모를
/// 때(502) "새로고침해 확인하세요" 안내가 이 버튼을 뜻한다. 빼지 말 것.
/// (앱 전체에 `RefreshIndicator` 관례가 없다 — 당겨서 새로고침으로 새 관례를 만들지 않는다.)
class _Header extends StatelessWidget {
  final Inquiry inquiry;
  final String? typeLabel;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _Header({
    required this.inquiry,
    required this.typeLabel,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final platformStatus = inquiry.platformStatus?.trim();
    final category = inquiry.category?.trim();
    final answeredAt = inquiry.answeredAt;
    final unanswered = inquiry.status == InquiryStatus.unanswered;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // 유형 라벨은 서버 `/types` 가 준 문구다 — 못 받았으면 그리지 않는다.
                      if (typeLabel != null)
                        _Chip(
                          text: typeLabel!,
                          color: scheme.onSurfaceVariant,
                          background: scheme.surfaceContainerHighest,
                        ),
                      _Chip(
                        text: getInquiryStatusLabel(inquiry.status),
                        color: unanswered
                            ? AppColors.foregroundLight
                            : scheme.onSurfaceVariant,
                        background: unanswered
                            ? AppColors.brandMain
                            : scheme.surfaceContainerHighest,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 조회 중에는 잠근다(연타로 요청이 겹치지 않게).
                OutlinedButton.icon(
                  onPressed: isLoading ? null : onRefresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('새로고침'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Row('문의일', formatOrderDateTime(
              inquiry.inquiredAt.toIso8601String(),
            )),
            _Row(
              '채널',
              '${inquiry.sellerName ?? '-'} · '
                  '${inquiryChannelLabel(
                inquiry.marketplaceAccountId,
                inquiry.accountAlias,
              )}',
            ),
            _Row('문의번호', inquiry.externalInquiryId),
            // 고객센터 접수 분류 — 상품문의에는 없다.
            if (category != null && category.isNotEmpty)
              _Row('접수 분류', category),
            if (answeredAt != null)
              _Row('답변일', formatOrderDateTime(answeredAt.toIso8601String())),
            // 플랫폼 원문 상태는 정보 손실 방지용 — 작은 회색 글씨 한 줄(클레임 상세와 같다).
            if (platformStatus != null && platformStatus.isNotEmpty)
              Text(
                '플랫폼 원문 상태: $platformStatus',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

/// 제목 + 내용 카드.
class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const _Chip({
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

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
}
