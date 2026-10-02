import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_route_args.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_network_image.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';

/// Master product list (FEATURE_2609_80 / 04 — web `master-products/components/MasterProductList.tsx`
/// + `MasterProductSearchCard.tsx` + `masterListQuery.ts` @09208a0).
///
/// **File**: lib/features/master_product/presentation/pages/master_product_list_page.dart
///
/// - The search term is committed by [검색] or the keyboard done key (no query per keystroke — same as the web).
/// - Sort changes re-query immediately. No page-size picker — infinite scroll, 25 per page (PLAN R-c).
/// - Tapping a row opens the detail. The only row action is [삭제] (hard delete, confirm dialog D32).
/// ❌ No [마스터 추가] button on the list (same as the web — the entry is the drawer).
class MasterProductListPage extends StatefulWidget {
  const MasterProductListPage({super.key});

  @override
  State<MasterProductListPage> createState() => _MasterProductListPageState();
}

/// Web `SORT_OPTIONS`.
const List<({String value, String label})> _sortOptions = [
  (value: 'createdAt,desc', label: '등록일 최신순'),
  (value: 'createdAt,asc', label: '등록일 오래된순'),
];

/// Web `DEFAULT_SIZE`.
const int _pageSize = 25;

class _MasterProductListPageState extends State<MasterProductListPage> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _sort = _sortOptions.first.value;
  String? _query;
  List<MasterProduct> _masters = [];
  int _page = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _error = '';
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _reload();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  /// Reload from the first page (after search, sort change or delete).
  Future<void> _reload() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final result = await _useCase.listMasters(
      page: 0,
      size: _pageSize,
      sort: _sort,
      search: _query,
    );
    if (!mounted) {
      return;
    }
    result.fold(
      (_) => setState(() {
        _isLoading = false;
        _error = '판매상품 마스터를 불러오지 못했습니다.';
      }),
      (page) => setState(() {
        _isLoading = false;
        _masters = page.content;
        _page = 0;
        _totalPages = page.totalPages;
        _totalElements = page.totalElements;
      }),
    );
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || _page + 1 >= _totalPages) {
      return;
    }
    setState(() => _isLoadingMore = true);
    final next = _page + 1;
    final result = await _useCase.listMasters(
      page: next,
      size: _pageSize,
      sort: _sort,
      search: _query,
    );
    if (!mounted) {
      return;
    }
    result.fold(
      (_) => setState(() {
        _isLoadingMore = false;
        _error = '판매상품 마스터를 불러오지 못했습니다.';
      }),
      (page) => setState(() {
        _isLoadingMore = false;
        _masters = [..._masters, ...page.content];
        _page = next;
        _totalPages = page.totalPages;
        _totalElements = page.totalElements;
      }),
    );
  }

  void _search() {
    final next = _searchController.text.trim();
    _query = next.isEmpty ? null : next;
    _reload();
  }

  Future<void> _delete(MasterProduct target) async {
    final ok = await showAppConfirmDialog(
      context,
      title: '마스터 삭제',
      message: '${target.name} 을(를) 삭제합니다. 되돌릴 수 없습니다.\n\n'
          '• 옵션 ${target.options.length}개 · 구성상품 ${target.components.length}개와 '
          '사진이 함께 삭제됩니다\n'
          '• 마켓에 올리지 않은 채널은 함께 삭제됩니다\n'
          '• 마켓에 올린 채널이 있으면 삭제되지 않습니다 — 먼저 [연결 해제] 하세요\n'
          '• 연결 해제한 판매상품이 이 마스터의 사진을 쓰고 있었다면 상세 이미지가 깨질 수 있습니다',
      confirmText: '삭제',
      isDangerous: true,
    );
    if (!ok || !mounted) {
      return;
    }
    setState(() {
      _error = '';
      _busyId = target.id;
    });
    final result = await _useCase.deleteMaster(target.id);
    if (!mounted) {
      return;
    }
    setState(() => _busyId = null);
    result.fold(
      (f) => setState(() => _error = failureText(f, '삭제에 실패했습니다.')),
      (_) => _reload(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '판매상품 마스터',
      navBarIndex: 2,
      showAppBarDrawerButton: false,
      body: AppPageBody(
        controller: _scrollController,
        children: [
          _buildSearchCard(),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppErrorBox(message: _error),
          ],
          const SizedBox(height: 12),
          if (_isLoading)
            const AppLoading()
          else if (_masters.isEmpty)
            AppEmpty(
              _query != null ? '검색 결과가 없습니다.' : '등록된 판매상품 마스터가 없습니다.',
            )
          else
            for (var i = 0; i < _masters.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _buildRow(_masters[i]),
            ],
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, _) => TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    labelText: '검색',
                    hintText: '이름 · 상품ID · 옵션ID',
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: '검색어 지우기',
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: _searchController.clear,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _sort,
                decoration: const InputDecoration(labelText: '정렬'),
                items: [
                  for (final option in _sortOptions)
                    DropdownMenuItem(
                      value: option.value,
                      child: Text(option.label),
                    ),
                ],
                onChanged: (next) {
                  if (next == null || next == _sort) {
                    return;
                  }
                  setState(() => _sort = next);
                  _reload();
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_totalElements > 0) Text('$_totalElements개의 결과'),
                  const Spacer(),
                  FilledButton(
                    onPressed: _isLoading ? null : _search,
                    child: Text(_isLoading ? '검색 중...' : '검색'),
                  ),
                ],
              ),
            ],
          ),
      );

  Widget _buildRow(MasterProduct m) => AppCard.row(
          onTap: () => context.pushNamed(
            Routes.masterProductDetail,
            pathParameters: {'id': '${m.id}'},
            extra: const MasterDetailArgs(),
          ),
            child: Row(
              children: [
                MasterNetworkImage(
                    url: m.sourceImageUrl, width: 48, height: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text('구성상품: ${m.components.length}'),
                      Text('옵션: ${m.options.length}'),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: _busyId == m.id ? null : () => _delete(m),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('삭제'),
                ),
              ],
            ),
      );
}
