import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/entities/order_period.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/inquiry.dart';
import '../bloc/inquiry_list_bloc.dart';
import '../bloc/inquiry_list_event.dart';
import '../bloc/inquiry_list_state.dart';
import '../widgets/inquiry_card.dart';
import '../widgets/inquiry_status_filter_bar.dart';
import '../widgets/inquiry_type_tabs.dart';

/// 주문관리 > 고객문의 페이지 (FEATURE_2609_36 — 조회 + 문의만 가져오기).
///
/// **기능**:
/// - 유형 탭(`InquiryTypeTabs`) — 후보·라벨은 서버 `/types` 가 준다(PLAN M2). **서버 재조회**
/// - 판매자 / 채널 / 기간 / 검색어를 고르고 [조회] 로 재조회 (`GET /api/inquiries`)
/// - 상태 칩: 클라이언트 필터(건수 배지) — 서버를 부르지 않는다
/// - [동기화]: 선택 채널(없으면 전체)의 **문의만** 가져온다 (`POST /api/inquiries/sync`)
/// - 카드 탭 → 문의 상세(`extra` 전달 + 상세 API 재조회, M1)
///
/// ⚠️ **동기화 다이얼로그를 띄우지 않는다**(M4) — 진행은 버튼 자리의 한 줄 + 진행바다.
/// `SyncProgressDialog` 는 `OrderListBloc` 을 직접 읽어 재사용할 수 없다.
/// ⚠️ **채널 드롭다운 옵션은 동기화 대상뿐이다**(M12) — 주문내역의 합집합 규칙(2609_15 D7-a)은
/// 그 화면 전용이다.
/// ⚠️ 기간 드롭다운은 `buildPeriodOptions()` 를 **인자 없이** 부른다(M9) — 문의에는 월별
/// 건수 API 가 없어 '(데이터 없음)' 을 판정할 근거가 없다.
/// ❌ 답변 버튼·입력 자리를 만들지 말 것 — 답변은 별도 범위다.
class InquiryListPage extends StatelessWidget {
  const InquiryListPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<InquiryListBloc>()..add(LoadInquiries()),
        child: const _InquiryListView(),
      );
}

class _InquiryListView extends StatefulWidget {
  const _InquiryListView();

  @override
  State<_InquiryListView> createState() => _InquiryListViewState();
}

class _InquiryListViewState extends State<_InquiryListView> {
  /// 검색어 입력 컨트롤러. ⚠️ [_LoadedBody] 안에서 만들면 rebuild 마다 커서가 튄다 —
  /// 여기(State)에서 만들어 주입한다.
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      // 메뉴 일관성: 주문내역·반품/교환과 같은 navBarIndex·Drawer 버튼 노출.
      ScaffoldWithNavBar(
        title: '고객문의',
        navBarIndex: 2,
        showDrawer: true,
        showAppBarDrawerButton: false,
        body: BlocConsumer<InquiryListBloc, InquiryListState>(
          // 재조회·동기화 결과(기존 목록 유지)만 SnackBar 로 알린다.
          // ⚠️ 문구가 **바뀔 때만** 띄운다 — 동기화 뒤 재조회가 같은 문구를 실은 상태를
          // 한 번 더 emit 하므로, curr 만 보면 같은 SnackBar 가 두 번 뜬다.
          listenWhen: (prev, curr) =>
              curr is InquiryListLoaded &&
              _message(curr) != null &&
              _message(prev) != _message(curr),
          listener: (context, state) {
            final message = _message(state);
            if (message == null) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(message),
                  behavior: SnackBarBehavior.floating,
                  margin:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 70),
                ),
              );
            // 같은 문구가 다음 rebuild 에서 다시 뜨지 않게 소비 후 비운다.
            context.read<InquiryListBloc>().add(ActionErrorCleared());
          },
          builder: (context, state) {
            if (state is InquiryListInitial || state is InquiryListLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is InquiryListError) {
              return _ErrorRetry(
                message: state.message,
                onRetry: () =>
                    context.read<InquiryListBloc>().add(LoadInquiries()),
              );
            }

            return _LoadedBody(
              state: state as InquiryListLoaded,
              searchController: _searchController,
            );
          },
        ),
      );
}

/// SnackBar 문구 — 실패([InquiryListLoaded.actionError])가 성공 요약보다 우선이다.
String? _message(InquiryListState state) {
  if (state is! InquiryListLoaded) return null;
  return state.actionError ?? state.syncSummary;
}

class _LoadedBody extends StatelessWidget {
  final InquiryListLoaded state;
  final TextEditingController searchController;

  const _LoadedBody({required this.state, required this.searchController});

