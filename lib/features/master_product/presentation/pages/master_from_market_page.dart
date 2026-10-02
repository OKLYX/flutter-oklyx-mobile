import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_route_args.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_tool_args.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/get_products_usecase.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';

// Status enum -> screen text (never show the raw enum). Kept local like the web.
const Map<String, String> _statusLabel = {
  'DRAFT': '미전송',
  'SUBMITTED': '승인 대기중',
  'SELLING': '판매중',
  'REJECTED': '승인 반려',
  'SUSPENDED': '판매 중지',
};

/// Supported platforms — Coupang only today (D17 · UX D64: one more record per
/// platform). (value, label, idLabel, idNumeric)
/// ⚠️ Never write a platform name directly in the widget tree.
const List<(String, String, String, bool)> _platforms = [
  ('COUPANG', '쿠팡', '쿠팡 상품 ID', true),
];

/// Tokens taken from the product name · candidates shown · size of one search (UX D79).
const int _candidateTokenLimit = 5;
const int _candidateLimit = 20;
const int _searchSize = 20;

/// Discriminator: a 400 containing this text = already attached to another
/// master (text owned by backend `DetachedCellPolicy`).
const String _alreadyLinked = '이미 다른 상품에 연결된';

/// One master row = name + component combination (UX D74). Overlap candidates
/// and name search results are drawn the same way.
class _MasterRow {
  final int id;
  final String name;
  final List<String> componentNames;

  const _MasterRow(this.id, this.name, this.componentNames);
}

/// Product name -> search tokens (split on whitespace · 2+ chars · unique ·
/// first 5).
List<String> _nameTokens(String name) {
  final seen = <String>{};
  final tokens = <String>[];
  for (final raw in name.split(RegExp(r'\s+'))) {
    final t = raw.trim();
    if (t.length >= 2 && seen.add(t)) {
      tokens.add(t);
    }
  }
  return tokens.take(_candidateTokenLimit).toList();
}

/// Uses the backend text as is and appends one actionable line only.
/// Decided by HTTP status + substring (no exception class names reach the app).
/// ⚠️ Texts are owned by backend `DetachedCellPolicy` · `MarketProductAccess`.
String _lookupErrorMessage(Failure f) {
  final status = f is ServerFailure ? f.statusCode : null;
  final message = failureText(f, '상품을 조회하지 못했습니다.');
  if (status == 429) return '잠시 후 다시 시도하세요.';
  if (status == 400 && message.contains(_alreadyLinked)) {
    return '$message 옮기려면 그 마스터에서 [마스터 연결 해제] 한 뒤 다시 조회하세요.';
  }
  if (status == 400 && message.contains('다른 판매자의')) {
    return '$message 위에서 판매자를 바꿔 다시 조회하세요.';
  }
  if (status == 400 && message.contains('계정')) {
    return '$message 판매자 관리에서 쿠팡 계정을 먼저 등록·활성화하세요.';
  }
  if (status == 404) {
    // 🔴 Never decide 404 by substring — the backend sends English. On this
    // screen a 404 is only seller / account.
    return '이 판매자의 쿠팡 계정을 찾을 수 없습니다. 판매자 관리에서 먼저 등록·활성화하세요.';
  }
  return message;
}

/// 「마켓 상품으로 시작」 (FEATURE_2609_80 / 11) — port of web
/// `master-products/new-from-channel/page.tsx` +
/// `components/MasterFromChannelForm.tsx` (@09208a0, UX D64 · D72~D81).
///
/// **File**: lib/features/master_product/presentation/pages/master_from_market_page.dart
///
/// Order: seller · sales channel · product ID → [조회] → product info → pick the
/// products inside it (candidates from the product name · direct search) →
/// every master containing at least one picked product → [이 마스터에 붙이기] /
/// [새 마스터로]. [기존 마스터에 붙이기] opens a master name search (UX D75).
///
/// - A product already attached to a master shows only the notice +
///   [그 마스터로 가기] (UX D81).
/// - [이 마스터에 붙이기] opens the shared 「마켓 상품 추가하기」 page
///   (`Routes.masterMarketProductAdd`, UX D42 · D78); on success → toast
///   「붙였습니다.」 + that master's detail.
/// - [새 마스터로] opens the create page in market mode with the looked-up
///   seller / platform / product ID + picked product ids (UX D70 · D77).
/// ❌ This screen saves nothing — creating masters / listings lives only in the
///    create page and the shared page.
/// ⚠️ The preview response is not cached (price / stock change).
class MasterFromMarketPage extends StatefulWidget {
  const MasterFromMarketPage({super.key});

