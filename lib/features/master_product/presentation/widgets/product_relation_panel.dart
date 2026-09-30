import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/master_format.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/get_products_usecase.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/presentation/widgets/product_thumbnail.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// Max results per search — when there are more, ask for a narrower query.
const int _searchSize = 20;

/// Web `purchasePlaceNames(product)`.
String _purchasePlaceNames(Product product) =>
    product.purchasePlaces.map((place) => place.name).join(', ');

/// **Left product panel** of the product-relation overview
/// (FEATURE_2609_80 / 09 — UX D50 · D54 · D63 · D67 · PLAN R-g).
///
/// **File**: lib/features/master_product/presentation/widgets/product_relation_panel.dart
/// **Web original**: `master-products/components/ProductRelationPanel.tsx` @09208a0
///
/// Two views switched inside the panel (no page navigation):
/// | View | Content |
/// |---|---|
/// | list (default) | component cards on top, product search below. Tapping a card / result opens the detail |
/// | detail | [뒤로] · product info (read only) · 「물품 화면에서 고치기 ↗」 · create mode = [구성상품에 넣기] |
///
/// [mode] = `'create'` (master create page, 10) | `'view'` (master detail, 09).
/// - create: the top-right slot stays empty (no product registration — R-g).
///   The detail view shows [구성상품에 넣기] → [onAddComponent].
/// - view: top-right [구성 변경] opens the composition page of [masterId].
///
/// [componentIds] = this master's component product ids (display order).
/// `null` = still loading (detail before the master arrives).
///
/// **Usage**:
/// ```dart
/// // master create page
/// ProductRelationPanel(
///   mode: 'create',
///   componentIds: selectedIds,
///   onAddComponent: addComponent,
///   addBlockedReason: null,
/// )
/// // master detail
/// ProductRelationPanel(
///   mode: 'view',
///   componentIds: master?.components.map((c) => c.productId).toList(),
///   masterId: id,
/// )
/// ```
///
/// ⚠️ The parent changes the composition (create = [onAddComponent]); the panel
///    never knows the parent state.
/// ⚠️ Product values (name · specs · photo) are never edited here — a product
///    is shared by several masters.
/// ❌ No product registration button or form here (R-g · discussion §4).
/// ❌ Do not open it as a popup — it is a section of the page.
class ProductRelationPanel extends StatefulWidget {
  final String mode;
  final List<int>? componentIds;
  final ValueChanged<Product>? onAddComponent;

  /// create only — why [구성상품에 넣기] is blocked (null = allowed). Shown
  /// as text under the button.
  final String? addBlockedReason;

  /// view only — master id for [구성 변경].
  final int? masterId;

  const ProductRelationPanel({
    required this.mode,
    required this.componentIds,
    super.key,
    this.onAddComponent,
    this.addBlockedReason,
    this.masterId,
  });

  @override
  State<ProductRelationPanel> createState() => _ProductRelationPanelState();
}

class _ProductRelationPanelState extends State<ProductRelationPanel> {
  // null = list view, otherwise the product shown in the detail view.
  Product? _detail;

  // Component card products (id → product). Search results are cached too.
  final Map<int, Product> _cache = {};

  // Component ids whose single lookup failed — kept as `#id` cards, never
  // fetched again.
  final List<int> _failedIds = [];

  // Ids being fetched right now (avoids duplicate lookups).
  final Set<int> _inFlight = {};