  @override
  Widget build(BuildContext context) {
    final s = state;
    final bloc = context.read<InquiryListBloc>();
    final inquiries = s.visible;
    final busy = s.busy;

    // 🔴 채널 옵션 = 동기화 대상뿐이다(M12). 목록에만 있는 계정 id 를 합치지 않는다.
    final accountOptions = <int, String>{
      for (final target in s.syncTargets)
        target.accountId:
            inquiryChannelLabel(target.accountId, target.accountAlias),
    };
    // 고른 채널이 옵션에서 사라지면 드롭다운이 assert 로 죽는다 — 그때는 전체로 되돌린다
    // (BLoC 도 판매자 변경 시 선택을 비우지만, 그 사이 프레임을 대비한다).
    final accountValue = accountOptions.containsKey(s.selectedAccountId)
        ? s.selectedAccountId
        : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 유형 탭 — 칩과 달리 서버를 다시 부른다(조회 중에는 잠근다).
          // 후보가 1개 이하면 위젯이 스스로 아무것도 그리지 않는다.
          InquiryTypeTabs(
            options: s.typeOptions,
            value: s.selectedType,
            enabled: !busy,
            onChanged: (type) => bloc.add(SelectType(type: type)),
          ),
          if (s.typeOptions.length > 1) const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          value: s.selectedSellerId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: '판매자',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('전체'),
                            ),
                            ...s.sellers.map(
                              (Seller seller) => DropdownMenuItem<int?>(
                                value: seller.id,
                                child: Text(
                                  seller.sellerName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: busy
                              ? null
                              : (value) =>
                                  bloc.add(SelectSeller(sellerId: value)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed:
                            busy ? null : () => bloc.add(SearchInquiries()),
                        child: Text(s.isSearching ? '조회 중...' : '조회'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 채널 필터 — 옵션은 동기화 대상뿐(M12). 판매자를 바꾸면 좁아진다.
                  DropdownButtonFormField<int?>(
                    value: accountValue,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '채널',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('전체'),
                      ),
                      ...accountOptions.entries.map(
                        (entry) => DropdownMenuItem<int?>(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: busy
                        ? null
                        : (value) => bloc.add(SelectChannel(accountId: value)),
                  ),
                  const SizedBox(height: 8),
                  // 기간 드롭다운 — 고른 값은 [조회] 를 눌러야 목록에 반영된다.
                  // ⚠️ monthsWithData 를 넘기지 않는다(= null) — 문의엔 월별 건수 API 가
                  // 없어 '(데이터 없음)' 을 붙이면 전 달이 거짓으로 표시된다(M9).
                  DropdownButtonFormField<String>(
                    value: s.selectedPeriod,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '기간',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: buildPeriodOptions()
                        .map((o) => DropdownMenuItem<String>(
                              value: o.value,
                              child: Text(
                                o.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: busy
                        ? null
                        : (value) => bloc.add(SelectPeriod(period: value!)),
                  ),
                  const SizedBox(height: 8),
                  // 검색어는 **서버로** 보낸다 — [조회] 를 눌러야 반영된다.
                  TextField(
                    controller: searchController,
                    enabled: !busy,
                    onChanged: (value) =>
                        bloc.add(ChangeSearchTerm(term: value)),
                    onSubmitted: (_) =>
                        busy ? null : bloc.add(SearchInquiries()),
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      hintText: '문의 내용·상품명·주문번호 검색',
                      suffixIcon: s.searchTerm.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                searchController.clear();
                                bloc.add(ChangeSearchTerm(term: ''));
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 동기화 — 진행은 이 자리의 한 줄이다(다이얼로그 금지, M4).
                  if (s.isSyncing)
                    _SyncProgress(
                      done: s.syncDone,
                      total: s.syncTotal,
                      channelName: s.syncingChannelName,
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: busy || s.syncTargets.isEmpty
                                ? null
                                : () => bloc.add(SyncInquiries()),
                            icon: const Icon(Icons.sync, size: 18),
                            label: const Text('동기화'),
                          ),
                        ),
                      ],
                    ),
                  // 대상이 없으면 버튼이 왜 꺼져 있는지 한 줄로 알린다.
                  if (!s.isSyncing && s.syncTargets.isEmpty) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '가져올 채널이 없습니다',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 상태 칩 — 클라이언트 필터. 같은 칩 재선택 시 전체 해제.
          InquiryStatusFilterBar(
            selectedStatus: s.selectedStatus,
            counts: s.statusCounts,
            onSelect: (status) => bloc.add(SelectStatus(status: status)),
          ),
          const SizedBox(height: 8),

          Text(
            '총 ${inquiries.length}건',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: s.isSearching
                ? const Center(child: CircularProgressIndicator())
                : inquiries.isEmpty
                    ? Center(
                        child: Text(
                          // 문구 2종을 구분한다 — 칩으로 0건인지, 기간에 아예 없는지.
                          s.selectedStatus != null
                              ? '이 상태의 문의가 없습니다.'
                              : '해당 기간에 문의가 없습니다.',
                        ),
                      )
                    : ListView.separated(
                        // ScaffoldWithNavBar 는 내비바를 오버레이하므로 하단 여백을 확보한다.
                        padding: EdgeInsets.only(
                          bottom: kBottomNavigationBarHeight +
                              MediaQuery.paddingOf(context).bottom +
                              24,
                        ),
                        itemCount: inquiries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final inquiry = inquiries[index];
                          return InquiryCard(
                            inquiry: inquiry,
                            // 상세는 진입 후 단건 API 를 다시 부른다 — `extra` 는 헤더를
                            // 먼저 그리기 위한 것이다(M1).
                            onTap: () => context.push(
                              Routes.inquiryDetailPath,
                              extra: inquiry,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// 동기화 진행 한 줄 + 진행바 (M4 — 다이얼로그를 쓰지 않는 이유는 페이지 주석 참고).
class _SyncProgress extends StatelessWidget {
  final int done;
  final int total;
  final String? channelName;

  const _SyncProgress({
    required this.done,
    required this.total,
    this.channelName,
  });

  @override
  Widget build(BuildContext context) {
    // 진행 중인 채널은 done + 1 번째다(끝난 개수 + 1).
    final current = total == 0 ? 0 : (done + 1).clamp(1, total);
    final name = channelName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '동기화 중 ($current/$total)${name == null ? '' : ' · $name'}',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: total == 0 ? null : done / total,
        ),
      ],
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      );
}