  @override
  State<MasterFromMarketPage> createState() => _MasterFromMarketPageState();
}

class _MasterFromMarketPageState extends State<MasterFromMarketPage> {
  final MasterProductUseCase _masterUseCase = getIt<MasterProductUseCase>();
  final GetProductsUseCase _productsUseCase = getIt<GetProductsUseCase>();

  // ① seller · sales channel (UX D72 — two fields) · product ID
  List<Seller> _sellers = [];
  int? _sellerId;
  String _platform = _platforms[0].$1;
  final TextEditingController _productIdController = TextEditingController();

  // ② lookup result — keeps the seller / platform / product ID of the moment
  // of lookup (editing the inputs does not mix with the result).
  MasterFromChannelPreview? _preview;
  ({int sellerId, String platform, String platformProductId})? _lookedUp;
  bool _looking = false;
  String _error = '';
  // Master the product is already attached to (master list search = exact
  // product ID match, UX D74 🔁 · D81).
  List<_MasterRow> _linkedMasters = [];
  // Lookup sequence — a fast second lookup must not let the first product's
  // candidates overwrite the second product's screen.
  int _lookupSeq = 0;

  // ③ product picking (UX D79)
  List<Product> _candidates = [];
  bool _candidateLoading = false;
  String _candidateError = '';
  final TextEditingController _productSearchController =
      TextEditingController();
  List<Product>? _productSearchResults;
  bool _productSearching = false;
  List<Product> _selectedProducts = [];

  // ④ masters containing a picked product (UX D74)
  List<_MasterRow> _overlapMasters = [];
  bool _overlapLoading = false;
  String _overlapError = '';

  // ⑤ master name search (UX D75)
  bool _masterSearchOpen = false;
  final TextEditingController _masterSearchController = TextEditingController();
  List<_MasterRow>? _masterSearchResults;
  bool _masterSearching = false;
  String _masterSearchError = '';

