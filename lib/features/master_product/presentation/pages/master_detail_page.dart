import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/entities/carrier_rate.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/usecases/get_carrier_rates_usecase.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/entities/marketplace_account.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/usecases/get_marketplace_accounts_by_seller_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/category_meta_validation.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/master_image_fields.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_route_args.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_tool_args.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/category_meta_panel.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/channel_option_table.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/channel_preview_sheet.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/detached_listing_picker_sheet.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/listing_detail_panel.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/listing_option_picker_sheet.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/listing_row.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_basic_info_panel.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_category_panel.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_default_cost_panel.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_field_values_panel.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_image_pool.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_option_editor.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_registration_suffix_panel.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_section_bar.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_shipping_override_panel.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_tags_panel.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/product_relation_panel.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/info_bubble_icon.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';

/// Why a channel cannot be created for a seller without outbound/return
/// places (user decision 2026-08-28).
const String _shippingBlockReason =
    '이 판매자의 출고지·반품지가 지정되지 않아 채널을 만들 수 없습니다. 판매채널 관리 > 배송관리에서 출고지·반품지를 먼저 지정하세요.';

// Section keys (PLAN R-f). Edit tabs share the keys of the web
// `MasterSectionTabs`.
const String _secProducts = 'products';
const String _secMaster = 'master';
const String _secChannels = 'channels';
const String _tabBasic = 'basic';
const String _tabImages = 'images';
const String _tabShipping = 'shipping';
const String _tabChannelOptions = 'channelOptions';
const List<String> _tabKeys = [
  _tabBasic,
  _tabImages,
  _tabShipping,
  _tabChannelOptions,
];

/// Sync summary lines (90) — the banner and the confirm dialog share them.
/// Zero items are omitted. `marketChannelOnlyOptions` is not counted.
List<String> _syncSummaryLines(ChannelSyncPreview preview) {
  final t = preview.totals;
  final lines = <String>[];
  if (t.missingOptions > 0) {
    lines.add('채널에 없는 옵션 ${t.missingOptions}');
  }
  if (t.channelOnlyOptions > 0) {
    lines.add('마스터에 없는 옵션 ${t.channelOnlyOptions}');
  }
  if (t.quantityMismatch > 0) {
    lines.add('수량이 다른 옵션 ${t.quantityMismatch}');
  }
  return lines;
}

/// Banner count = sum of option counts (not channel count).
int _syncOptionCount(ChannelSyncPreview preview) =>
    preview.totals.missingOptions +
    preview.totals.channelOnlyOptions +
    preview.totals.quantityMismatch;

/// `{label}: {option, option}` parts of one channel (zero items omitted).
String _channelDiffText(ChannelSyncChannel c) {
  final parts = <String>[];
  if (c.missingOptions.isNotEmpty) {
    parts.add('채널에 없는 옵션: ${c.missingOptions.join(', ')}');
  }
  if (c.channelOnlyOptions.isNotEmpty) {
    parts.add('마스터에 없는 옵션: ${c.channelOnlyOptions.join(', ')}');
  }
  if (c.quantityMismatchOptions.isNotEmpty) {
    parts.add('수량이 다른 옵션: ${c.quantityMismatchOptions.join(', ')}');
  }
  return parts.join(' · ');
}

/// **Every** cell of an account row. 🔴 One account can hold several Coupang
/// pages for the same master — looking at the first cell only hides the
/// second page entirely. Falls back to the legacy first-cell field.
List<MatrixCell> _rowCellsOf(MatrixRow row) {
  final cells = row.cells;
  if (cells != null) {
    return cells;
  }
  final cell = row.cell;
  return cell != null ? [cell] : const [];
}

/// Tag of one cell for window titles. Unsent cells have no market ID.
String _cellTag(MatrixCell cell) => cell.platformProductId ?? '미전송';

/// Stable sort (Dart `List.sort` is not stable; web `Array.sort` is).
List<T> _stableSorted<T>(List<T> items, int Function(T a, T b) compare) {
  final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])]
    ..sort((a, b) {
      final c = compare(a.$2, b.$2);
      return c != 0 ? c : a.$1 - b.$1;
    });
  return [for (final e in indexed) e.$2];
}

/// Cells needing action first (ties keep response order).
List<MatrixCell> _sortedCells(List<MatrixCell> cells) =>
    _stableSorted(cells, (a, b) => cellActionCount(b) - cellActionCount(a));

int _rowActionCount(MatrixRow row) =>
    _rowCellsOf(row).fold(0, (sum, c) => sum + cellActionCount(c));

class _Notice {
  final String text;
  final bool green;

  const _Notice({required this.text, required this.green});
}

class _BatchSummary {
  final String text;
  final bool green;
  final List<String> failures;

  const _BatchSummary({
    required this.text,
    required this.green,
    required this.failures,
  });
}

/// **Master detail** screen (FEATURE_2609_80 / 09 — UX D27 · D54 · D69 ·
/// PLAN R-f).
///
/// **File**: lib/features/master_product/presentation/pages/master_detail_page.dart
/// **Web original**: `master-products/[id]/page.tsx` +
/// `[id]/components/CoverageMatrix.tsx` + `[id]/components/MasterSectionTabs.tsx` @09208a0
///
/// Head buttons · banners · sales channels (account header + listing rows) ·
/// 4 edit tabs · product relation overview. The web's stacked / 3-column
/// layout is shown **one section at a time** through the section button row:
/// - overview off: `판매채널 · 상품 기본 정보 · 이미지 · 배송 설정 · 채널별 옵션 설정`
/// - overview on: `물품 · 마스터 · 판매채널` (마스터 = inner row of the 4 tabs)
///
/// [args] = web `?overview=1` / `?notice=` — read once.
///
/// ⚠️ Sections and tabs once opened stay mounted (`Offstage`) to keep unsaved
///    input (R9). Never swap them with a conditional.
/// ❌ No 3-column grid, sticky head or URL hash (R-f · R10).
class MasterDetailPage extends StatefulWidget {
  final int masterId;
  final MasterDetailArgs args;

  const MasterDetailPage({
    required this.masterId,
    required this.args,
    super.key,
  });

  @override
  State<MasterDetailPage> createState() => _MasterDetailPageState();
}

