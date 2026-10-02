import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/entities/carrier_rate.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/usecases/get_carrier_rates_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/category_meta_validation.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/market_source.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/master_format.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/master_image_commit.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/master_image_fields.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/shipping_override.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_route_args.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/category_meta_create_fields.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/category_tree_list.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_image_pool.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_option_editor.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/meta_platform_tabs.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/product_relation_panel.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/shipping_override_fields.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/tag_chips_input.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/get_products_usecase.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/presentation/widgets/product_thumbnail.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';

/// Web local `formatWon`.
String _formatWon(num? v) => v == null ? '—' : '${koNumber(v)}원';

// Cap of category name-search results (client filter over the full list).
const int _categorySearchLimit = 50;

// Cap of component search results.
const int _productSearchLimit = 50;

/// Web `purchasePlaceNames(product)`.
String _purchasePlaceNames(Product product) =>
    product.purchasePlaces.map((p) => p.name).join(', ');

// Per-platform create-mode meta: user values + the loaded schema (for the
// save gate). Web `MetaEntry`.
class _MetaEntry {
  final List<CategoryAttribute> attributes;
  final List<CategoryNotice> notices;
  final Map<String, String> attrValues;
  final Map<String, String> noticeValues;
  final String? noticeGroup;

  const _MetaEntry({
    this.attributes = const [],
    this.notices = const [],
    this.attrValues = const {},
    this.noticeValues = const {},
    this.noticeGroup,
  });

  CategoryMetaCreateValue get value => CategoryMetaCreateValue(
        attrValues: attrValues,
        noticeValues: noticeValues,
        noticeGroup: noticeGroup,
      );

  _MetaEntry withValue(CategoryMetaCreateValue v) => _MetaEntry(
        attributes: attributes,
        notices: notices,
        attrValues: v.attrValues,
        noticeValues: v.noticeValues,
        noticeGroup: v.noticeGroup,
      );

  _MetaEntry withSchema(
    List<CategoryAttribute> attrs,
    List<CategoryNotice> notes,
  ) =>
      _MetaEntry(
        attributes: attrs,
        notices: notes,
        attrValues: attrValues,
        noticeValues: noticeValues,
        noticeGroup: noticeGroup,
      );
}

// One category name-search result with its ancestor breadcrumb.
class _CategoryResult {
  final StandardCategory cat;
  final String path;

  const _CategoryResult({required this.cat, required this.path});
}

/// Master **create-only** form of the create page (FEATURE_2609_80 / 10) —
/// port of web `master-products/new/components/MasterProductCreateForm.tsx`
/// (@09208a0).
///
/// **File**: lib/features/master_product/presentation/widgets/master_create_form.dart
///
/// Components come first: the component set is the master's identity, so
/// every other input stays locked until the set is applied and confirmed not
/// to be a duplicate. Saving creates the master with its options atomically,
/// then applies category → category meta → shipping → tags → image buffer →
/// (market mode) listing attach, in the web order with the web texts. A
/// follow-up failure hands over to [onCreatedWithWarning] (the master already
/// exists — the detail page tells what to fill in).
///
/// [overviewOpen] = on mobile the product-relation 「물품」 section is showing:
/// the product panel is drawn (and kept mounted once opened — R9) and the
/// form body is offstage. The form itself is always mounted, so toggling the
/// overview keeps every input.
///
/// [initialProductIds] = products to preselect (read once in initState).
/// [market] = market "new master" mode (UX D70 · D71 · D77) — read as the
/// initial value only; the page mounts the form after the lookup finished.
///
/// **Usage**:
/// ```dart
/// MasterCreateForm(
///   initialProductIds: const [],
///   overviewOpen: false,
///   onCreated: _handleCreated,
///   onCreatedWithWarning: _handleCreatedWithWarning,
///   onCancel: () => context.go(Routes.masterProductsPath),
/// )
/// ```
///
/// ⚠️ Editing is never done here — every value is edited on the master detail
///    page (single edit point). Do not add an edit branch.
/// ❌ No sales-channel section before saving (D69).
class MasterCreateForm extends StatefulWidget {
  final List<int> initialProductIds;
  final bool overviewOpen;
  final void Function(int masterId) onCreated;
  final void Function(int masterId, String warning) onCreatedWithWarning;
  final VoidCallback onCancel;
  final MarketSource? market;

  const MasterCreateForm({
    required this.initialProductIds,
    required this.overviewOpen,
    required this.onCreated,
    required this.onCreatedWithWarning,
    required this.onCancel,
    super.key,
    this.market,
  });

  @override
  State<MasterCreateForm> createState() => _MasterCreateFormState();
}