  final TextEditingController _searchController = TextEditingController();
  List<Product> _results = [];
  int _totalMatches = 0;
  bool _searching = false;
  bool _hasSearched = false;
  String _searchError = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchMissing();
  }

  @override
  void didUpdateWidget(covariant ProductRelationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fetchMissing();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  // Only components missing from the cache are fetched one by one (there
  // are usually few).
  Future<void> _fetchMissing() async {
    final ids = (widget.componentIds ?? const <int>[])
        .where((id) =>
            !_cache.containsKey(id) &&
            !_failedIds.contains(id) &&
            !_inFlight.contains(id))
        .toList();
    if (ids.isEmpty) {
      return;
    }
    _inFlight.addAll(ids);
    final detailUseCase = getIt<GetProductDetailUseCase>();
    final fetched = await Future.wait(
      ids.map((id) async {
        final result = await detailUseCase(GetProductDetailParams(id));
        return result.fold((_) => null, (p) => p);
      }),
    );
    _inFlight.removeAll(ids);
    if (!mounted) {
      return;
    }
    setState(() {
      for (var i = 0; i < ids.length; i++) {
        final p = fetched[i];
        if (p != null) {
          _cache[p.id] = p;
        } else {
          _failedIds.add(ids[i]);
        }
      }
    });
  }

  void _openDetail(Product product) {
    setState(() {
      _cache[product.id] = product;
      _detail = product;
    });
  }

  Future<void> _runSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return;
    }
    setState(() {
      _searching = true;
      _searchError = '';
    });
    final result = await getIt<GetProductsUseCase>()(
      GetProductsParams(page: 0, size: _searchSize, search: query),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      result.fold(
        (f) {
          _results = [];
          _totalMatches = 0;
          _searchError = failureText(f, '물품을 검색하지 못했습니다.');
        },
        (page) {
          _results = page.content;
          _totalMatches = page.totalElements;
        },
      );
      _hasSearched = true;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children:
          detail == null ? _buildList(context) : _buildDetail(context, detail),
    );
  }

  List<Widget> _buildList(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final componentIds = widget.componentIds;
    final masterId = widget.masterId;
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              '구성상품${componentIds != null ? ' ${componentIds.length}개' : ''}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          // create mode: the slot stays empty (no product registration — R-g).
          if (widget.mode != 'create' && masterId != null)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => context.pushNamed(
                Routes.masterProductComposition,
                pathParameters: {'id': '$masterId'},
              ),
              child: const Text('구성 변경'),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (componentIds == null)
        const _BusyLabel('불러오는 중...')
      else if (componentIds.isEmpty)
        Text(
          '구성상품이 없습니다.',
          style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        )
      else
        for (var i = 0; i < componentIds.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _componentCard(context, componentIds[i]),
        ],
      const SizedBox(height: 12),
      const Divider(height: 1),
      const SizedBox(height: 12),
      Text(
        '다른 물품 찾아보기',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _runSearch(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '상품명으로 검색',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: _searching || _searchController.text.trim().isEmpty
                ? null
                : _runSearch,
            child: _searching ? const _BusyLabel('검색 중...') : const Text('검색'),
          ),
        ],
      ),
      if (_searchError.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _searchError,
            style: TextStyle(fontSize: 14, color: scheme.error),
          ),
        ),
      ],
      if (_hasSearched && _searchError.isEmpty && _results.isEmpty) ...[
        const SizedBox(height: 8),
        Text(
          '검색 결과가 없습니다.',
          style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        ),
      ],
      if (_results.isNotEmpty) ...[
        const SizedBox(height: 8),
        for (var i = 0; i < _results.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ProductCard(
            product: _results[i],
            onTap: () => _openDetail(_results[i]),
          ),
        ],
      ],
      if (_totalMatches > _results.length && _results.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(
          '$_totalMatches개 중 ${_results.length}개 표시 — 더 구체적으로 검색하세요.',
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
      ],
    ];
  }

  Widget _componentCard(BuildContext context, int id) {
    final product = _cache[id];
    if (product != null) {
      return _ProductCard(product: product, onTap: () => _openDetail(product));
    }
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _failedIds.contains(id) ? '#$id (불러오지 못했습니다)' : '불러오는 중…',
        style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
      ),
    );
  }

  List<Widget> _buildDetail(BuildContext context, Product product) {
    final scheme = Theme.of(context).colorScheme;
    final componentIds = widget.componentIds ?? const <int>[];
    final blockedReason = widget.addBlockedReason;
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => setState(() => _detail = null),
            child: const Text('뒤로'),
          ),
          TextButton(
            onPressed: () => context.pushNamed(
              Routes.productDetail,
              pathParameters: {'productId': '${product.id}'},
            ),
            child: const Text(
              '물품 화면에서 고치기 ↗',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _ProductBrief(product: product),
      if (widget.mode == 'create') ...[
        const SizedBox(height: 12),
        if (componentIds.contains(product.id))
          Text(
            '이미 구성상품입니다.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          )
        else ...[
          FilledButton(
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: blockedReason != null
                ? null
                : () => widget.onAddComponent?.call(product),
            child: const Text('구성상품에 넣기'),
          ),
          if (blockedReason != null && blockedReason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              blockedReason,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.warningForeground,
              ),
            ),
          ],
        ],
      ],
    ];
  }
}

/// One component / search result card — tap opens the in-panel detail.
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = product.brand;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            ProductThumbnail(productId: product.id, size: 40),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.productName,
                      style: const TextStyle(fontSize: 14)),
                  Text(
                    '${brand == null || brand.isEmpty ? '-' : brand} · ${formatKrw(product.price)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Product info (read only). Items and labels = the 「상품 정보」 of the
/// product detail screen (web `ProductDetailView`).
class _ProductBrief extends StatelessWidget {
  final Product product;

  const _ProductBrief({required this.product});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final countQuantity = product.countQuantity;
    final price = product.price;
    final description = product.description;
    final rows = <({String label, String? value})>[
      (label: '바코드 ID', value: product.barcodeId),
      (label: '브랜드', value: product.brand),
      (label: '가격', value: price == null ? null : formatKrw(price)),
      (label: '구매처', value: _purchasePlaceNames(product)),
      (label: '내용물 양', value: product.netContent),
      (label: '단위', value: product.netContentUnit),
      (label: '개수', value: countQuantity != null ? '$countQuantity' : null),
      (label: '개수 단위', value: product.countUnit),
      (label: '높이', value: product.packageHeight),
      (label: '길이', value: product.packageLength),
      (label: '너비', value: product.packageWidth),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductThumbnail(productId: product.id, size: 96),
        const SizedBox(height: 12),
        Text(
          product.productName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rows[i].label,
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  rows[i].value != null && rows[i].value!.trim().isNotEmpty
                      ? rows[i].value!
                      : '-',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Text(
            '설명',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 14)),
        ],
      ],
    );
  }
}

class _BusyLabel extends StatelessWidget {
  final String label;

  const _BusyLabel(this.label);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
}
