import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/product_listing.dart';
import '../bloc/product_listing_list_bloc.dart';
import '../bloc/product_listing_list_event.dart';
import '../bloc/product_listing_list_state.dart';
import '../product_listing_refresh.dart';

/// 판매상품 조회 페이지 (목록 + 검색)
///
/// 프론트 "판매상품 조회"와 동일한 기능:
/// - 플랫폼 선택 후 검색
/// - 행 펼치기로 옵션(판매가/마진/마진율) 표시
/// - 카드 탭 시 상세 페이지로 이동
/// - 무한 스크롤 페이지네이션
///
/// UI는 모바일 "상품 조회"(ProductSearchPage) 스타일을 따른다.
class ProductListingSearchPage extends StatelessWidget {
  const ProductListingSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProductListingListBloc>(),
      child: const _ProductListingSearchView(),
    );
  }
}

/// 플랫폼 코드 → 한글 표시명 (프론트 ProductListingSearchCard와 동일)
const Map<String, String> _platformLabels = {
  'COUPANG': '쿠팡',
  'GMARKET': '지마켓',
  'AUCTION': '옥션',
  'SMARTSTORE': '스마트스토어',
};

class _ProductListingSearchView extends StatefulWidget {
  const _ProductListingSearchView();

  @override
  State<_ProductListingSearchView> createState() =>
      _ProductListingSearchViewState();
}

class _ProductListingSearchViewState extends State<_ProductListingSearchView> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedPlatform;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 수정/삭제 후 돌아오면 마지막 검색을 재실행해 변경 내용을 반영한다.
    productListingRefreshSignal.addListener(_onRefreshSignal);
  }

  @override
  void dispose() {
    productListingRefreshSignal.removeListener(_onRefreshSignal);
    _scrollController.dispose();
    super.dispose();
  }

  // 갱신 신호 수신 시 마지막으로 조회한 플랫폼으로 재검색 (이미 검색한 경우에만).
  void _onRefreshSignal() {
    if (!mounted) return;
    final state = context.read<ProductListingListBloc>().state;
    if (state is ProductListingListLoaded) {
      context
          .read<ProductListingListBloc>()
          .add(SearchProductListings(platform: state.platform));
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      final state = context.read<ProductListingListBloc>().state;
      if (state is ProductListingListLoaded && state.hasMore && !state.isLoadingMore) {
        context.read<ProductListingListBloc>().add(LoadMoreProductListings());
      }
    }
  }

  void _onSearch() {
    final platform = _selectedPlatform;
    if (platform == null || platform.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('플랫폼을 선택해주세요.')),
      );
      return;
    }
    context
        .read<ProductListingListBloc>()
        .add(SearchProductListings(platform: platform));
  }

  @override
  Widget build(BuildContext context) => ScaffoldWithNavBar(
        title: '판매상품 조회',
        navBarIndex: 2,
        showDrawer: true,
        showAppBarDrawerButton: false,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPlatform,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: '플랫폼',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('선택하세요'),
                      items: _platformLabels.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedPlatform = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 프론트 ProductListingSearchCard와 동일: 로딩 중 비활성화 + '검색 중...'
                  BlocBuilder<ProductListingListBloc, ProductListingListState>(
                    builder: (context, state) {
                      final isLoading = state is ProductListingListLoading;
                      return ElevatedButton(
                        onPressed: isLoading ? null : _onSearch,
                        child: Text(isLoading ? '검색 중...' : '검색'),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 프론트 ProductListingSearchCard와 동일: 결과 개수 표시 (N개의 결과)
              BlocBuilder<ProductListingListBloc, ProductListingListState>(
                builder: (context, state) {
                  if (state is ProductListingListLoaded &&
                      state.listings.isNotEmpty) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${state.listings.length}개의 결과',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<ProductListingListBloc, ProductListingListState>(
                  builder: (context, state) {
                    if (state is ProductListingListInitial) {
                      return const Center(
                        child: Text('플랫폼을 선택하고 검색해주세요.'),
                      );
                    }

                    if (state is ProductListingListLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is ProductListingListError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(state.message),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _onSearch,
                              child: const Text('재시도'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is ProductListingListLoaded) {
                      if (state.listings.isEmpty) {
                        return const Center(child: Text('조회 결과가 없습니다.'));
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        itemCount:
                            state.listings.length + (state.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.listings.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final listing = state.listings[index];
                          return _ProductListingCard(
                            listing: listing,
                            isExpanded: state.expandedId == listing.id,
                            onToggle: () => context
                                .read<ProductListingListBloc>()
                                .add(ToggleListingOptions(listingId: listing.id)),
                            onTap: () => context.go(
                              Routes.salesProductsDetailRoute(listing.id),
                            ),
                          );
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      );
}

class _ProductListingCard extends StatelessWidget {
  final ProductListing listing;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _ProductListingCard({
    required this.listing,
    required this.isExpanded,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _Badge(
                              text: _platformLabels[listing.platform] ??
                                  listing.platform,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '상품 ID: ${listing.platformProductId}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '카테고리: ${listing.categoryName ?? '-'}  ·  '
                          '배송사: ${listing.carrierName ?? '-'}  ·  '
                          '패키지: ${listing.packageType ?? '-'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[700],
                    ),
                    onPressed: onToggle,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _OptionsSection(options: listing.options),
            ),
        ],
      ),
    );
  }
}

class _OptionsSection extends StatelessWidget {
  final List<ProductListingOption>? options;

  const _OptionsSection({required this.options});

  @override
  Widget build(BuildContext context) {
    final opts = options ?? const [];
    if (opts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '등록된 옵션이 없습니다.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(flex: 3, child: _HeaderCell('옵션명')),
              Expanded(flex: 2, child: _HeaderCell('판매가', alignEnd: true)),
              Expanded(flex: 2, child: _HeaderCell('마진', alignEnd: true)),
              Expanded(flex: 2, child: _HeaderCell('마진율', alignEnd: true)),
            ],
          ),
          const Divider(height: 16),
          ...opts.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(flex: 3, child: _BodyCell(o.optionName)),
                  Expanded(
                    flex: 2,
                    child: _BodyCell(_formatNumber(o.sellingPrice), alignEnd: true),
                  ),
                  Expanded(
                    flex: 2,
                    child: _BodyCell(
                      o.margin != null ? _formatNumber(o.margin!) : '-',
                      alignEnd: true,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _BodyCell(
                      o.marginRate != null
                          ? '${(o.marginRate! * 100).toStringAsFixed(2)}%'
                          : '-',
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 1,234 형식의 천 단위 구분 (프론트 toLocaleString('ko-KR')과 동일)
  String _formatNumber(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    final negative = str.startsWith('-');
    final digits = negative ? str.substring(1) : str;
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return negative ? '-$buffer' : buffer.toString();
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool alignEnd;

  const _HeaderCell(this.text, {this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final String text;
  final bool alignEnd;

  const _BodyCell(this.text, {this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Colors.blue[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