  // ⑥ attach page
  int? _attachLoadingId;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSellers());
  }

  @override
  void dispose() {
    _productIdController.dispose();
    _productSearchController.dispose();
    _masterSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadSellers() async {
    final result = await getIt<GetSellersUseCase>()();
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _error = '판매자 목록을 불러오지 못했습니다.'),
      (list) => setState(() => _sellers = list),
    );
  }

  /// Input definition of the selected platform. All texts / input modes come from here.
  (String, String, String, bool) get _platformMeta => _platforms.firstWhere(
        (p) => p.$1 == _platform,
        orElse: () => _platforms[0],
      );

  /// Searches products per name token and ranks by hits (ties = first seen).
  Future<void> _loadCandidates(String productName, int seq) async {
    final tokens = _nameTokens(productName);
    if (tokens.isEmpty) return;
    setState(() {
      _candidateLoading = true;
      _candidateError = '';
    });
    final results = await Future.wait(
      tokens.map(
        (token) => _productsUseCase(
          GetProductsParams(page: 0, search: token),
        ),
      ),
    );
    final score = <int, ({Product product, int order})>{};
    final hits = <int, int>{};
    var order = 0;
    for (final result in results) {
      final page = result.toNullable();
      if (page == null) continue;
      for (final product in page.content) {
        if (score.containsKey(product.id)) {
          hits[product.id] = hits[product.id]! + 1;
        } else {
          score[product.id] = (product: product, order: order++);
          hits[product.id] = 1;
        }
      }
    }
    // Another product was looked up meanwhile — drop this result (the later
    // lookup owns the loading state).
    if (!mounted || seq != _lookupSeq) return;
    final ranked = score.values.toList()
      ..sort((a, b) {
        final byHits = hits[b.product.id]! - hits[a.product.id]!;
        return byHits != 0 ? byHits : a.order - b.order;
      });
    setState(() {
      if (results.every((r) => r.isLeft())) {
        _candidateError = '물품 후보를 불러오지 못했습니다. 아래에서 직접 검색하세요.';
      }
      _candidates = ranked.take(_candidateLimit).map((s) => s.product).toList();
      _candidateLoading = false;
    });
  }

  /// A new lookup drops the previous result, product picks and master candidates.
  Future<void> _handleLookup() async {
    final sellerId = _sellerId;
    final productId = _productIdController.text.trim();
    if (sellerId == null || productId.isEmpty || _looking) return;
    final target = (
      sellerId: sellerId,
      platform: _platform,
      platformProductId: productId,
    );
    final seq = ++_lookupSeq;
    setState(() {
      _looking = true;
      _candidateLoading = false;
      _error = '';
      _preview = null;
      _lookedUp = null;
      _linkedMasters = [];
      _candidates = [];
      _candidateError = '';
      _productSearchResults = null;
      _selectedProducts = [];
      _overlapMasters = [];
      _overlapError = '';
      _masterSearchOpen = false;
      _masterSearchResults = null;
    });
    final result = await _masterUseCase.masterFromChannelPreview(
      sellerId: target.sellerId,
      platform: target.platform,
      platformProductId: target.platformProductId,
    );
    if (!mounted) return;
    await result.fold(
      (f) async {
        setState(() => _error = _lookupErrorMessage(f));
        final status = f is ServerFailure ? f.statusCode : null;
        if (status == 400 && failureText(f, '').contains(_alreadyLinked)) {
          // Tell which master it is attached to — the master list search
          // matches the product ID exactly.
          final page = await _masterUseCase.listMasters(
            page: 0,
            size: _searchSize,
            sort: 'createdAt,desc',
            search: target.platformProductId,
          );
          if (!mounted) return;
          setState(() {
            _linkedMasters = page.fold(
              (_) => [],
              (p) => p.content
                  .map((m) => _MasterRow(
                        m.id,
                        m.name,
                        m.components.map((c) => c.productName).toList(),
                      ))
                  .toList(),
            );
          });
        }
      },
      (res) async {
        setState(() {
          _preview = res;
          _lookedUp = target;
        });
        unawaited(_loadCandidates(res.productName ?? '', seq));
      },
    );
    if (!mounted) return;
    setState(() => _looking = false);
  }

  /// Every pick / unpick reloads masters containing at least one picked product (UX D74).
  Future<void> _refreshOverlap(List<Product> products) async {
    setState(() => _overlapError = '');
    if (products.isEmpty) {
      setState(() => _overlapMasters = []);
      return;
    }
    setState(() => _overlapLoading = true);
    final result = await _masterUseCase
        .findByAnyComponent(products.map((p) => p.id).toList());
    if (!mounted) return;
    setState(() {
      result.fold(
        (f) {
          _overlapMasters = [];
          _overlapError = failureText(f, '마스터 후보를 불러오지 못했습니다.');
        },
        (rows) {
          _overlapMasters = rows
              .map((m) => _MasterRow(
                    m.id,
                    m.name,
                    m.components.map((c) => c.productName).toList(),
                  ))
              .toList();
        },
      );
      _overlapLoading = false;
    });
  }

  void _toggleProduct(Product product) {
    final next = _selectedProducts.any((p) => p.id == product.id)
        ? _selectedProducts.where((p) => p.id != product.id).toList()
        : [..._selectedProducts, product];
    setState(() => _selectedProducts = next);
    unawaited(_refreshOverlap(next));
  }

  Future<void> _handleProductSearch() async {
    final query = _productSearchController.text.trim();
    if (query.isEmpty || _productSearching) return;
    setState(() => _productSearching = true);
    final result = await _productsUseCase(
      GetProductsParams(page: 0, search: query),
    );
    if (!mounted) return;
    setState(() {
      _productSearchResults = result.fold((_) => [], (page) => page.content);
      _productSearching = false;
    });
  }

  Future<void> _handleMasterSearch() async {
    final query = _masterSearchController.text.trim();
    if (query.isEmpty || _masterSearching) return;
    setState(() {
      _masterSearching = true;
      _masterSearchError = '';
    });
    final result = await _masterUseCase.listMasters(
      page: 0,
      size: _searchSize,
      sort: 'createdAt,desc',
      search: query,
    );
    if (!mounted) return;
    setState(() {
      result.fold(
        (f) {
          _masterSearchResults = [];
          _masterSearchError = failureText(f, '마스터를 검색하지 못했습니다.');
        },
        (page) {
          _masterSearchResults = page.content
              .map((m) => _MasterRow(
                    m.id,
                    m.name,
                    m.components.map((c) => c.productName).toList(),
                  ))
              .toList();
        },
      );
      _masterSearching = false;
    });
  }

  /// [이 마스터에 붙이기] — reads the master's options and opens the shared
  /// page (it looks up as soon as it opens).
  Future<void> _openAttach(int masterId) async {
    final lookedUp = _lookedUp;
    if (_attachLoadingId != null || lookedUp == null) return;
    setState(() {
      _attachLoadingId = masterId;
      _error = '';
    });
    final result = await _masterUseCase.getMaster(masterId);
    if (!mounted) {
      return;
    }
    setState(() => _attachLoadingId = null);
    await result.fold(
      (f) async => setState(() => _error = failureText(f, '마스터를 불러오지 못했습니다.')),
      (master) async {
        final r = await context.pushNamed<MarketProductAddResult>(
          Routes.masterMarketProductAdd,
          extra: MarketProductAddArgs(
            masterId: masterId,
            sellerId: lookedUp.sellerId,
            platform: lookedUp.platform,
            sellerName: _sellerName,
            masterOptions: master.options,
            initialProductId: lookedUp.platformProductId,
          ),
        );
        if (r != null && mounted) {
          _handleAttached(masterId, r.categoryWarning);
        }
      },
    );
  }

  /// After attaching = toast + that master's detail (UX D75). A category
  /// warning from the commit goes to the detail banner.
  void _handleAttached(int masterId, String? categoryWarning) {
    showSuccessToast(context, '붙였습니다.');
    context.pushNamed(
      Routes.masterProductDetail,
      pathParameters: {'id': '$masterId'},
      extra: MasterDetailArgs(notice: categoryWarning),
    );
  }

  /// [새 마스터로] — the create page; picked products are preselected as
  /// components (UX D79).
  void _goToNewMaster() {
    final lookedUp = _lookedUp;
    if (lookedUp == null) {
      return;
    }
    context.pushNamed(
      Routes.masterProductNew,
      extra: MasterCreateArgs(
        sellerId: lookedUp.sellerId,
        platform: lookedUp.platform,
        platformProductId: lookedUp.platformProductId,
        productIds: _selectedProducts.map((p) => p.id).toList(),
      ),
    );
  }

  /// Changing the platform changes what the identifier means — drop the input
  /// and the previous lookup.
  void _handlePlatformChange(String next) {
    setState(() {
      _platform = next;
      _productIdController.clear();
      _preview = null;
      _lookedUp = null;
      _error = '';
    });
  }

  String get _sellerName {
    final id = _lookedUp?.sellerId;
    for (final s in _sellers) {
      if (s.id == id) {
        return s.sellerName;
      }
    }
    return '';
  }

  void _openMasterDetail(int id) => context.pushNamed(
        Routes.masterProductDetail,
        pathParameters: {'id': '$id'},
        extra: const MasterDetailArgs(),
      );

  Widget _card(String? title, List<Widget> children) => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ...children,
            ],
          ),
      );

  Widget _hint(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );

  Widget _muted(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );

  Widget _smallError(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.error,
        ),
      );

  Widget _boxedList(List<Widget> rows) => ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 192),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: rows,
          ),
        ),
      );

  Widget _productRow(Product p) {
    final checked = _selectedProducts.any((s) => s.id == p.id);
    return CheckboxListTile(
      value: checked,
      onChanged: (_) => _toggleProduct(p),
      title: Text(
        '${p.brand != null && p.brand!.isNotEmpty ? '${p.brand} ' : ''}${p.productName}',
        style: const TextStyle(fontSize: 14),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _masterRows(List<_MasterRow> rows) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          onPressed: () => _openMasterDetail(rows[i].id),
                          child: Text(
                            rows[i].name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          rows[i].componentNames.isNotEmpty
                              ? rows[i].componentNames.join(' + ')
                              : '구성상품 없음',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _attachLoadingId != null
                        ? null
                        : () => unawaited(_openAttach(rows[i].id)),
                    child: _attachLoadingId == rows[i].id
                        ? const AppBusyLabel('여는 중…')
                        : const Text('이 마스터에 붙이기'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _searchRow({
    required TextEditingController controller,
    required String hintText,
    required bool busy,
    required VoidCallback onSearch,
  }) =>
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => onSearch(),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            onPressed: busy || controller.text.trim().isEmpty ? null : onSearch,
            child: busy ? const AppBusyLabel('검색 중…') : const Text('검색'),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = _platformMeta;
    final preview = _preview;
    final lookedUp = _lookedUp;
    final canLookup = _sellerId != null &&
        _productIdController.text.trim().isNotEmpty &&
        !_looking;

    return ScaffoldWithNavBar(
      title: '마켓 상품으로 시작',
      navBarIndex: 2,
      showAppBarDrawerButton: false,
      body: AppPageBody.scroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _card(null, [
              // ① seller · sales channel — two fields (UX D72)
              DropdownButtonFormField<int>(
                initialValue: _sellerId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '판매자'),
                hint: const Text('판매자를 선택하세요'),
                items: [
                  for (final s in _sellers)
                    DropdownMenuItem(value: s.id, child: Text(s.sellerName)),
                ],
                onChanged: _looking
                    ? null
                    : (value) => setState(() => _sellerId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _platform,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '판매채널'),
                items: [
                  for (final p in _platforms)
                    DropdownMenuItem(value: p.$1, child: Text(p.$2)),
                ],
                onChanged: _looking || _platforms.length == 1
                    ? null
                    : (value) {
                        if (value != null) {
                          _handlePlatformChange(value);
                        }
                      },
              ),
              const SizedBox(height: 16),
              // ② product identifier — label / input mode come from the platform
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _productIdController,
                      enabled: !_looking,
                      keyboardType:
                          meta.$4 ? TextInputType.number : TextInputType.text,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(labelText: meta.$3),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => unawaited(_handleLookup()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed:
                        canLookup ? () => unawaited(_handleLookup()) : null,
                    child: _looking
                        ? const AppBusyLabel('조회 중…')
                        : const Text('조회'),
                  ),
                ],
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _error,
                    style: TextStyle(fontSize: 14, color: scheme.error),
                  ),
                ),
              ],
              // UX D81: already attached = notice + [그 마스터로 가기] only.
              for (final m in _linkedMasters) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warningSurface,
                    border: Border.all(color: AppColors.warningBorder),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.warningForeground,
                            ),
                            children: [
                              const TextSpan(text: '이미 '),
                              TextSpan(
                                text: m.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(text: ' 마스터에 연결돼 있습니다.'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _openMasterDetail(m.id),
                        child: const Text('그 마스터로 가기'),
                      ),
                    ],
                  ),
                ),
              ],
              if (preview == null && _error.isEmpty) ...[
                const SizedBox(height: 16),
                _hint(
                  '판매자와 ${meta.$3} 를 넣고 [조회]하면 ${meta.$2}에서 상품을 읽어 옵니다.',
                ),
              ],
            ]),
            if (preview != null && lookedUp != null) ...[
              const SizedBox(height: 16),
              // ③ product info (read only)
              _card('상품 정보', [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 14),
                    children: [
                      TextSpan(
                        text: preview.productName ?? '(이름 없음)',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text:
                            ' · ${_statusLabel[preview.status] ?? preview.status} · 옵션 ${preview.options.length}개',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (preview.reusesExistingListing) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.infoSurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '이 상품에는 마스터 연결이 끊긴 판매상품이 있습니다. 새로 만들지 않고 그 판매상품을 붙입니다 — '
                      '주문·고객문의·정산 기록이 함께 따라옵니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.infoForeground,
                      ),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 16),
              // ④ pick the products inside this product (UX D79)
              _card('이 상품에 든 물품 (${_selectedProducts.length}개 선택)', [
                _hint(
                  '상품명으로 찾은 물품 후보입니다. 이 상품에 들어 있는 물품을 모두 고르세요 — 후보에 없으면 아래에서 '
                  '직접 검색합니다.',
                ),
                const SizedBox(height: 8),
                if (_candidateLoading)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AppBusyLabel('물품 후보를 찾는 중…', gap: 8),
                  )
                else if (_candidates.isEmpty)
                  _muted('상품명으로 찾은 물품 후보가 없습니다.')
                else
                  _boxedList(_candidates.map(_productRow).toList()),
                if (_candidateError.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _smallError(_candidateError),
                ],
                const SizedBox(height: 8),
                _searchRow(
                  controller: _productSearchController,
                  hintText: '물품 이름으로 검색',
                  busy: _productSearching,
                  onSearch: () => unawaited(_handleProductSearch()),
                ),
                if (_productSearchResults != null) ...[
                  const SizedBox(height: 8),
                  if (_productSearchResults!.isEmpty)
                    _muted('검색 결과가 없습니다.')
                  else
                    _boxedList(
                        _productSearchResults!.map(_productRow).toList()),
                ],
              ]),
              const SizedBox(height: 16),
              // ⑤ every master containing at least one picked product (UX D74)
              _card('이 물품이 들어간 마스터', [
                if (_selectedProducts.isEmpty)
                  _muted('물품을 고르면 그 물품이 하나라도 들어간 마스터를 물품 조합과 함께 보여 줍니다.')
                else if (_overlapLoading)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AppBusyLabel('마스터를 찾는 중…', gap: 8),
                  )
                else if (_overlapMasters.isEmpty)
                  _muted('고른 물품이 들어간 마스터가 없습니다.')
                else
                  _masterRows(_overlapMasters),
                if (_overlapError.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _smallError(_overlapError),
                ],
              ]),
              const SizedBox(height: 16),
              // ⑥ new master / attach to an existing master (UX D73)
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        setState(() => _masterSearchOpen = !_masterSearchOpen),
                    child: const Text('기존 마스터에 붙이기'),
                  ),
                  FilledButton(
                    onPressed: _goToNewMaster,
                    child: const Text('새 마스터로'),
                  ),
                ],
              ),
              // ⑦ master name search (UX D75)
              if (_masterSearchOpen) ...[
                const SizedBox(height: 16),
                _card('마스터 찾기', [
                  _searchRow(
                    controller: _masterSearchController,
                    hintText: '마스터 이름 · 상품 ID · 옵션 ID',
                    busy: _masterSearching,
                    onSearch: () => unawaited(_handleMasterSearch()),
                  ),
                  if (_masterSearchError.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _smallError(_masterSearchError),
                  ],
                  if (_masterSearchResults != null) ...[
                    const SizedBox(height: 8),
                    if (_masterSearchResults!.isEmpty)
                      _muted('검색 결과가 없습니다.')
                    else
                      _masterRows(_masterSearchResults!),
                  ],
                ]),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