class _MasterDetailPageState extends State<MasterDetailPage> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  ListingMatrix? _matrix;
  MasterProduct? _master;
  List<CarrierRate> _carrierRates = [];
  List<MasterBox> _packages = [];
  List<MasterOption> _options = [];
  MasterCategory? _category;
  // Guards against stale category-meta responses.
  int _metaRequest = 0;
  Map<String, String> _masterAttrValues = {};
  Map<String, String> _masterNoticeValues = {};
  String? _masterNoticeGroup;
  String _metaBaseError = '';
  List<ImageField> _imageFields = [];
  List<ImageFieldFilter> _imageFieldFilters = [];
  bool _isLoading = true;
  String _error = '';

  // Per-cell generated assets. Missing key = still loading, null = failed.
  Map<int, GeneratedProduct?> _generated = {};
  bool _genLoading = false;

  // Accounts whose outbound/return places are unset. Missing key = unknown.
  Map<int, bool> _placesUnset = {};
  int? _shippingLoadingId;

  // Unregistered channels selected for batch registration, by accountId.
  Set<int> _selected = {};
  bool _isBatchAdding = false;
  int? _rowBusyId;
  _BatchSummary? _batchSummary;

  bool _isPropagating = false;
  _Notice? _banner;
  String? _createNotice;
  ChannelSyncPreview? _syncPreview;

  FocusOptionSignal? _focusOption;
  List<ChannelOptionCell>? _channelOptionCells;
  String _channelOptionError = '';

  bool _isApplyingNames = false;
  bool _isDeleting = false;

  // ---- Section state (PLAN R-f · R9) ----
  bool _overviewOpen = false;
  // products | master | channels. With the overview off, `master` shows the
  // tab in [_tab].
  String _section = _secChannels;
  String _tab = _tabBasic;
  bool _panelMounted = false;
  final Set<String> _visitedTabs = {};

  int get _id => widget.masterId;

  @override
  void initState() {
    super.initState();
    _createNotice = widget.args.notice;
    _overviewOpen = widget.args.openOverview;
    unawaited(_load());
    unawaited(_loadCostCandidates());
    unawaited(_loadImageFields());
    unawaited(_loadMetaBase());
  }

  // ---------------------------------------------------------------- loading

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final matrixFuture = _useCase.getMatrix(_id);
    final masterFuture = _useCase.getMaster(_id);
    final categoryFuture = _useCase.getMasterCategory(_id);
    await Future.wait<Object>([matrixFuture, masterFuture, categoryFuture]);
    final matrixResult = await matrixFuture;
    final masterResult = await masterFuture;
    final categoryResult = await categoryFuture;
    if (!mounted) {
      return;
    }
    final matrix = matrixResult.fold((_) => null, (m) => m);
    final master = masterResult.fold((_) => null, (m) => m);
    if (matrix == null || master == null) {
      setState(() {
        _isLoading = false;
        _error = '커버리지 매트릭스를 불러오지 못했습니다.';
      });
      return;
    }
    final category = categoryResult.fold((_) => null, (c) => c);
    setState(() {
      _matrix = matrix;
      _master = master;
      _options = master.options;
      _selected = {};
      _isLoading = false;
    });
    _setCategory(category);
    // Fire-and-forget: the list draws now, these fill in after.
    unawaited(_fetchGenerated(matrix));
    unawaited(_fetchPlaces(matrix));
    unawaited(_fetchSyncPreview());
    unawaited(_fetchChannelOptions());
  }

  Future<void> _fetchGenerated(ListingMatrix m) async {
    final registered =
        m.rows.expand(_rowCellsOf).map((c) => c.productListingId).toList();
    setState(() => _genLoading = true);
    final entries = await Future.wait(
      registered.map((lid) async {
        final result = await _useCase.getGenerated(lid);
        return MapEntry(lid, result.fold((_) => null, (g) => g));
      }),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _generated = Map.fromEntries(entries);
      _genLoading = false;
    });
  }

  Future<void> _fetchPlaces(ListingMatrix m) async {
    final accountIds = m.rows
        .where((r) => !r.registered || _rowCellsOf(r).isEmpty)
        .map((r) => r.accountId)
        .toList();
    final entries = await Future.wait(
      accountIds.map((accountId) async {
        final result = await _useCase.getShippingConfig(accountId);
        return result.fold<MapEntry<int, bool>?>(
          (_) => null,
          (cfg) {
            final outbound = cfg.outboundShippingPlaceCode?.trim() ?? '';
            final returnCenter = cfg.returnCenterCode?.trim() ?? '';
            return MapEntry(
              accountId,
              outbound.isEmpty || returnCenter.isEmpty,
            );
          },
        );
      }),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _placesUnset = Map.fromEntries(entries.whereType<MapEntry<int, bool>>());
    });
  }

  Future<void> _fetchSyncPreview() async {
    final result = await _useCase.getChannelSyncPreview(_id);
    if (!mounted) {
      return;
    }
    setState(() => _syncPreview = result.fold((_) => null, (p) => p));
  }

  Future<void> _fetchChannelOptions() async {
    setState(() => _channelOptionError = '');
    final result = await _useCase.getChannelOptions(_id);
    if (!mounted) {
      return;
    }
    setState(() {
      result.fold(
        (f) {
          _channelOptionCells = null;
          _channelOptionError = failureText(f, '채널별 옵션을 불러오지 못했습니다.');
        },
        (res) => _channelOptionCells = res.cells,
      );
    });
  }

  // Carrier / box candidates — loaded once; a failure leaves them empty.
  Future<void> _loadCostCandidates() async {
    final ratesFuture = getIt<GetCarrierRatesUseCase>()();
    // 🔴 Box candidates for price calculation = purchased boxes only.
    final boxesFuture = _useCase.getPurchasedBoxes();
    await Future.wait<Object>([ratesFuture, boxesFuture]);
    final rates = (await ratesFuture).fold((_) => null, (r) => r);
    final boxes = (await boxesFuture).fold((_) => null, (b) => b);
    if (!mounted || rates == null || boxes == null) {
      return;
    }
    setState(() {
      _carrierRates = rates;
      _packages = boxes;
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
    });
  }

  /// Web `useEffect([categoryId, metaVersion])` — the option override
  /// baseline (saved master category meta).
  Future<void> _loadMetaBase() async {
    final request = ++_metaRequest;
    if (_category == null) {
      setState(() {
        _masterAttrValues = {};
        _masterNoticeValues = {};
        _masterNoticeGroup = null;
        _metaBaseError = '';
      });
      return;
    }
    final result = await _useCase.getCategoryMeta(_id, 'COUPANG');
    if (!mounted || request != _metaRequest) {
      return;
    }
    setState(() {
      result.fold(
        (_) {
          _masterAttrValues = {};
          _masterNoticeValues = {};
          _masterNoticeGroup = null;
          _metaBaseError =
              '카테고리 메타를 불러오지 못해 옵션의 상속 기준값이 비어 있습니다. 옵션에 입력한 값이 그대로 저장됩니다.';
        },
        (meta) {
          _masterAttrValues = meta.values.attributes;
          _masterNoticeValues = meta.values.notices;
          _masterNoticeGroup = submitNoticeGroup(
            meta.notices,
            meta.values.notices,
            meta.values.noticeGroup,
          );
          _metaBaseError = '';
        },
      );
    });
  }

  void _setCategory(MasterCategory? category) {
    final changed = category?.categoryId != _category?.categoryId;
    setState(() => _category = category);
    if (changed) {
      unawaited(_loadMetaBase());
    }
  }

  // A panel saved its own fields: take the response and patch the header
  // name in place. ⚠️ Never reload the matrix here.
  void _handlePanelSaved(MasterProduct patched) {
    setState(() {
      _master = patched;
      final matrix = _matrix;
      if (matrix != null) {
        _matrix = ListingMatrix(
          masterId: matrix.masterId,
          masterName: patched.name,
          rows: matrix.rows,
          masterCategoryName: matrix.masterCategoryName,
        );
      }
    });
  }

  // [옵션 수정] in the option×channel table → 「상품 기본 정보」 + focus.
  void _handleEditMasterOption(int masterOptionId) {
    setState(() {
      _tab = _tabBasic;
      _section = _secMaster;
      _visitedTabs.add(_tab);
      _focusOption = FocusOptionSignal(
        optionId: masterOptionId,
        nonce: DateTime.now().millisecondsSinceEpoch,
      );
    });
  }

  // ---------------------------------------------------------------- derived

  bool _isShippingBlocked(int accountId) => _placesUnset[accountId] == true;

  List<MatrixRow> get _unregisteredRows =>
      _matrix?.rows.where((r) => !r.registered).toList() ?? const [];

  List<MatrixRow> get _selectableRows =>
      _unregisteredRows.where((r) => !_isShippingBlocked(r.accountId)).toList();

  List<int> get _effectiveSelected =>
      _selected.where((id) => !_isShippingBlocked(id)).toList();

  bool get _allSelected =>
      _selectableRows.isNotEmpty &&
      _effectiveSelected.length == _selectableRows.length;

  bool get _busy => _isBatchAdding || _rowBusyId != null;

  // Every cell (not the first per account) — the force-apply list.
  List<ForceApplyChannel> get _forceApplyChannels =>
      (_matrix?.rows ?? const <MatrixRow>[]).expand((r) {
        final cells = _rowCellsOf(r);
        return cells.map((c) {
          final gen = _generated[c.productListingId];
          return ForceApplyChannel(
            listingId: c.productListingId,
            label:
                '${r.sellerName} · ${r.platform}${cells.length > 1 ? ' · ${_cellTag(c)}' : ''}',
            override: gen?.shippingOverride,
            overrideLoaded: gen != null,
          );
        });
      }).toList();

  // ---------------------------------------------------------------- actions

  void _toggleOne(int accountId) {
    setState(() {
      final next = {..._selected};
      if (!next.remove(accountId)) {
        next.add(accountId);
      }
      _selected = next;
    });
  }

  void _toggleAll() {
    setState(() {
      _selected =
          _allSelected ? {} : _selectableRows.map((r) => r.accountId).toSet();
    });
  }

  Future<void> _handleBatchAdd() async {
    final targets = _unregisteredRows
        .where((r) =>
            _selected.contains(r.accountId) && !_isShippingBlocked(r.accountId))
        .map((r) => ChannelTarget(sellerId: r.sellerId, platform: r.platform))
        .toList();
    if (targets.isEmpty) {
      setState(() {
        _error = '등록할 채널이 없습니다. 출고지·반품지가 지정되지 않은 판매자는 채널을 만들 수 없습니다.';
      });
      return;
    }
    setState(() {
      _isBatchAdding = true;
      _batchSummary = null;
      _error = '';
    });
    final result = await _useCase.addChannelsBatch(_id, targets);
    if (!mounted) {
      return;
    }
    final res = result.fold((_) => null, (r) => r);
    if (res == null) {
      setState(() {
        _error = result.fold(
          (f) => failureText(f, '일괄 등록에 실패했습니다.'),
          (_) => '',
        );
        _isBatchAdding = false;
      });
      return;
    }
    final failures = res.results.where((r) => !r.success).map((r) {
      String? name;
      for (final row in _matrix?.rows ?? const <MatrixRow>[]) {
        if (row.sellerId == r.sellerId && row.platform == r.platform) {
          name = row.sellerName;
          break;
        }
      }
      return '${name ?? r.sellerId}/${r.platform} — ${r.errorMessage ?? '실패'}';
    }).toList();
    setState(() {
      _batchSummary = _BatchSummary(
        text: '요청 ${res.requested} · 등록 ${res.succeeded} · 실패 ${res.failed}',
        green: res.failed <= 0,
        failures: failures,
      );
    });
    await _load();
    if (mounted) {
      setState(() => _isBatchAdding = false);
    }
  }

  Future<void> _handleRowAdd(
      int accountId, int sellerId, String platform) async {
    setState(() {
      _rowBusyId = accountId;
      _error = '';
    });
    final result =
        await _useCase.addChannel(_id, sellerId: sellerId, platform: platform);
    if (!mounted) {
      return;
    }
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      // 2609_74/D7: a 400 has other causes than the category — no fixed hint.
      setState(() {
        _error = failureText(failure, '채널 등록에 실패했습니다.');
        _rowBusyId = null;
      });
      return;
    }
    await _load();
    if (mounted) {
      setState(() => _rowBusyId = null);
    }
  }

  // 2609_77/D43: [쿠팡에 올리기] = create the listing line → option picker.
  // 🔴 Nothing is sent to Coupang here — the sheet's [올리기] sends.
  Future<void> _handleRowUpload(
    int accountId,
    int sellerId,
    String platform,
    String channelLabel,
  ) async {
    setState(() => _rowBusyId = accountId);
    final result =
        await _useCase.addChannel(_id, sellerId: sellerId, platform: platform);
    if (!mounted) {
      return;
    }
    final added = result.fold((_) => null, (r) => r);
    if (added == null) {
      setState(() => _rowBusyId = null);
      result.fold(
        (f) => showErrorToast(context, failureText(f, '판매상품 줄을 만들지 못했습니다.')),
        (_) {},
      );
      return;
    }
    await _load();
    if (!mounted) {
      return;
    }
    setState(() => _rowBusyId = null);
    final addedCell = (_matrix?.rows ?? const <MatrixRow>[])
        .expand(_rowCellsOf)
        .where((c) => c.productListingId == added.productListingId)
        .firstOrNull;
    final done = await showListingOptionPickerSheet(
      context,
      mode: 'upload',
      listingId: added.productListingId,
      channelLabel: channelLabel,
      displayName: addedCell?.name ?? '',
      onDisplayNameSaved: () => unawaited(_load()),
    );
    if (!mounted) {
      return;
    }
    if (done) {
      unawaited(_load());
    } else {
      // D43: the created line stays as 「미전송」 — say it did not vanish.
      showSuccessToast(context, '판매상품 줄을 만들었습니다. 아직 쿠팡에 올리지 않았습니다.');
    }
  }

  // 2609_77/S6 · D83: blocked account → its shipping config page.
  Future<void> _openShippingConfig(int accountId, int sellerId) async {
    setState(() => _shippingLoadingId = accountId);
    final result =
        await getIt<GetMarketplaceAccountsBySellerUseCase>()(sellerId);
    if (!mounted) {
      return;
    }
    setState(() => _shippingLoadingId = null);
    final accounts = result.fold((_) => null, (a) => a);
    if (accounts == null) {
      result.fold(
        (f) => showErrorToast(context, failureText(f, '판매채널 정보를 불러오지 못했습니다.')),
        (_) {},
      );
      return;
    }
    MarketplaceAccount? account;
    for (final a in accounts) {
      if (a.id == accountId) {
        account = a;
        break;
      }
    }
    if (account == null) {
      showErrorToast(context, '판매채널 정보를 찾지 못했습니다.');
      return;
    }
    await context.pushNamed(
      Routes.masterShippingConfig,
      extra: ShippingConfigArgs(account: account),
    );
    if (mounted) {
      unawaited(_load());
    }
  }

  Future<void> _handlePropagate() async {
    if (_isPropagating) {
      return;
    }
    final preview = _syncPreview;
    final lines = preview != null && !preview.inSync
        ? _syncSummaryLines(preview)
        : const <String>[];
    final ok = await showAppConfirmDialog(
      context,
      title: '채널에 반영',
      message: '마스터 변경분을 연결된 채널에 반영합니다.'
          '${lines.isNotEmpty ? '\n\n${lines.map((l) => '• $l').join('\n')}' : ''}',
      confirmText: '반영하기',
    );
    if (!ok || !mounted || _isPropagating) {
      return;
    }
    setState(() {
      _isPropagating = true;
      _banner = null;
    });
    final result = await _useCase.propagate(_id);
    if (!mounted) {
      return;
    }
    final res = result.fold((_) => null, (r) => r);
    if (res == null) {
      setState(() {
        _banner = const _Notice(text: '채널 반영에 실패했습니다.', green: false);
        _isPropagating = false;
      });
      return;
    }
    final extra = (res.skipped > 0 ? ' · 반영 대상이 아닌 채널 ${res.skipped}개' : '') +
        (res.failed > 0 ? ' · 실패 ${res.failed}개' : '');
    setState(() {
      _banner = _Notice(
        text: '${res.propagated}개 채널에 반영했습니다.$extra — 마켓 반영은 반영/승인 콘솔에서 진행하세요.',
        green: res.failed <= 0,
      );
    });
    await _load();
    if (mounted) {
      setState(() => _isPropagating = false);
    }
  }

  Future<void> _handleCellRemoved(String message) async {
    setState(() => _banner = _Notice(text: message, green: true));
    await _load();
  }

  Future<void> _handleImportDone(String? categoryWarning) async {
    showSuccessToast(context, '쿠팡 상품을 가져왔습니다.');
    setState(() {
      _banner = categoryWarning != null
          ? _Notice(text: categoryWarning, green: false)
          : null;
    });
    await _load();
  }

  Future<void> _openMarketProductAdd(MatrixRow row,
      {String? initialProductId}) async {
    final r = await context.pushNamed<MarketProductAddResult>(
      Routes.masterMarketProductAdd,
      extra: MarketProductAddArgs(
        masterId: _id,
        sellerId: row.sellerId,
        platform: row.platform,
        sellerName: row.sellerName,
        masterOptions: _options,
        initialProductId: initialProductId,
      ),
    );
    if (r != null && mounted) {
      await _handleImportDone(r.categoryWarning);
    }
  }

  Future<void> _openDetachedPicker(MatrixRow row) async {
    final id = await showDetachedListingPickerSheet(
      context,
      masterId: _id,
      sellerId: row.sellerId,
      platform: row.platform,
      sellerName: row.sellerName,
    );
    if (id != null && mounted) {
      await _openMarketProductAdd(row, initialProductId: id);
    }
  }

  Future<void> _handleApplyNames() async {
    final ok = await showAppConfirmDialog(
      context,
      title: '옵션명 일괄 적용',
      message: '채널에서 따로 지정한 옵션명이 마스터 옵션명으로 되돌아갑니다. 진행할까요?',
      confirmText: '적용하기',
    );
    if (!ok || !mounted || _isApplyingNames) {
      return;
    }
    setState(() {
      _isApplyingNames = true;
      _banner = null;
    });
    final result = await _useCase.applyMasterOptionNames(_id);
    if (!mounted) {
      return;
    }
    final res = result.fold((_) => null, (r) => r);
    if (res == null) {
      setState(() {
        _banner = _Notice(
          text: result.fold(
            (f) => failureText(f, '옵션명 일괄 적용에 실패했습니다.'),
            (_) => '',
          ),
          green: false,
        );
        _isApplyingNames = false;
      });
      return;
    }
    final warnings = res.warnings;
    setState(() {
      _banner = _Notice(
        text:
            '${res.updatedCells}개 채널 · ${res.updatedOptions}개 옵션의 이름을 마스터 기준으로 되돌렸습니다.'
            '${warnings.isNotEmpty ? ' — ${warnings.join(' · ')}' : ''}',
        green: warnings.isEmpty,
      );
    });
    await _load();
    if (mounted) {
      setState(() => _isApplyingNames = false);
    }
  }

  // Hard delete (2609_72). Success leaves this screen for the list.
  Future<void> _handleDelete() async {
    final master = _master;
    if (_isDeleting || master == null) {
      return;
    }
    final ok = await showAppConfirmDialog(
      context,
      title: '마스터 삭제',
      message: '${master.name} 을(를) 삭제합니다. 되돌릴 수 없습니다.\n\n'
          '• 옵션 ${master.options.length}개 · 구성상품 ${master.components.length}개와 '
          '사진이 함께 삭제됩니다\n'
          '• 마켓에 올리지 않은 채널은 함께 삭제됩니다\n'
          '• 마켓에 올린 채널이 있으면 삭제되지 않습니다 — 먼저 [연결 해제] 하세요\n'
          '• 연결 해제한 판매상품이 이 마스터의 사진을 쓰고 있었다면 상세 이미지가 깨질 수 있습니다',
      confirmText: '삭제',
      isDangerous: true,
    );
    if (!ok || !mounted || _isDeleting) {
      return;
    }
    setState(() {
      _isDeleting = true;
      _error = '';
    });
    final result = await _useCase.deleteMaster(_id);
    if (!mounted) {
      return;
    }
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      setState(() {
        _isDeleting = false;
        _error = failureText(failure, '삭제에 실패했습니다.');
      });
      return;
    }
    // `_isDeleting` stays true while leaving so the button cannot be pressed.
    context.go(Routes.masterProductsPath);
  }

  void _handleShippingSaved(int listingId, GeneratedProduct updated) {
    setState(() => _generated = {..._generated, listingId: updated});
  }

  void _openPreview(GeneratedProduct? gen, String title, String tab) {
    unawaited(showChannelPreviewSheet(
      context,
      ChannelPreviewData(
        imageSrc: gen?.thumbnailUrl,
        html: gen?.detailHtml,
        title: title,
        initialTab: tab,
      ),
    ));
  }

  // ---------------------------------------------------------------- sections

  void _toggleOverview() {
    setState(() {
      _overviewOpen = !_overviewOpen;
      if (_overviewOpen) {
        // D50: the product panel just opened on the left.
        _section = _secProducts;
        _panelMounted = true;
      } else {
        _section = _secChannels;
      }
    });
  }

  // Overview off: `channels` or one of the 4 tab keys.
  void _selectOffSection(String key) {
    setState(() {
      if (key == _secChannels) {
        _section = _secChannels;
      } else {
        _section = _secMaster;
        _tab = key;
        _visitedTabs.add(key);
      }
    });
  }

  // Overview on: products · master · channels.
  void _selectOnSection(String key) {
    setState(() {
      _section = key;
      if (key == _secProducts) {
        _panelMounted = true;
      }
      if (key == _secMaster) {
        _visitedTabs.add(_tab);
      }
    });
  }

  void _selectTab(String key) {
    setState(() {
      _tab = key;
      _visitedTabs.add(key);
    });
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final matrix = _matrix;
    final master = _master;
    final preview = _syncPreview;
    final banner = _banner ??
        (_createNotice != null
            ? _Notice(text: _createNotice!, green: false)
            : null);
    final tabItems = _tabItems();

    final Widget sectionBar;
    final relationChip = FilterChip(
      label: const Text('상품 관계'),
      selected: _overviewOpen,
      onSelected: (_) => _toggleOverview(),
    );
    if (_overviewOpen) {
      sectionBar = MasterSectionBar(
        items: const [
          MasterSectionItem(key: _secProducts, label: '물품'),
          MasterSectionItem(key: _secMaster, label: '마스터'),
          MasterSectionItem(key: _secChannels, label: '판매채널'),
        ],
        selected: _section,
        onSelected: _selectOnSection,
        trailing: relationChip,
      );
    } else {
      sectionBar = MasterSectionBar(
        items: [
          const MasterSectionItem(key: _secChannels, label: '판매채널'),
          ...tabItems,
        ],
        selected: _section == _secChannels ? _secChannels : _tab,
        onSelected: _selectOffSection,
        trailing: relationChip,
      );
    }

    return ScaffoldWithNavBar(
      title: matrix?.masterName ?? '커버리지 매트릭스',
      navBarIndex: 2,
      onBackPressed: () => context.go(Routes.masterProductsPath),
      // A single scroll (not a lazy ListView) so offstage sections are never
      // disposed while scrolled away (R9 — unsaved input).
      body: AppPageBody.scroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeadButtons(context),
            if (_batchSummary != null) ...[
              const SizedBox(height: 12),
              _buildBatchSummary(_batchSummary!),
            ],
            if (banner != null) ...[
              const SizedBox(height: 12),
              _NoticeBox(
                text: banner.text,
                background: banner.green
                    ? AppColors.successSurface
                    : AppColors.warningSurface,
                foreground: banner.green
                    ? AppColors.successForeground
                    : AppColors.warningForeground,
              ),
            ],
            if (preview != null && !preview.inSync) ...[
              const SizedBox(height: 12),
              _buildSyncPreview(context, preview),
            ],
            if (preview != null &&
                preview.inSync &&
                preview.channels
                    .any((c) => c.marketChannelOnlyOptions.isNotEmpty)) ...[
              const SizedBox(height: 12),
              _buildOrphanList(context, preview),
            ],
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              AppErrorBox(message: _error),
            ],
            const SizedBox(height: 12),
            sectionBar,
            const SizedBox(height: 12),
            if (_panelMounted)
              Offstage(
                key: const ValueKey('section-products'),
                offstage: !(_overviewOpen && _section == _secProducts),
                child: ProductRelationPanel(
                  mode: 'view',
                  componentIds:
                      master?.components.map((c) => c.productId).toList(),
                  masterId: _id,
                ),
              ),
            Offstage(
              key: const ValueKey('section-channels'),
              offstage: _section != _secChannels,
              child: _buildChannels(context),
            ),
            Offstage(
              key: const ValueKey('section-master'),
              offstage: _section != _secMaster,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_overviewOpen && tabItems.isNotEmpty) ...[
                    MasterSectionBar(
                      key: const ValueKey('inner-tabs-bar'),
                      items: tabItems,
                      selected: _tab,
                      onSelected: _selectTab,
                    ),
                    const SizedBox(height: 12, key: ValueKey('inner-tabs-gap')),
                  ],
                  if (master != null)
                    AppCard.flush(
                      key: const ValueKey('tabs-card'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final key in _tabKeys)
                            if (_visitedTabs.contains(key))
                              Offstage(
                                key: ValueKey('tab-$key'),
                                offstage: _tab != key,
                                child: _buildTab(context, key, master),
                              ),
                        ],
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

  /// The 4 edit tabs — only once `master` is loaded (web `tabs = master ? […] : []`).
  List<MasterSectionItem> _tabItems() {
    final master = _master;
    if (master == null) {
      return const [];
    }
    final category = _category;
    final filledFieldCount =
        master.fieldValues.values.where((v) => v.trim().isNotEmpty).length;
    final categorySummary = category != null ? category.categoryName : '미지정';
    final metaFilledCount =
        _masterAttrValues.values.where((v) => v.trim().isNotEmpty).length +
            _masterNoticeValues.values.where((v) => v.trim().isNotEmpty).length;
    final basicSummary =
        '${master.name} · $categorySummary · 필수속성 $metaFilledCount개 · 옵션 ${_options.length}개 · '
        '${master.sourceImageUrl != null && master.sourceImageUrl!.isNotEmpty ? '대표사진 있음' : '대표사진 없음'}';
    final channelCellCount = (_matrix?.rows ?? const <MatrixRow>[])
        .fold<int>(0, (sum, row) => sum + _rowCellsOf(row).length);
    final channelOptionSummary =
        '옵션 ${_options.length}개 · 채널 $channelCellCount개';
    final fieldValuesSummary =
        filledFieldCount > 0 ? '$filledFieldCount개 입력됨' : '입력 없음';
    CarrierRate? summaryCarrier;
    for (final r in _carrierRates) {
      if (r.id == master.defaultDeliveryId) {
        summaryCarrier = r;
        break;
      }
    }
    MasterBox? summaryPackage;
    for (final p in _packages) {
      if (p.id == master.defaultPackageId) {
        summaryPackage = p;
        break;
      }
    }
    final defaultCostSummary =
        '${summaryCarrier != null ? carrierLabel(summaryCarrier) : '미지정'} · '
        '${summaryPackage != null ? packageLabel(summaryPackage) : '미지정'}';
    final tagsSummary = '태그 ${master.tags.length}개';
    final shippingOverrideCount = master.shippingOverride?.length ?? 0;
    final shippingSummary =
        shippingOverrideCount > 0 ? '$shippingOverrideCount개 항목 지정' : '기본값 사용';
    return [
      MasterSectionItem(
          key: _tabBasic, label: '상품 기본 정보', summary: basicSummary),
      MasterSectionItem(
          key: _tabImages, label: '이미지', summary: fieldValuesSummary),
      MasterSectionItem(
        key: _tabShipping,
        label: '배송 설정',
        summary: '$defaultCostSummary · $shippingSummary',
      ),
      MasterSectionItem(
        key: _tabChannelOptions,
        label: '채널별 옵션 설정',
        summary: '$channelOptionSummary · $tagsSummary',
      ),
    ];
  }

  Widget _buildHeadButtons(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = _syncPreview;
    final inSync = preview?.inSync == true;
    final selectedCount = _effectiveSelected.length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton(
          onPressed: selectedCount == 0 || _busy ? null : _handleBatchAdd,
          child: _isBatchAdding
              ? const AppBusyLabel('등록 중...')
              : Text(
                  '선택 채널 일괄 등록${selectedCount > 0 ? ' ($selectedCount)' : ''}'),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              // ⚠️ Strict `== true`: an unknown preview never blocks.
              onPressed: _isPropagating || inSync ? null : _handlePropagate,
              child: _isPropagating
                  ? const AppBusyLabel('반영 중...')
                  : Text(
                      '채널에 반영하기${preview != null && !preview.inSync ? ' (${preview.totals.affectedChannels})' : ''}'),
            ),
            if (inSync) const InfoBubbleIcon(message: '반영할 변경이 없습니다'),
          ],
        ),
        if (inSync)
          Text(
            '모든 채널이 최신입니다',
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
              onPressed: _master == null || _isDeleting || _busy
                  ? null
                  : _handleDelete,
              child: _isDeleting
                  ? const AppBusyLabel('삭제 중...')
                  : const Text('마스터 삭제'),
            ),
            if (_master == null)
              const InfoBubbleIcon(message: '마스터를 불러오는 중입니다'),
          ],
        ),
      ],
    );
  }

  Widget _buildBatchSummary(_BatchSummary summary) {
    final fg = summary.green
        ? AppColors.successForeground
        : AppColors.warningForeground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            summary.green ? AppColors.successSurface : AppColors.warningSurface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary.text, style: TextStyle(fontSize: 14, color: fg)),
          if (summary.failures.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (final f in summary.failures)
              Text('• $f', style: TextStyle(fontSize: 12, color: fg)),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncPreview(BuildContext context, ChannelSyncPreview preview) {
    final scheme = Theme.of(context).colorScheme;
    final lines = _syncSummaryLines(preview);
    const fg = AppColors.infoForeground;
    final muted = TextStyle(color: scheme.onSurfaceVariant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.infoSurface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '채널에 반영할 변경이 ${_syncOptionCount(preview)}건 있습니다'
            '${lines.isNotEmpty ? ' — ${lines.join(' · ')}' : ''}',
            style: const TextStyle(fontSize: 14, color: fg),
          ),
          const SizedBox(height: 4),
          // Order = response order (sellerName → platform) — never re-sort.
          for (final c in preview.channels.take(5))
            Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 12, color: fg),
                children: [
                  const TextSpan(text: '• '),
                  if (_channelDiffText(c).isNotEmpty) ...[
                    TextSpan(
                      text:
                          '${c.sellerName} · ${c.platform} — ${_channelDiffText(c)}',
                    ),
                    if (c.onMarket)
                      TextSpan(text: ' (반영 후 재등록 필요)', style: muted),
                  ],
                  if (c.marketChannelOnlyOptions.isNotEmpty)
                    TextSpan(
                      text:
                          '${_channelDiffText(c).isNotEmpty ? ' ' : '${c.sellerName} · ${c.platform} — '}'
                          '마스터에 없는데 판매 중: ${c.marketChannelOnlyOptions.join(', ')} (WING에서 직접 중지)',
                      style: muted,
                    ),
                ],
              ),
            ),
          if (preview.channels.length > 5) ...[
            const SizedBox(height: 4),
            Text(
              '외 ${preview.channels.length - 5}개 채널',
              style: const TextStyle(fontSize: 12, color: fg),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrphanList(BuildContext context, ChannelSyncPreview preview) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in preview.channels
              .where((c) => c.marketChannelOnlyOptions.isNotEmpty)
              .take(5))
            Text(
              '• ${c.sellerName} · ${c.platform} — 마스터에 없는데 판매 중: '
              '${c.marketChannelOnlyOptions.join(', ')} (WING에서 직접 중지)',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- channels

  Widget _buildChannels(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final matrix = _matrix;
    final Widget body;
    if (_isLoading) {
      body = const SizedBox(
        height: 128,
        child: Center(child: AppBusyLabel('불러오는 중...')),
      );
    } else if (matrix == null || matrix.rows.isEmpty) {
      body = AppCard.flush(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Text(
            '등록된 판매채널 계정이 없습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          ),
        ),
      );
    } else {
      // Accounts needing action first (two groups, response order inside).
      final sortedRows = _stableSorted(
        matrix.rows,
        (a, b) =>
            (_rowActionCount(b) > 0 ? 1 : 0) - (_rowActionCount(a) > 0 ? 1 : 0),
      );
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_unregisteredRows.isNotEmpty)
            CheckboxListTile(
              value: _allSelected,
              onChanged:
                  _busy || _selectableRows.isEmpty ? null : (_) => _toggleAll(),
              title: const Text(
                '미등록 계정 전체 선택',
                style: TextStyle(fontSize: 12),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          for (var i = 0; i < sortedRows.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildAccountCard(context, matrix, sortedRows[i]),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        const SizedBox(height: 8),
        const Text(
          '$kMarketOptionLockReason 옵션 추가는 언제든 가능합니다.',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.warningForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    ListingMatrix matrix,
    MatrixRow row,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final rowCells = _sortedCells(_rowCellsOf(row));
    final multiCell = rowCells.length > 1;
    String cellLabel(MatrixCell c) =>
        '${row.sellerName} · ${row.platform}${multiCell ? ' · ${_cellTag(c)}' : ''}';
    final canRegister = !row.registered || rowCells.isEmpty;
    final actionCount =
        rowCells.fold<int>(0, (sum, c) => sum + cellActionCount(c));
    final blocked = _isShippingBlocked(row.accountId);
    final isCoupang = row.platform == 'COUPANG';
    final rowBusy = _rowBusyId == row.accountId;
    final smallButton = OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
    );
    final blueButton = OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      foregroundColor: AppColors.infoForeground,
    );

    return AppCard.flush(
      key: ValueKey('account-${row.accountId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (canRegister)
                      // Batch registration is per **account**.
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value:
                                  _selected.contains(row.accountId) && !blocked,
                              onChanged: _busy || blocked
                                  ? null
                                  : (_) => _toggleOne(row.accountId),
                            ),
                          ),
                          if (blocked)
                            const InfoBubbleIcon(message: _shippingBlockReason),
                        ],
                      ),
                    Text(
                      '${row.platform} · ${row.accountLabel}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      row.sellerName,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (rowCells.isNotEmpty)
                      Text(
                        '판매상품 ${rowCells.length}개',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '미등록',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (actionCount > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningSurface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '조치 필요 $actionCount',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warningForeground,
                              ),
                            ),
                          ),
                          const InfoBubbleIcon(
                            message: '변경 미반영 · 카테고리 불일치 칩의 합',
                          ),
                        ],
                      ),
                    if (canRegister && isCoupang)
                      // 2609_77/D43: create the line, then the option picker.
                      _withBlockedHint(
                        blocked,
                        OutlinedButton(
                          style: blueButton,
                          onPressed: _busy || blocked
                              ? null
                              : () => _handleRowUpload(
                                    row.accountId,
                                    row.sellerId,
                                    row.platform,
                                    '${row.sellerName} · ${row.platform}',
                                  ),
                          child: rowBusy
                              ? const AppBusyLabel('만드는 중')
                              : const Text('쿠팡에 올리기'),
                        ),
                      ),
                    if (canRegister && !isCoupang)
                      _withBlockedHint(
                        blocked,
                        OutlinedButton(
                          style: blueButton,
                          onPressed: _busy || blocked
                              ? null
                              : () => _handleRowAdd(
                                    row.accountId,
                                    row.sellerId,
                                    row.platform,
                                  ),
                          child: rowBusy
                              ? const AppBusyLabel('등록 중')
                              : const Text('등록'),
                        ),
                      ),
                    // 2609_22: attach a product already on the market (no
                    // shipping guard — it is already selling).
                    if (isCoupang)
                      OutlinedButton(
                        style: smallButton,
                        onPressed:
                            _busy ? null : () => _openMarketProductAdd(row),
                        child: const Text('마켓 상품 추가하기'),
                      ),
                    // 2609_74/D14: re-attach a detached listing of this account.
                    if (isCoupang)
                      OutlinedButton(
                        style: smallButton,
                        onPressed:
                            _busy ? null : () => _openDetachedPicker(row),
                        child: const Text('미연결 판매상품 연결'),
                      ),
                  ],
                ),
                if (canRegister && blocked) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '배송 설정 필요 — 판매채널 관리 > 배송관리에서 출고지·반품지를 먼저 지정하세요.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.warningForeground,
                              ),
                            ),
                          ),
                          InfoBubbleIcon(
                            message: _shippingBlockReason,
                            size: 14,
                          ),
                        ],
                      ),
                      // 2609_77/S6 · D83: open this account's shipping config.
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.warningForeground,
                        ),
                        onPressed: _shippingLoadingId != null
                            ? null
                            : () => _openShippingConfig(
                                  row.accountId,
                                  row.sellerId,
                                ),
                        child: _shippingLoadingId == row.accountId
                            ? const AppBusyLabel('여는 중')
                            : const Text('배송 설정하기'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          for (final cell in rowCells)
            ListingRow(
              key: ValueKey(cell.productListingId),
              masterId: _id,
              cell: cell,
              gen: _generated[cell.productListingId],
              genLoaded: _generated.containsKey(cell.productListingId),
              genLoading: _genLoading,
              channelOptions: _channelOptionsOf(cell.productListingId),
              channelOptionsLoading:
                  _channelOptionCells == null && _channelOptionError.isEmpty,
              masterOptions: _options,
              channelLabel: cellLabel(cell),
              accountId: row.accountId,
              platform: row.platform,
              onEditMasterOption: _handleEditMasterOption,
              onReload: () => unawaited(_load()),
              onPreview: _openPreview,
              onShippingSaved: _handleShippingSaved,
              masterCategoryName: matrix.masterCategoryName,
              onCellRemoved: (message) =>
                  unawaited(_handleCellRemoved(message)),
            ),
        ],
      ),
    );
  }

  List<ListingOptionSummary>? _channelOptionsOf(int listingId) {
    for (final cell in _channelOptionCells ?? const <ChannelOptionCell>[]) {
      if (cell.productListingId == listingId) {
        return cell.options;
      }
    }
    return null;
  }

  Widget _withBlockedHint(bool blocked, Widget button) => blocked
      ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button,
            const InfoBubbleIcon(message: _shippingBlockReason),
          ],
        )
      : button;

  // ---------------------------------------------------------------- tabs

  Widget _buildTab(BuildContext context, String key, MasterProduct master) {
    switch (key) {
      case _tabBasic:
        return _buildBasicTab(context, master);
      case _tabImages:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '이미지',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '변경 즉시 저장됩니다.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  MasterImagePool(
                    masterId: _id,
                    fields: _imageFields,
                    fieldFilters: _imageFieldFilters,
                    sourceProducts: master.components
                        .map((c) =>
                            SourceProduct(id: c.productId, name: c.productName))
                        .toList(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _StackedBlock(
              title: '템플릿 필드값',
              child: MasterFieldValuesPanel(
                master: master,
                onSaved: _handlePanelSaved,
              ),
            ),
          ],
        );
      case _tabShipping:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StackedBlock(
              title: '기본 택배/상자',
              child: MasterDefaultCostPanel(
                master: master,
                carrierRates: _carrierRates,
                packages: _packages,
                onSaved: _handlePanelSaved,
              ),
            ),
            const Divider(height: 1),
            MasterShippingOverridePanel(
              masterId: _id,
              channels: _forceApplyChannels,
              onSaved: () => unawaited(_load()),
            ),
          ],
        );
      case _tabChannelOptions:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChannelOptionTable(
              rows: _matrix?.rows ?? const [],
              masterOptions: _options,
              cells: _channelOptionCells,
              error: _channelOptionError,
              onEditMasterOption: _handleEditMasterOption,
            ),
            const Divider(height: 1),
            _StackedBlock(
              title: '등록상품명 · 태그',
              child:
                  MasterTagsPanel(master: master, onSaved: _handlePanelSaved),
            ),
            const Divider(height: 1),
            MasterRegistrationSuffixPanel(
              masterId: _id,
              onSaved: () => unawaited(_load()),
            ),
          ],
        );
    }
  }

  Widget _buildBasicTab(BuildContext context, MasterProduct master) {
    final scheme = Theme.of(context).colorScheme;
    final category = _category;
    // Mixed composition = 2+ component kinds (backend 63 mirror).
    final isBundle = master.components.length >= 2;
    // Coupang is the only platform today → always selected.
    const coupangSelected = true;
    final hideCategoryAttrs = coupangSelected && isBundle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StackedBlock(
          title: '기본 정보',
          child:
              MasterBasicInfoPanel(master: master, onSaved: _handlePanelSaved),
        ),
        const Divider(height: 1),
        _StackedBlock(
          title: '표준 카테고리',
          child: MasterCategoryPanel(
            masterId: _id,
            onCategoryChanged: _setCategory,
          ),
        ),
        const Divider(height: 1),
        _StackedBlock(
          title: '필수속성 · 고시',
          child: CategoryMetaPanel(
            masterId: _id,
            categoryCode: category != null ? '${category.categoryId}' : null,
            isBundle: isBundle,
            onSaved: () => unawaited(_loadMetaBase()),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      '옵션 (수량조합)',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _options.isEmpty || _isApplyingNames
                        ? null
                        : _handleApplyNames,
                    child: const Text('옵션명 일괄 적용'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '옵션의 카테고리 필수속성은 저장된 마스터 값을 기준으로 상속 여부를 판단합니다. '
                '위 [필수속성 · 고시]에서 저장한 뒤 입력하세요.',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
              if (_metaBaseError.isNotEmpty) ...[
                const SizedBox(height: 8),
                _NoticeBox(
                  text: _metaBaseError,
                  background: AppColors.warningSurface,
                  foreground: AppColors.warningForeground,
                  fontSize: 12,
                ),
              ],
              const SizedBox(height: 8),
              MasterOptionEditor(
                master: master,
                carrierRates: _carrierRates,
                packages: _packages,
                masterDefaults: MasterDefaults(
                  deliveryId: master.defaultDeliveryId,
                  packageId: master.defaultPackageId,
                ),
                categoryId: category?.categoryId,
                masterAttrValues: _masterAttrValues,
                masterNoticeValues: _masterNoticeValues,
                masterNoticeGroup: _masterNoticeGroup,
                hideCategoryAttrs: hideCategoryAttrs,
                onChanged: _load,
                focusOption: _focusOption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Title + body of one block stacked inside a tab. Panels do not draw their
/// own titles; dividers between blocks are drawn by the parent.
class _StackedBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _StackedBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          child,
        ],
      );
}

class _NoticeBox extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final double fontSize;

  const _NoticeBox({
    required this.text,
    required this.background,
    required this.foreground,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: fontSize, color: foreground),
        ),
      );
}
