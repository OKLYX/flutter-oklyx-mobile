import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/entities/order_period.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../bloc/claim_list_bloc.dart';
import '../bloc/claim_list_event.dart';
import '../bloc/claim_list_state.dart';
import '../widgets/claim_card.dart';
import '../widgets/claim_status_filter_bar.dart';
import '../widgets/claim_type_tabs.dart';

/// 주문관리 > 반품/교환 페이지 (FEATURE_2609_18 — 조회 전용).
///
/// **기능**:
/// - 반품 / 교환 탭 전환 (`ClaimTypeTabs`) — **서버 재조회**를 부른다
/// - 판매자 / 기간 / 검색어를 고르고 [조회] 로 서버 재조회 (`GET /api/claims`)
/// - 상태 칩: 클라이언트 필터(건수 배지) — 서버를 부르지 않는다. 후보는 탭마다 다르다
/// - 카드 탭 → 클레임 상세(`extra` 전달, 상세 API 재조회 없음)
///
/// ⚠️ **처리 버튼(승인·입고확인)을 만들지 말 것** — 조회 전용이다(PLAN D4).
/// ⚠️ 기간 드롭다운은 `buildPeriodOptions()` 를 **인자 없이** 부른다 —
/// 클레임에는 월별 건수 API 가 없어 '(데이터 없음)' 을 판정할 근거가 없다.
class ClaimListPage extends StatelessWidget {
  const ClaimListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ClaimListBloc>()..add(LoadClaims()),
      child: const _ClaimListView(),
    );
  }
}

class _ClaimListView extends StatefulWidget {
  const _ClaimListView();

  @override
  State<_ClaimListView> createState() => _ClaimListViewState();
}

class _ClaimListViewState extends State<_ClaimListView> {
  /// 검색어 입력 컨트롤러. ⚠️ [_LoadedBody] 안에서 만들면 rebuild 마다 커서가 튄다 —
  /// 여기(State)에서 만들어 주입한다.
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 메뉴 일관성: 주문내역과 같은 navBarIndex·Drawer 버튼 노출.
    return ScaffoldWithNavBar(
      title: '반품/교환',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      body: BlocConsumer<ClaimListBloc, ClaimListState>(
        // 재조회 실패(기존 목록 유지)만 SnackBar 로 알린다.
        listenWhen: (prev, curr) =>
            curr is ClaimListLoaded && curr.actionError != null,
        listener: (context, state) {
          final message = (state as ClaimListLoaded).actionError;
          if (message == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
              ),
            );
        },
        builder: (context, state) {
          if (state is ClaimListInitial || state is ClaimListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ClaimListError) {
            return _ErrorRetry(
              message: state.message,
              onRetry: () => context.read<ClaimListBloc>().add(LoadClaims()),
            );
          }

          return _LoadedBody(
            state: state as ClaimListLoaded,
            searchController: _searchController,
          );
        },
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  final ClaimListLoaded state;
  final TextEditingController searchController;

  const _LoadedBody({required this.state, required this.searchController});

  @override
  Widget build(BuildContext context) {
    final s = state;
    final bloc = context.read<ClaimListBloc>();
    final claims = s.visible;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 반품 ↔ 교환 — 칩과 달리 서버를 다시 부른다(조회 중에는 잠근다).
          ClaimTypeTabs(
            value: s.claimType,
            enabled: !s.isSearching,
            onChanged: (t) => bloc.add(SelectClaimType(type: t)),
          ),
          const SizedBox(height: 12),
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
                          onChanged: s.isSearching
                              ? null
                              : (value) =>
                                  bloc.add(SelectSeller(sellerId: value)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: s.isSearching
                            ? null
                            : () => bloc.add(SearchClaims()),
                        child: Text(s.isSearching ? '조회 중...' : '조회'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 기간 드롭다운 — 고른 값은 [조회] 를 눌러야 목록에 반영된다.
                  // ⚠️ monthsWithData 를 넘기지 않는다(= null) — 클레임엔 월별 건수 API 가 없어
                  // '(데이터 없음)' 을 붙이면 전 달이 거짓으로 표시된다.
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
                    onChanged: s.isSearching
                        ? null
                        : (value) => bloc.add(SelectPeriod(period: value!)),
                  ),
                  const SizedBox(height: 8),
                  // 검색어는 **서버로** 보낸다 — [조회] 를 눌러야 반영된다.
                  TextField(
                    controller: searchController,
                    enabled: !s.isSearching,
                    onChanged: (value) =>
                        bloc.add(ChangeSearchTerm(term: value)),
                    onSubmitted: (_) =>
                        s.isSearching ? null : bloc.add(SearchClaims()),
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      hintText: '주문번호·접수번호·상품명 검색',
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 상태 칩 — 클라이언트 필터. 같은 칩 재선택 시 전체 해제.
          // 후보 목록은 탭마다 다르다(state 파생 — 화면이 분기를 들지 않는다).
          ClaimStatusFilterBar(
            selectedStatus: s.selectedStatus,
            counts: s.statusCounts,
            statuses: s.statusFilters,
            onSelect: (status) => bloc.add(SelectStatus(status: status)),
          ),
          const SizedBox(height: 8),

          Text(
            '총 ${claims.length}건',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: s.isSearching
                ? const Center(child: CircularProgressIndicator())
                : claims.isEmpty
                    ? Center(
                        child: Text(
                          // 문구 2종을 구분한다 — 칩으로 0건인지, 기간에 아예 없는지.
                          s.selectedStatus != null
                              ? '이 상태의 ${s.typeLabel}이 없습니다.'
                              : '해당 기간에 ${s.typeLabel} 내역이 없습니다.',
                        ),
                      )
                    : ListView.separated(
                        // ScaffoldWithNavBar 는 내비바를 오버레이하므로 하단 여백을 확보한다.
                        padding: EdgeInsets.only(
                          bottom: kBottomNavigationBarHeight +
                              MediaQuery.paddingOf(context).bottom +
                              24,
                        ),
                        itemCount: claims.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            ClaimCard(claim: claims[index]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
}