class _MasterCreateFormState extends State<MasterCreateForm> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  // Market mode option template (name = market option, quantities empty).
  // Discarding options returns to this.
  List<MasterOptionRequest>? _marketOptions;

  final TextEditingController _nameController = TextEditingController();
  List<int> _selectedIds = [];

  List<MasterOptionRequest> _options = [];
  // True while the option add/edit form is open → components are locked.
  bool _optionFormOpen = false;

  // ---- Category ----
  int? _selectedCategoryId;
  String _selectedCategoryName = '';
  final TextEditingController _catSearchController = TextEditingController();
  List<_CategoryResult> _catResults = [];
  bool _catSearching = false;
  bool _catHasSearched = false;
  int _catTotalMatches = 0;
  List<int>? _catExpandChain;
  // Once applied the category is frozen until 수정 is pressed.
  bool _categoryLocked = false;
  List<StandardCategory>? _allCategories;

  // Form-level error banner.
  String _error = '';

  Map<String, _MetaEntry> _metaByPlatform = {};

  // ---- Images ----
  List<ImageField> _imageFields = [];
  List<ImageFieldFilter> _imageFieldFilters = [];
  List<String> _requiredZoneKeys = [];
  MasterImageBuffer _imageBuffer = const MasterImageBuffer();

  // Default carrier/box (required on create).
  int? _defaultDeliveryId;
  int? _defaultPackageId;

  List<TemplateField> _fields = [];
  final Map<String, TextEditingController> _fieldControllers = {};

  List<String> _tags = [];
  ShippingSettings _shippingOverride = kEmptyShippingOverride;

  // ---- Components ----
  List<Product> _products = [];
  List<CarrierRate> _carrierRates = [];
  List<MasterBox> _packages = [];
  final TextEditingController _productSearchController =
      TextEditingController();
  String _productQuery = '';
  bool _productHasSearched = false;
  bool _componentsLocked = false;
  List<MasterByComponents> _duplicateMasters = [];
  bool _checkingComponents = false;
  String _componentsError = '';
  bool _isSubmitting = false;

  // A product panel once opened stays mounted (R9).
  bool _panelMounted = false;

  bool get _isMarket => widget.market != null;

  @override
  void initState() {
    super.initState();
    final market = widget.market;
    if (market != null) {
      final preview = market.preview;
      _marketOptions = marketOptionsOf(preview);
      _options = [..._marketOptions!];
      _nameController.text =
          preview.suggestedMasterName ?? preview.productName ?? '';
      // UX D77: a resolved market category is filled and already applied.
      final suggested = preview.suggestedCategoryId;
      if (preview.categoryResolved && suggested != null) {
        _selectedCategoryId = suggested;
        _selectedCategoryName = preview.suggestedCategoryName ?? '';
        _categoryLocked = true;
      }
      _metaByPlatform = {
        market.platform: _MetaEntry(
          attrValues: {...preview.commonAttributes},
          noticeValues: {...preview.notices},
          noticeGroup: preview.noticeGroup,
        ),
      };
    }
    _panelMounted = widget.overviewOpen;
    _nameController.addListener(_onTextChanged);
    _catSearchController.addListener(_onTextChanged);
    _productSearchController.addListener(_onTextChanged);
    unawaited(_loadCandidates());
    unawaited(_loadImageFields());
  }

  @override
  void didUpdateWidget(covariant MasterCreateForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.overviewOpen) {
      _panelMounted = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _catSearchController.dispose();
    _productSearchController.dispose();
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  // ---------------------------------------------------------------- loading

  Future<void> _loadCandidates() async {
    final productsFuture = getIt<GetProductsUseCase>()(
      const GetProductsParams(page: 0, size: 1000),
    );
    final ratesFuture = getIt<GetCarrierRatesUseCase>()();
    // 🔴 Box candidates for price calculation = purchased boxes only (a
    // recycled box costs 0 and would compute a price from a 0 cost).
    final boxesFuture = _useCase.getPurchasedBoxes();
    await Future.wait<Object>([productsFuture, ratesFuture, boxesFuture]);
    final prod = (await productsFuture).fold((_) => null, (p) => p);
    final rates = (await ratesFuture).fold((_) => null, (r) => r);
    final boxes = (await boxesFuture).fold((_) => null, (b) => b);
    if (!mounted) {
      return;
    }
    if (prod == null || rates == null || boxes == null) {
      setState(() => _error = '구성상품·택배/박스 후보를 불러오지 못했습니다.');
    } else {
      // Products preselected from outside may lie outside the first 1000 —
      // only the missing ones are fetched one by one and put in front.
      var productList = prod.content;
      final wanted = widget.initialProductIds;
      final missing =
          wanted.where((id) => !productList.any((p) => p.id == id)).toList();
      if (missing.isNotEmpty) {
        final detailUseCase = getIt<GetProductDetailUseCase>();
        final fetched = await Future.wait(
          missing.map((id) async {
            final result = await detailUseCase(GetProductDetailParams(id));
            return result.fold((_) => null, (p) => p);
          }),
        );
        if (!mounted) {
          return;
        }
        // Products that could not be fetched are not preselected.
        productList = [...fetched.whereType<Product>(), ...productList];
      }
      final preselected =
          wanted.where((id) => productList.any((p) => p.id == id)).toList();
      final defaultRate = rates.where((r) => r.isDefault);
      final defaultBox = boxes.where((b) => b.isDefault);
      setState(() {
        _products = productList;
        if (preselected.isNotEmpty) {
          _selectedIds = preselected;
        }
        _carrierRates = rates;
        _packages = boxes;
        // Preselect the isDefault entries; otherwise leave unselected (never
        // pick the first entry arbitrarily).
        _defaultDeliveryId = defaultRate.isEmpty ? null : defaultRate.first.id;
        _defaultPackageId = defaultBox.isEmpty ? null : defaultBox.first.id;
      });
    }
    // Template fields are a secondary input — a failure never blocks.
    final templates = await _useCase.listThumbnailTemplates();
    if (!mounted) {
      return;
    }
    final fields = templates.fold((_) => <TemplateField>[], (list) {
      final defaults = list.where((t) => t.isDefault);
      return defaults.isEmpty ? <TemplateField>[] : defaults.first.fields;
    });
    setState(() {
      _fields = fields;
      for (final f in fields) {
        _fieldControllers.putIfAbsent(f.key, TextEditingController.new);
      }
    });
  }

  Future<void> _loadImageFields() async {
    final derived = await deriveMasterImageFields();
    if (!mounted) {
      return;
    }
    setState(() {
      _imageFields = derived.fields;
      _imageFieldFilters = derived.fieldFilters;
      _requiredZoneKeys = derived.requiredZoneKeys;
    });
  }

  // ---------------------------------------------------------------- options

  // Web `discardOptions`: plain = remove all, market = back to the template.
  void _discardOptions() => _options = [...?_marketOptions];

  // Is there input that would be discarded? Market options exist from the
  // start, so only options with quantities count there.
  bool get _hasOptionInput => _marketOptions != null
      ? _options.any((o) => o.items.isNotEmpty)
      : _options.isNotEmpty;

  // Web `setConfirmDialog({ message, onConfirm })`.
  Future<void> _confirmDiscard(String message, VoidCallback onConfirm) async {
    final ok = await showAppConfirmDialog(
      context,
      title: _isMarket ? '구성 수량 지우기 확인' : '옵션 삭제 확인',
      message: message,
      confirmText: _isMarket ? '지우고 계속' : '삭제하고 계속',
      isDangerous: true,
    );
    if (ok && mounted) {
      setState(onConfirm);
    }
  }

  // ---------------------------------------------------------------- category

  // Stable method tear-off so CategoryTreeList does not reload every build.
  Future<List<CategoryTreeNode>> _browseTree(int? parentId) async {
    final result = await _useCase.browseCategoryTree(parentId: parentId);
    return result.fold(
      // CategoryTreeList contract: throw the Failure to show its message.
      // ignore: only_throw_errors
      (failure) => throw failure,
      (nodes) => nodes,
    );
  }

  Future<void> _runCategorySearch(String query) async {
    setState(() => _catSearching = true);
    final cached = _allCategories;
    final List<StandardCategory> all;
    if (cached != null) {
      all = cached;
    } else {
      final result = await _useCase.getStandardCategories();
      if (!mounted) {
        return;
      }
      final failure = result.fold((f) => f, (_) => null);
      if (failure != null) {
        setState(() {
          _error = failureText(failure, '카테고리 검색에 실패했습니다.');
          _catResults = [];
          _catTotalMatches = 0;
          _catSearching = false;
        });
        return;
      }
      all = result.fold((_) => <StandardCategory>[], (list) => list);
      _allCategories = all;
    }
    // Ancestor breadcrumb built from the cached list (climb parentId).
    final byId = {for (final c in all) c.id: c};
    String pathOf(StandardCategory c) {
      final names = <String>[];
      StandardCategory? cur = c;
      var guard = 0;
      while (cur != null && guard < 20) {
        names.insert(0, cur.name);
        final parentId = cur.parentId;
        cur = parentId != null ? byId[parentId] : null;
        guard += 1;
      }
      return names.join(' > ');
    }

    final lower = query.trim().toLowerCase();
    final filtered =
        all.where((c) => c.name.toLowerCase().contains(lower)).toList();
    setState(() {
      _catResults = [
        for (final c in filtered.take(_categorySearchLimit))
          _CategoryResult(cat: c, path: pathOf(c)),
      ];
      _catTotalMatches = filtered.length;
      _catHasSearched = true;
      _catSearching = false;
    });
  }

  void _handleCategorySearch() {
    final query = _catSearchController.text;
    if (query.trim().isEmpty) {
      return;
    }
    unawaited(_runCategorySearch(query));
  }

  // Climb parentId to build the root→…→target chain (drives expandTo).
  Future<List<int>> _buildCategoryChain(StandardCategory cat) async {
    final ids = [cat.id];
    var pid = cat.parentId;
    var guard = 0;
    while (pid != null && guard < 20) {
      ids.insert(0, pid);
      final result = await _useCase.getStandardCategory(pid);
      final parent = result.fold(
        // ignore: only_throw_errors
        (failure) => throw failure,
        (c) => c,
      );
      pid = parent.parentId;
      guard += 1;
    }
    return ids;
  }

  // Select a category; a change discards existing options.
  void _chooseCategory(int id, String name) {
    void doSelect() {
      _selectedCategoryId = id;
      _selectedCategoryName = name;
    }

    if (_selectedCategoryId != id && _hasOptionInput) {
      unawaited(_confirmDiscard(
        _isMarket
            ? kMarketOptionResetMessage
            : '카테고리를 변경할 경우 기존에 추가한 옵션을 제거됩니다. 계속하시겠습니까?',
        () {
          _discardOptions();
          doSelect();
        },
      ));
      return;
    }
    setState(doSelect);
  }

  // Apply the picked category: clear the search UI and freeze the section.
  void _applyCategory() {
    setState(() {
      _catSearchController.clear();
      _catResults = [];
      _catHasSearched = false;
      _catTotalMatches = 0;
      _categoryLocked = true;
    });
  }

  // Unlock the category; if options exist, confirm they will be discarded.
  void _editCategory() {
    if (_hasOptionInput) {
      unawaited(_confirmDiscard(
        _isMarket
            ? kMarketOptionResetMessage
            : '카테고리를 수정할 경우 기존에 추가한 옵션을 제거됩니다. 계속하시겠습니까?',
        () {
          _discardOptions();
          _categoryLocked = false;
        },
      ));
      return;
    }
    setState(() => _categoryLocked = false);
  }

  // Re-expand the tree to the currently selected category.
  Future<void> _revealSelectedCategory() async {
    final selected = _selectedCategoryId;
    if (selected == null) {
      return;
    }
    try {
      final result = await _useCase.getStandardCategory(selected);
      final cat = result.fold(
        // ignore: only_throw_errors
        (failure) => throw failure,
        (c) => c,
      );
      final chain = await _buildCategoryChain(cat);
      if (mounted) {
        setState(() => _catExpandChain = chain);
      }
    } on Failure catch (f) {
      if (mounted) {
        setState(() => _error = failureText(f, '카테고리를 여는 데 실패했습니다.'));
      }
    }
  }

  // Pick a search result: expand the tree to it; a leaf is selected directly.
  Future<void> _handleSelectCategoryResult(StandardCategory cat) async {
    try {
      final chain = await _buildCategoryChain(cat);
      if (!mounted) {
        return;
      }
      setState(() => _catExpandChain = chain);
      final siblings = await _browseTree(cat.parentId);
      if (!mounted) {
        return;
      }
      final match = siblings.where((n) => n.id == cat.id);
      if (match.isNotEmpty && match.first.leaf) {
        _chooseCategory(cat.id, cat.name);
      }
    } on Failure catch (f) {
      if (mounted) {
        setState(() => _error = failureText(f, '카테고리를 여는 데 실패했습니다.'));
      }
    }
  }

  // ---------------------------------------------------------------- meta

  void _handleMetaChange(String platform, CategoryMetaCreateValue next) {
    setState(() {
      _metaByPlatform = {
        ..._metaByPlatform,
        platform:
            (_metaByPlatform[platform] ?? const _MetaEntry()).withValue(next),
      };
    });
  }

  void _handleMetaSchemaLoad(
    String platform,
    List<CategoryAttribute> attributes,
    List<CategoryNotice> notices,
  ) {
    setState(() {
      _metaByPlatform = {
        ..._metaByPlatform,
        platform: (_metaByPlatform[platform] ?? const _MetaEntry())
            .withSchema(attributes, notices),
      };
    });
  }

  // ---------------------------------------------------------------- components

  /// Applies the component set (2609_46). A master with the same set blocks
  /// instead of locking; a lookup failure does not lock either.
  Future<void> _applyComponents() async {
    if (_selectedIds.isEmpty) {
      return;
    }
    setState(() {
      _componentsError = '';
      _duplicateMasters = [];
      _checkingComponents = true;
    });
    final result = await _useCase.findByComponents(_selectedIds);
    if (!mounted) {
      return;
    }
    setState(() {
      result.fold(
        (f) => _componentsError = failureText(
          f,
          '같은 구성상품의 마스터가 있는지 확인하지 못했습니다. 다시 시도하세요.',
        ),
        (existing) {
          if (existing.isNotEmpty) {
            _duplicateMasters = existing;
            return;
          }
          _productSearchController.clear();
          _productQuery = '';
          _productHasSearched = false;
          _componentsLocked = true;
        },
      );
      _checkingComponents = false;
    });
  }

  // Unlocking returns the rest of the form to disabled (the duplicate check
  // is no longer valid). Callers wrap it in setState.
  void _unlockComponents() {
    _componentsLocked = false;
    _duplicateMasters = [];
    _componentsError = '';
  }

  void _editComponents() {
    if (_hasOptionInput) {
      unawaited(_confirmDiscard(
        _isMarket
            ? kMarketOptionResetMessage
            : '구성상품을 수정할 경우 기존에 추가한 옵션을 제거됩니다. 계속하시겠습니까?',
        () {
          _discardOptions();
          _unlockComponents();
        },
      ));
      return;
    }
    setState(_unlockComponents);
  }

  void _toggleProduct(int id) {
    // Locked while an option is being edited, or after the set was applied.
    if (_optionFormOpen || _componentsLocked) {
      return;
    }
    void doToggle() {
      // A changed set invalidates the previous duplicate check.
      _duplicateMasters = [];
      _componentsError = '';
      _selectedIds = _selectedIds.contains(id)
          ? _selectedIds.where((x) => x != id).toList()
          : [..._selectedIds, id];
    }

    if (_hasOptionInput) {
      unawaited(_confirmDiscard(
        _isMarket
            ? kMarketOptionResetMessage
            : '구성상품을 변경할 경우 기존에 추가한 옵션을 제거됩니다. 계속하시겠습니까?',
        () {
          _discardOptions();
          doToggle();
        },
      ));
      return;
    }
    setState(doToggle);
  }

  /// Product panel "구성상품에 넣기" (2609_78 / UX D67). A locked set is
  /// unlocked first (a changed set needs a new duplicate check).
  void _addComponent(Product product) {
    if (_optionFormOpen || _selectedIds.contains(product.id)) {
      return;
    }
    void doAdd() {
      // Products outside the first 1000 get a name in the list and the
      // option quantity rows too.
      if (!_products.any((p) => p.id == product.id)) {
        _products = [product, ..._products];
      }
      _unlockComponents();
      if (!_selectedIds.contains(product.id)) {
        _selectedIds = [..._selectedIds, product.id];
      }
    }

    if (_hasOptionInput) {
      unawaited(_confirmDiscard(
        _isMarket
            ? kMarketOptionResetMessage
            : '구성상품을 변경할 경우 기존에 추가한 옵션을 제거됩니다. 계속하시겠습니까?',
        () {
          _discardOptions();
          doAdd();
        },
      ));
      return;
    }
    setState(doAdd);
  }

  void _handleProductSearch() {
    final filter = _productSearchController.text;
    if (filter.trim().isEmpty) {
      return;
    }
    setState(() {
      _productQuery = filter;
      _productHasSearched = true;
    });
  }

  List<Product> get _filteredProducts {
    final q = _productQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return _products;
    }
    return _products
        .where((p) => p.productName.toLowerCase().contains(q))
        .toList();
  }

  // Search results = matches excluding already-selected products.
  List<Product> get _searchMatches {
    final selected = _selectedIds.toSet();
    return _filteredProducts.where((p) => !selected.contains(p.id)).toList();
  }

  List<Product> get _selectedProducts => [
        for (final id in _selectedIds)
          ..._products.where((p) => p.id == id).take(1),
      ];

  // Master defaults feed the option editor's carrier/box prefill.
  MasterDefaults get _masterDefaults => MasterDefaults(
        deliveryId: _defaultDeliveryId,
        packageId: _defaultPackageId,
      );

  // Bundle = component kinds ≥ 2 (backend 63). Today Coupang only.
  bool get _hideCategoryAttrs => _selectedIds.length >= 2;

  String? get _masterNoticeGroup {
    final entry = _metaByPlatform['COUPANG'];
    return entry == null
        ? null
        : submitNoticeGroup(
            entry.notices,
            entry.noticeValues,
            entry.noticeGroup,
          );
  }

  /// Save block reason = every required item checked in save order, **first**
  /// missing one only (S4). handleSubmit blocks with the same value.
  String? get _saveBlockReason {
    String? missingZoneKey;
    for (final zoneKey in _requiredZoneKeys) {
      final count = (_imageBuffer.assignments[zoneKey]?.length ?? 0) +
          (_imageBuffer.productAssignments[zoneKey]?.length ?? 0);
      if (count < 1) {
        missingZoneKey = zoneKey;
        break;
      }
    }
    // S7: the zone name shown as the image field title, not the zone code.
    String? missingZoneLabel;
    if (missingZoneKey != null) {
      final field = _imageFields.where((f) => f.key == missingZoneKey);
      missingZoneLabel = field.isEmpty ? missingZoneKey : field.first.label;
    }
    final gate = _metaByPlatform['COUPANG'];
    if (!_componentsLocked) {
      return '구성상품을 먼저 선택하고 [설정 적용]을 누르세요.';
    }
    if (_nameController.text.trim().isEmpty) {
      return '이름을 입력하세요.';
    }
    if (_selectedCategoryId == null) {
      return '세부 카테고리를 선택하세요.';
    }
    if (computeMissingRequired(
      gate?.attributes ?? const [],
      gate?.attrValues ?? const {},
      gate?.notices ?? const [],
      gate?.noticeValues ?? const {},
      _hideCategoryAttrs,
      gate?.noticeGroup,
    )) {
      return '필수 카테고리 속성을 입력하세요.';
    }
    if (_options.isEmpty) {
      return '저장하려면 옵션을 1개 이상 추가하세요.';
    }
    if (_options.any((o) => o.name.trim().isEmpty)) {
      return '옵션 이름을 입력하세요.';
    }
    if (_options.any((o) => o.items.isEmpty)) {
      return '각 옵션에 구성상품 수량을 입력하세요.';
    }
    if (_defaultDeliveryId == null || _defaultPackageId == null) {
      return '기본 택배비와 기본 상자비를 선택하세요.';
    }
    if (missingZoneLabel != null) {
      return '상세 이미지($missingZoneLabel)를 1장 이상 넣어 주세요.';
    }
    return null;
  }

  List<SourceProduct> get _sourceProducts => [
        for (final p in _selectedProducts)
          SourceProduct(id: p.id, name: p.productName),
      ];

  // The option editor renders a quantity row per selected component.
  // netContent/netContentUnit derive the per-unit measure of options (101).
  List<MasterComponent> get _createComponents => [
        for (final id in _selectedIds) _componentOf(id),
      ];

  MasterComponent _componentOf(int id) {
    final match = _products.where((x) => x.id == id);
    final p = match.isEmpty ? null : match.first;
    return MasterComponent(
      productId: id,
      productName: p?.productName ?? '#$id',
      netContent: p?.netContent,
      netContentUnit: p?.netContentUnit,
    );
  }

  // ---------------------------------------------------------------- submit

  void _finishSubmit() {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _error = '');
    // The button is already disabled; block a stray save with the same reason.
    final reason = _saveBlockReason;
    if (reason != null) {
      setState(() => _error = reason);
      return;
    }
    setState(() => _isSubmitting = true);
    // Blank values are omitted so the backend falls back to defaults.
    final cleaned = <String, String>{};
    _fieldControllers.forEach((k, c) {
      if (c.text.trim().isNotEmpty) {
        cleaned[k] = c.text;
      }
    });
    final market = widget.market;
    // UX D70: in market mode a stop before attaching says so in the banner.
    void warnBeforeAttach(int masterId, String warning) =>
        widget.onCreatedWithWarning(
          masterId,
          market != null ? '$warning$kMarketNotAttachedSuffix' : warning,
        );

    final createdResult = await _useCase.createMaster(MasterProductRequest(
      name: _nameController.text.trim(),
      componentProductIds: _selectedIds,
      fieldValues: cleaned.isNotEmpty ? cleaned : null,
      defaultDeliveryId: _defaultDeliveryId,
      defaultPackageId: _defaultPackageId,
      options: _options,
    ));
    if (!mounted) {
      return;
    }
    final createFailure = createdResult.fold((f) => f, (_) => null);
    if (createFailure != null) {
      // Server reason as is (same components exist · options miss components).
      setState(() {
        _error = failureText(createFailure, '저장에 실패했습니다.');
        _isSubmitting = false;
      });
      return;
    }
    final createdId = createdResult.fold((_) => 0, (m) => m.id);

    // Category right after create (validation guarantees a value).
    final categoryResult =
        await _useCase.setMasterCategory(createdId, _selectedCategoryId!);
    if (!mounted) {
      return;
    }
    if (categoryResult.isLeft()) {
      _finishSubmit();
      warnBeforeAttach(createdId, '마스터는 생성되었습니다. 카테고리 지정에 실패했습니다(상세에서 재지정).');
      return;
    }

    // Category required attributes / notices (COUPANG values only).
    final coupangMeta = _metaByPlatform['COUPANG'];
    if (coupangMeta != null) {
      // Same rule as the detail panel: one effective group for values + group.
      final group = submitNoticeGroup(
        coupangMeta.notices,
        coupangMeta.noticeValues,
        coupangMeta.noticeGroup,
      );
      final metaResult = await _useCase.setCategoryAttributes(
        createdId,
        CategoryAttributesRequest(
          attributes: coupangMeta.attrValues,
          notices: noticesToSubmit(
            coupangMeta.notices,
            coupangMeta.noticeValues,
            group,
          ),
          noticeGroup: group,
        ),
      );
      if (!mounted) {
        return;
      }
      if (metaResult.isLeft()) {
        _finishSubmit();
        warnBeforeAttach(
            createdId, '마스터는 생성되었습니다. 카테고리 속성 저장에 실패했습니다(상세에서 재입력).');
        return;
      }
    }

    // Shipping for all channels — same PATCH as the detail panel.
    final shippingMap = overrideToMap(_shippingOverride);
    if (shippingMap.isNotEmpty) {
      final shippingResult =
          await _useCase.updateMasterShippingOverride(createdId, shippingMap);
      if (!mounted) {
        return;
      }
      if (shippingResult.isLeft()) {
        _finishSubmit();
        warnBeforeAttach(
            createdId, '마스터는 생성되었습니다. 배송 설정 저장에 실패했습니다(상세에서 재지정).');
        return;
      }
    }

    // Web does not catch this one — a failure is the generic save error.
    if (_tags.isNotEmpty) {
      final tagsResult = await _useCase.updateMasterTags(createdId, _tags);
      if (!mounted) {
        return;
      }
      final tagsFailure = tagsResult.fold((f) => f, (_) => null);
      if (tagsFailure != null) {
        setState(() {
          _error = failureText(tagsFailure, '저장에 실패했습니다.');
          _isSubmitting = false;
        });
        return;
      }
    }

    // Buffer → master (upload order and mapping rules live in the helper).
    final imageFailure = await commitMasterImageBuffer(createdId, _imageBuffer);
    if (!mounted) {
      return;
    }
    if (imageFailure != null) {
      _finishSubmit();
      warnBeforeAttach(createdId, '마스터·옵션은 생성되었습니다. 이미지 일부 업로드/매핑에 실패했습니다.');
      return;
    }

    // UX D70: attach the listing after the master is complete (photos
    // included — attaching runs auto-generation). A failure keeps the master.
    if (market != null) {
      final attached = await _useCase.importListing(
        createdId,
        sellerId: market.sellerId,
        platform: market.platform,
        platformProductId: market.platformProductId,
        options: importOptionsOf(market.preview, _options),
      );
      if (!mounted) {
        return;
      }
      final attachFailure = attached.fold((f) => f, (_) => null);
      if (attachFailure != null) {
        _finishSubmit();
        widget.onCreatedWithWarning(
          createdId,
          '$kMarketAttachFailPrefix${failureText(attachFailure, '알 수 없는 오류')}'
          ' — 판매채널 줄의 [마켓 상품 추가하기]로 다시 붙이세요.',
        );
        return;
      }
      final categoryWarning =
          attached.fold((_) => null, (r) => r.categoryWarning);
      if (categoryWarning != null) {
        _finishSubmit();
        widget.onCreatedWithWarning(createdId, categoryWarning);
        return;
      }
    }
    _finishSubmit();
    widget.onCreated(createdId);
  }

  Future<void> _handleCancel() async {
    final hasInput =
        _nameController.text.trim().isNotEmpty || _selectedIds.isNotEmpty;
    if (!hasInput) {
      widget.onCancel();
      return;
    }
    final ok = await showAppConfirmDialog(
      context,
      title: '작성 취소',
      message: '작성 중인 내용이 저장되지 않고 사라집니다. 나가시겠습니까?',
      confirmText: '나가기',
      cancelText: '계속 작성',
      isDangerous: true,
    );
    if (ok && mounted) {
      widget.onCancel();
    }
  }

  void _openProductDetail(Product product) {
    unawaited(showAppSheet<void>(
      context,
      builder: (sheetContext) => _ProductDetailSheet(product: product),
    ));
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_panelMounted)
            Offstage(
              key: const ValueKey('create-products-panel'),
              offstage: !widget.overviewOpen,
              child: ProductRelationPanel(
                mode: 'create',
                componentIds: _selectedIds,
                onAddComponent: _addComponent,
                addBlockedReason: _optionFormOpen
                    ? '옵션을 추가하는 동안에는 구성상품을 넣을 수 없습니다. 옵션 편집을 닫은 뒤 넣으세요.'
                    : null,
              ),
            ),
          Offstage(
            key: const ValueKey('create-form'),
            offstage: widget.overviewOpen,
            child: AppCard(
              child: _buildFormBody(context),
            ),
          ),
        ],
      );

  Widget _buildFormBody(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reason = _saveBlockReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error.isNotEmpty) ...[
          _Banner(
            text: _error,
            background: scheme.errorContainer,
            foreground: scheme.error,
          ),
          const SizedBox(height: 16),
        ],
        _buildComponents(context),
        const SizedBox(height: 16),
        // Until the component set is applied every other input is locked.
        IgnorePointer(
          ignoring: !_componentsLocked,
          child: Opacity(
            opacity: _componentsLocked ? 1 : 0.6,
            child: _buildLockedBody(context),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(height: 1),
        const SizedBox(height: 24),
        if (reason != null) ...[
          Text(
            reason,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.warningForeground,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _isSubmitting ? null : _handleCancel,
              child: const Text('취소'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: reason != null || _isSubmitting ? null : _handleSubmit,
              child: Text(_isSubmitting ? '저장 중...' : '저장'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComponents(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final matches = _searchMatches;
    final results = matches.take(_productSearchLimit).toList();
    final selectedProducts = _selectedProducts;
    final muted = TextStyle(fontSize: 11, color: scheme.onSurfaceVariant);
    final searchEnabled = !(_optionFormOpen || _componentsLocked);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel('구성상품 (${_selectedIds.length}개 선택)'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _productSearchController,
                enabled: searchEnabled,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _handleProductSearch(),
                decoration: const InputDecoration(
                  hintText: '상품명으로 검색',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              onPressed: searchEnabled &&
                      _productSearchController.text.trim().isNotEmpty
                  ? _handleProductSearch
                  : null,
              child: const Text('검색'),
            ),
            const SizedBox(width: 8),
            if (_componentsLocked)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _editComponents,
                child: const Text('수정'),
              )
            else
              FilledButton(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
                onPressed: _optionFormOpen ||
                        _selectedIds.isEmpty ||
                        _checkingComponents
                    ? null
                    : () => unawaited(_applyComponents()),
                child: _checkingComponents
                    ? const AppBusyLabel('확인 중...')
                    : const Text('설정적용'),
              ),
          ],
        ),
        if (!_componentsLocked && _productHasSearched) ...[
          const SizedBox(height: 8),
          _BorderBox(
            child: results.isEmpty
                ? Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      '검색 결과가 없습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < results.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        // Row tap adds the product.
                        InkWell(
                          onTap: _optionFormOpen
                              ? null
                              : () => _toggleProduct(results[i].id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                ProductThumbnail(
                                  productId: results[i].id,
                                  size: 40,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        results[i].productName,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        '${_brandOf(results[i])} · '
                                        '${_formatWon(results[i].price)}',
                                        style: muted,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (matches.length > results.length) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            '${matches.length}개 중 ${results.length}개 표시'
                            ' — 더 구체적으로 검색하세요.',
                            style: muted,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '검색 결과에서 선택하면 아래 목록에 추가됩니다. 제품명을 클릭하면 상세 정보를 볼 수 있습니다.',
          style: muted,
        ),
        if (_optionFormOpen) ...[
          const SizedBox(height: 4),
          const Text(
            '옵션을 추가하는 동안에는 구성상품을 수정할 수 없습니다. 옵션 편집을 닫은 뒤 수정하세요.',
            style: TextStyle(fontSize: 11, color: AppColors.warningForeground),
          ),
        ],
        if (!_optionFormOpen && _hasOptionInput) ...[
          const SizedBox(height: 4),
          Text(
            _isMarket
                ? '구성상품을 수정하면 옵션별 구성 수량이 지워집니다.'
                : '구성상품을 수정하면 기존에 추가한 옵션이 모두 삭제됩니다.',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.warningForeground,
            ),
          ),
        ],
        const SizedBox(height: 8),
        // Selected components — table rows as cards (R7).
        if (selectedProducts.isEmpty)
          Text(
            '선택된 상품이 없습니다.',
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          )
        else
          for (var i = 0; i < selectedProducts.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _componentCard(context, selectedProducts[i]),
          ],
        if (_componentsError.isNotEmpty) ...[
          const SizedBox(height: 8),
          _Banner(
            text: _componentsError,
            background: scheme.errorContainer,
            foreground: scheme.error,
          ),
        ],
        // A master with the same component set already exists → stop here.
        if (_duplicateMasters.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildDuplicates(context),
        ],
        if (!_componentsLocked && _duplicateMasters.isEmpty) ...[
          const SizedBox(height: 8),
          Text('구성상품을 고르고 [설정적용]을 누르면 나머지 항목을 입력할 수 있습니다.', style: muted),
        ],
      ],
    );
  }

  String _brandOf(Product p) {
    final brand = p.brand;
    return brand == null || brand.isEmpty ? '—' : brand;
  }

  Widget _componentCard(BuildContext context, Product p) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 14, color: scheme.onSurfaceVariant);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductThumbnail(productId: p.id, size: 40),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => _openProductDetail(p),
                        child: Text(
                          p.productName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      Text('브랜드: ${_brandOf(p)}', style: muted),
                      Text('가격: ${_formatWon(p.price)}', style: muted),
                    ],
                  ),
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.error,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _optionFormOpen || _componentsLocked
                      ? null
                      : () => _toggleProduct(p.id),
                  child: const Text('✕'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDuplicates(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.warningSurface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이 구성상품으로 만든 마스터가 이미 있습니다. 새로 만드는 대신 해당 마스터에 옵션을 '
              '추가하세요.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.warningForeground,
              ),
            ),
            const SizedBox(height: 8),
            for (final m in _duplicateMasters)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => context.pushNamed(
                      Routes.masterProductDetail,
                      pathParameters: {'id': '${m.id}'},
                      extra: const MasterDetailArgs(),
                    ),
                    child: Text(m.name),
                  ),
                  Text(
                    '(옵션 ${m.optionCount}개)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.warningForeground,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            const Text(
              '수량만 다른 상품(예: 1개 / 5개 묶음)은 새 마스터가 아니라 위 마스터의 옵션으로 '
              '만듭니다.',
              style:
                  TextStyle(fontSize: 11, color: AppColors.warningForeground),
            ),
          ],
        ),
      );

  Widget _buildLockedBody(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 11, color: scheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: '마스터 이름 *'),
        ),
        const SizedBox(height: 16),
        _buildCategory(context),
        const SizedBox(height: 16),
        const _FieldLabel('필수속성 / 상품정보제공고시'),
        const SizedBox(height: 8),
        MetaPlatformTabs(
          builder: (platform) => CategoryMetaCreateFields(
            key: ValueKey(platform),
            categoryId: _selectedCategoryId,
            platform: platform,
            value: _metaByPlatform[platform]?.value ?? kEmptyMetaValue,
            onChanged: (next) => _handleMetaChange(platform, next),
            onSchemaLoad: (attrs, notices) =>
                _handleMetaSchemaLoad(platform, attrs, notices),
            hideCategoryAttrs: _hideCategoryAttrs,
          ),
        ),
        if (_fields.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _FieldLabel('템플릿 필드값 (선택)'),
          const SizedBox(height: 8),
          for (final f in _fields) ...[
            TextField(
              controller: _fieldControllers[f.key],
              decoration: InputDecoration(
                labelText: f.label,
                hintText: kBuiltinFieldKeys.contains(f.key)
                    ? '등록상품값 사용'
                    : '템플릿 기본값 사용',
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            '비우면 예약 필드는 등록상품 정보, 커스텀 필드는 템플릿 기본값으로 채워집니다. 채널마다 '
            '다르게 하려면 등록 후 셀의 [필드값 편집]에서 조정하세요.',
            style: muted,
          ),
        ],
        const SizedBox(height: 16),
        const _FieldLabel('태그 (선택)'),
        const SizedBox(height: 8),
        TagChipsInput(
          tags: _tags,
          onChanged: (next) => setState(() => _tags = next),
          disabled: _isSubmitting,
        ),
        const SizedBox(height: 4),
        Text('Enter 또는 콤마로 추가하세요.', style: muted),
        const SizedBox(height: 16),
        const _FieldLabel('이미지 (대표사진 + 상세페이지)'),
        const SizedBox(height: 8),
        MasterImagePool(
          masterId: null,
          fields: _imageFields,
          fieldFilters: _imageFieldFilters,
          buffer: _imageBuffer,
          onBufferChange: (next) => setState(() => _imageBuffer = next),
          sourceProducts: _sourceProducts,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          key: ValueKey('delivery-${_carrierRates.length}'),
          initialValue: _defaultDeliveryId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '기본 택배비 *'),
          items: [
            for (final r in _carrierRates)
              DropdownMenuItem(
                value: r.id,
                child: Text('${r.carrier} ${r.type} · ${_formatWon(r.cost)}'),
              ),
          ],
          onChanged: (v) => setState(() => _defaultDeliveryId = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: ValueKey('package-${_packages.length}'),
          initialValue: _defaultPackageId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '기본 상자비 *'),
          items: [
            for (final p in _packages)
              DropdownMenuItem(
                value: p.id,
                child: Text('${p.type} · ${_formatWon(p.cost)}'),
              ),
          ],
          onChanged: (v) => setState(() => _defaultPackageId = v),
        ),
        const SizedBox(height: 4),
        Text(
          '옵션에서 개별 지정하지 않으면 이 값이 모든 옵션 판매가 계산에 쓰입니다.',
          style: muted,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '배송 설정 (전 채널 공통)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '비우면 판매채널의 기본 배송 설정을 그대로 씁니다. 채워두면 이 마스터의 모든 채널에 '
                '적용되고, 채널마다 다르게 하려면 나중에 [채널 배송 설정]에서 바꿉니다. 출고지·반품지는 '
                '판매채널마다 달라야 해서 여기서 지정하지 않습니다.',
                style: muted,
              ),
              const SizedBox(height: 8),
              ShippingOverrideFields(
                level: ShippingOverrideLevel.master,
                scope: 'common',
                value: _shippingOverride,
                onChanged: (next) => setState(() => _shippingOverride = next),
                platform: 'COUPANG',
                disabled: _isSubmitting,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Divider(height: 1),
        const SizedBox(height: 24),
        MasterOptionEditor(
          components: _createComponents,
          options: _options,
          onOptionsChange: (next) => setState(() => _options = next),
          carrierRates: _carrierRates,
          packages: _packages,
          masterDefaults: _masterDefaults,
          categoryId: _selectedCategoryId,
          masterAttrValues: _metaByPlatform['COUPANG']?.attrValues ?? const {},
          masterNoticeValues:
              _metaByPlatform['COUPANG']?.noticeValues ?? const {},
          masterNoticeGroup: _masterNoticeGroup,
          hideCategoryAttrs: _hideCategoryAttrs,
          onFormOpenChange: (open) => setState(() => _optionFormOpen = open),
          marketLocked: _isMarket,
        ),
      ],
    );
  }

  Widget _buildCategory(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 11, color: scheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel('카테고리 *'),
        const SizedBox(height: 8),
        if (_selectedCategoryId != null) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '선택된 카테고리: '),
                    TextSpan(
                      text: _selectedCategoryName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 14),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => unawaited(_revealSelectedCategory()),
                child: const Text('선택 카테고리로 이동'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        // Name search → a result expands the tree there (a leaf is selected).
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _catSearchController,
                enabled: !_categoryLocked,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _handleCategorySearch(),
                decoration: const InputDecoration(
                  hintText: '카테고리 이름으로 검색',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              onPressed: _categoryLocked ||
                      _catSearching ||
                      _catSearchController.text.trim().isEmpty
                  ? null
                  : _handleCategorySearch,
              child: _catSearching
                  ? const AppBusyLabel('검색 중...')
                  : const Text('검색'),
            ),
            const SizedBox(width: 8),
            if (_categoryLocked)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _editCategory,
                child: const Text('수정'),
              )
            else
              FilledButton(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
                onPressed: _selectedCategoryId == null ? null : _applyCategory,
                child: const Text('설정적용'),
              ),
          ],
        ),
        if (!_categoryLocked && _catHasSearched) ...[
          const SizedBox(height: 8),
          _BorderBox(
            child: _catResults.isEmpty
                ? Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      '검색 결과가 없습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < _catResults.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        InkWell(
                          onTap: () => unawaited(
                            _handleSelectCategoryResult(_catResults[i].cat),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _catResults[i].cat.name,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(_catResults[i].path, style: muted),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_catTotalMatches > _catResults.length) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            '$_catTotalMatches개 중 ${_catResults.length}개 표시'
                            ' — 더 구체적으로 검색하세요.',
                            style: muted,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
        const SizedBox(height: 8),
        // Locked: the tree stays browsable but leaf selection is frozen.
        CategoryTreeList(
          browse: _browseTree,
          selectedId: _selectedCategoryId,
          expandTo: _catExpandChain,
          onSelectLeaf: (leaf, _) {
            if (!_categoryLocked) {
              _chooseCategory(leaf.id, leaf.name);
            }
          },
        ),
        if (!_categoryLocked) ...[
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('카테고리가 없으면 ', style: muted),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => context.pushNamed(Routes.categoryList),
                child: const Text('카테고리 관리', style: TextStyle(fontSize: 11)),
              ),
              Text('에서 추가하세요.', style: muted),
            ],
          ),
        ],
      ],
    );
  }
}

/// Label above an input (R27 ④).
class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 14));
}

/// Bordered, height-capped scroll box (web `max-h-40 overflow-y-auto`).
class _BorderBox extends StatelessWidget {
  final Widget child;

  const _BorderBox({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxHeight: 160),
        decoration: BoxDecoration(
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(4),
        ),
        child: SingleChildScrollView(child: child),
      );
}

class _Banner extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Banner({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text, style: TextStyle(fontSize: 14, color: foreground)),
      );
}

/// Web `상품 상세` modal content (data already loaded — no extra fetch).
class _ProductDetailSheet extends StatelessWidget {
  final Product product;

  const _ProductDetailSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = product.brand;
    final barcode = product.barcodeId;
    final unit = product.netContentUnit;
    final netContent = product.netContent;
    final description = product.description;
    final places = _purchasePlaceNames(product);
    final rows = <(String, String)>[
      ('제품명', product.productName),
      ('브랜드', brand == null || brand.isEmpty ? '—' : brand),
      ('가격', _formatWon(product.price)),
      ('구매처', places.isEmpty ? '—' : places),
      if (barcode != null && barcode.isNotEmpty) ('바코드', barcode),
      if (unit != null && unit.isNotEmpty) ('단위', unit),
      if (netContent != null && netContent.isNotEmpty) ('내용물 양', netContent),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '상품 상세',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: '닫기',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductThumbnail(productId: product.id, size: 96),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].$1,
                          style: TextStyle(
                            fontSize: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            rows[i].$2,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
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
