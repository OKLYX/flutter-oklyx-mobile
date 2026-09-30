import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_tool_args.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/listing_option_picker_sheet.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/info_bubble_icon.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';

/// [쿠팡에서 보기] = the WING seller product screen. `platformProductId` is the
/// Coupang sellerProductId (not the buyer page id).
/// ⚠️ The URL shape is unverified on a real account — fix only this function.
String _coupangWingUrl(String sellerProductId) =>
    'https://wing.coupang.com/tenants/seller-web/vendor-inventory/modify'
    '?vendorInventoryId=${Uri.encodeQueryComponent(sellerProductId)}';

// Busy kinds (web `Busy`).
const String _busyRegister = 'register';
const String _busyFetch = 'fetch';
const String _busyRegenerate = 'regenerate';
const String _busyUpdate = 'update';
const String _busyCategorySource = 'category-source';
const String _busyApplyNames = 'apply-names';
const String _busyUnlink = 'unlink';
const String _busyDeleteCell = 'delete-cell';

// Primary button kinds.
const String _primaryUpload = 'upload';
const String _primaryRegister = 'register';
const String _primaryUpdate = 'update';

class _MenuItem {
  final String key;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({required this.key, required this.label, required this.onTap});
}

class _MenuGroup {
  final String label;
  final List<_MenuItem> items;

  const _MenuGroup({required this.label, required this.items});
}

/// Actions of one listing (cell) row = **one primary button + ⋯ menu** —
/// FEATURE_2609_80 / 08.
///
/// **File**: lib/features/master_product/presentation/widgets/cell_actions.dart
/// **Web original**: `master-products/[id]/components/CellActions.tsx` @09208a0
///
/// - Primary: draft = Coupang [쿠팡에 올리기] (option picker sheet, D43) /
///   other platforms [마켓 등록] · unsynced changes (`needsMarketSync`) =
///   [수정 요청] · otherwise none.
/// - ⋯ menu: 편집 (field values · detail · price · stock · option names ·
///   shipping · options to upload) / 동기화 (update request · approval refresh ·
///   regenerate · apply master option names) / 연결 (쿠팡에서 보기 ·
///   master category) / red items under a divider ([마스터 연결 해제] ·
///   [채널 삭제]).
/// - Result lines (success · failure · approval result) show under the buttons.
///
/// ⚠️ [쿠팡에서 보기] opens the phone's browser (D82 · R20) — this file is the
///    only place that imports `url_launcher`.
/// ⚠️ [cells] = this row's own cell only — passing every cell multiplies the
///    unlink/delete items.
/// ❌ Do not add confirmations beyond the five here (D23).
class CellActions extends StatefulWidget {
  final int masterId;
  final int listingId;
  final String status;
  final List<MasterOption> options;
  final VoidCallback onReload;
  final int accountId;
  final String platform;
  final String channelLabel;
  final Map<String, String>? shippingOverride;

  /// `false` = register guard (disabled + reason). `null` = not judged → allow.
  final bool? shippingReady;
  final ValueChanged<GeneratedProduct> onShippingSaved;

  /// Server judgement — `false` hides [마스터 카테고리로 변경].
  final bool usesOwnCategory;
  final String? channelCategoryLabel;
  final String? masterCategoryName;

  /// Cells the unlink/delete items act on (2609_63/D10-1).
  final List<MatrixCell> cells;

  /// Unlink/delete success — the parent shows a banner and reloads.
  final ValueChanged<String> onCellRemoved;

  /// Local changes not on the market yet → [수정 요청] is the primary.
  final bool needsMarketSync;

  const CellActions({
    required this.masterId,
    required this.listingId,
    required this.status,
    required this.options,
    required this.onReload,
    required this.accountId,
    required this.platform,
    required this.channelLabel,
    required this.shippingOverride,
    required this.shippingReady,
    required this.onShippingSaved,
    required this.usesOwnCategory,
    required this.channelCategoryLabel,
    required this.masterCategoryName,
    required this.cells,
    required this.onCellRemoved,
    required this.needsMarketSync,
    super.key,
  });

  @override
  State<CellActions> createState() => _CellActionsState();
}

class _CellActionsState extends State<CellActions> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  String? _busy;
  String _error = '';
  ListingStatusResult? _statusResult;
  // [수정 요청] etc. success notice. Cleared whenever another action starts.
  String _pushedBanner = '';

  int get _listingId => widget.listingId;

  // The fetch-status result (when present) is fresher than the matrix value.
  String get _status => _statusResult?.status ?? widget.status;

  bool get _hasShippingOverride {
    final o = widget.shippingOverride;
    return o != null && o.isNotEmpty;
  }

  // Strict false — null means "not judged" → allow.
  bool get _shippingBlocked => widget.shippingReady == false;

  String? get _primary {
    if (_status == ListingStatusCode.draft) {
      return widget.platform == 'COUPANG' ? _primaryUpload : _primaryRegister;
    }
    return widget.needsMarketSync ? _primaryUpdate : null;
  }

  String _optionName(int id) {
    final match = widget.options.where((o) => o.id == id);
    return match.isEmpty ? '옵션 #$id' : match.first.name;
  }

  void _begin(String kind) => setState(() {
        _busy = kind;
        _error = '';
        _pushedBanner = '';
      });

  void _end() {
    if (mounted) {
      setState(() => _busy = null);
    }
  }

  // Shows the server/Coupang reason as-is.
  void _fail(Failure failure, String fallback) {
    if (mounted) {
      setState(() => _error = failureText(failure, fallback));
    }
  }

  Future<void> _handleRegister() async {
    _begin(_busyRegister);
    final res = await _useCase.registerListing(_listingId);
    res.fold(
      (f) => _fail(f, '요청에 실패했습니다.'),
      (_) => widget.onReload(),
    );
    _end();
  }

  // Forced re-push of an already-registered cell (109).
  Future<void> _handleUpdateRequest() async {
    _begin(_busyUpdate);
    final res = await _useCase.requestListingUpdate(_listingId);
    if (!mounted) {
      return;
    }
    res.fold(
      (f) => _fail(f, '수정 요청에 실패했습니다.'),
      (_) {
        setState(() {
          _pushedBanner = '승인 대기중으로 전환됨';
          // The previous fetch-status result is stale now.
          _statusResult = null;
        });
        widget.onReload();
      },
    );
    _end();
  }

  // Channel category → master category (2609_45/D13).
  Future<void> _handleCategorySource() async {
    _begin(_busyCategorySource);
    final res =
        await _useCase.setCategorySource(_listingId, useMasterCategory: true);
    if (!mounted) {
      return;
    }
    res.fold(
      (f) => _fail(f, '마스터 카테고리로 변경하지 못했습니다.'),
      (_) {
        setState(() => _pushedBanner =
            '마스터 카테고리로 변경했습니다. 다음 수정 요청 때 쿠팡에 반영됩니다.');
        widget.onReload();
      },
    );
    _end();
  }

  // 「마스터 옵션명 반영」(2609_74/D15).
  Future<void> _handleApplyNames() async {
    _begin(_busyApplyNames);
    final res = await _useCase.applyMasterOptionNamesToListing(_listingId);
    if (!mounted) {
      return;
    }
    res.fold(
      (f) => _fail(f, '마스터 옵션명을 반영하지 못했습니다.'),
      (r) {
        final skipped = r.skippedAwaitingId;
        final skippedText = skipped.isNotEmpty
            ? '옵션 ID 를 받기 전인 옵션 ${skipped.length}개는 건너뛰었습니다(${skipped.join(', ')}).'
            : '';
        final changedText = r.updatedOptions > 0
            ? '${r.updatedOptions}개 옵션의 이름을 마스터 기준으로 바꿨습니다.'
            : skipped.isNotEmpty
                ? ''
                : '바꿀 옵션명이 없습니다 — 이미 마스터와 같습니다.';
        setState(() => _pushedBanner =
            [changedText, skippedText].where((t) => t != '').join(' '));
        widget.onReload();
      },
    );
    _end();
  }

  // Unlink from the master (2609_63/D3). 🔴 Target = the cell the item passed.
  Future<void> _handleUnlink(MatrixCell cell) async {
    _begin(_busyUnlink);
    final res =
        await _useCase.unlinkChannel(widget.masterId, cell.productListingId);
    res.fold(
      (f) => _fail(f, '마스터 연결을 해제하지 못했습니다.'),
      (_) => widget.onCellRemoved(
        '마스터 연결을 해제했습니다. 판매상품 목록의 「마스터 미연결만」에서 볼 수 있습니다.',
      ),
    );
    _end();
  }

  // Delete a never-sent channel (2609_63/D13).
  Future<void> _handleDeleteCell(MatrixCell cell) async {
    _begin(_busyDeleteCell);
    final res = await _useCase.deleteDraftChannel(
      widget.masterId,
      cell.productListingId,
    );
    res.fold(
      (f) => _fail(f, '채널을 삭제하지 못했습니다.'),
      (_) => widget.onCellRemoved('채널을 삭제했습니다.'),
    );
    _end();
  }

  Future<void> _handleFetch() async {
    _begin(_busyFetch);
    final res = await _useCase.fetchListingStatus(_listingId);
    if (!mounted) {
      return;
    }
    res.fold(
      (f) => _fail(f, '요청에 실패했습니다.'),
      (r) {
        setState(() => _statusResult = r);
        widget.onReload();
      },
    );
    _end();
  }

  Future<void> _handleRegenerate() async {
    _begin(_busyRegenerate);
    final res = await _useCase.regenerate(_listingId);
    res.fold(
      (f) => _fail(f, '요청에 실패했습니다.'),
      (_) => widget.onReload(),
    );
    _end();
  }

  // ── Confirmations (D23 · D29 · D32) ────────────────────────────────────

  Future<void> _confirmUpdateRequest() async {
    final ok = await showMasterConfirmDialog(
      context,
      title: '수정 요청',
      message: '수정한 값을 마켓에 다시 보내고 재심사를 요청합니다. 계속하시겠습니까?',
      confirmText: '수정 요청',
    );
    if (ok && mounted) {
      await _handleUpdateRequest();
    }
  }

  Future<void> _confirmCategorySource() async {
    final ok = await showMasterConfirmDialog(
      context,
      title: '마스터 카테고리로 변경',
      message: '이 채널의 카테고리를 마스터 카테고리로 바꿉니다.\n'
          '${widget.channelCategoryLabel ?? '채널 카테고리'} → '
          '${widget.masterCategoryName ?? '마스터 카테고리'}\n'
          '지금 쿠팡에 반영되지는 않습니다. 다음 [수정 요청] 때 함께 전송되며, 그때 쿠팡에서 '
          '카테고리가 변경되고 재심사에 들어갑니다. 이 카테고리에 맞춰 넣어둔 필수 속성·고시 값은 '
          '지워집니다.',
      confirmText: '변경',
    );
    if (ok && mounted) {
      await _handleCategorySource();
    }
  }

  Future<void> _confirmApplyNames() async {
    final ok = await showMasterConfirmDialog(
      context,
      title: '마스터 옵션명 반영',
      message: '${widget.channelLabel} 채널의 옵션명을 마스터 옵션 이름으로 바꿉니다.\n'
          '• 이 채널에서 직접 정했거나 쿠팡에서 가져온 옵션명이 마스터 이름으로 바뀝니다.\n'
          '• 쿠팡에 올렸지만 옵션 ID 를 아직 받지 못한 옵션은 건너뜁니다(판매상품이 승인반려 상태면 '
          '바꿉니다 — 마지막 [승인 새로고침] 결과 기준).\n'
          '• 지금 쿠팡에 반영되지는 않습니다. 쿠팡에 올라간 옵션의 이름이 바뀌면 「변경 미반영」이 '
          '표시되고, [수정 요청]을 눌러야 전송됩니다.',
      confirmText: '반영',
    );
    if (ok && mounted) {
      await _handleApplyNames();
    }
  }

  Future<void> _confirmUnlink(MatrixCell cell) async {
    final pid = cell.platformProductId;
    final ok = await showMasterConfirmDialog(
      context,
      title: '마스터 연결 해제',
      message: '${widget.channelLabel} 채널'
          '${pid != null && pid.isNotEmpty ? ' (상품 ID $pid)' : ''}을 '
          '이 마스터에서 떼어냅니다.\n'
          '• 쿠팡에는 아무것도 전송하지 않습니다 — 상품은 그대로 팔립니다.\n'
          '• 주문·고객문의·정산 기록은 이 판매상품에 그대로 남습니다.\n'
          '• 해제하면 판매상품 목록의 「마스터 미연결만」에서 볼 수 있습니다.\n'
          '• 올바른 마스터에서 [마켓 상품 추가하기] 에 같은 상품 ID 를 넣으면 이 판매상품이 그대로 '
          '다시 붙습니다.',
      confirmText: '연결 해제',
      isDangerous: true,
    );
    if (ok && mounted) {
      await _handleUnlink(cell);
    }
  }

  Future<void> _confirmDeleteCell(MatrixCell cell) async {
    final ok = await showMasterConfirmDialog(
      context,
      title: '채널 삭제',
      message: '${widget.channelLabel} 채널 1줄을 지웁니다. 아직 쿠팡에 보낸 적이 없는 채널입니다.\n'
          '• 이 채널의 옵션·구성·자동 생성된 썸네일·상세가 함께 지워집니다.\n'
          '• 쿠팡에는 아무것도 전송하지 않습니다.\n'
          '• 되돌릴 수 없습니다 — 다시 만들려면 [채널 추가] 를 쓰세요.',
      confirmText: '삭제',
      isDangerous: true,
    );
    if (ok && mounted) {
      await _handleDeleteCell(cell);
    }
  }

  // ── Windows (pages · sheets) ───────────────────────────────────────────

  Future<void> _openFieldValues() async {
    final r = await context.pushNamed<GeneratedProduct>(
      Routes.masterChannelFieldValues,
      extra: ChannelFieldValuesArgs(listingId: _listingId),
    );
    if (r != null) {
      widget.onReload();
    }
  }

  Future<void> _openOptionsPage(String routeName) async {
    final r = await context.pushNamed<bool>(
      routeName,
      extra: ChannelOptionsArgs(
        listingId: _listingId,
        channelLabel: widget.channelLabel,
      ),
    );
    if (r == true) {
      widget.onReload();
    }
  }

  Future<void> _openShipping() async {
    final r = await context.pushNamed<GeneratedProduct>(
      Routes.masterChannelShipping,
      extra: ChannelShippingArgs(
        listingId: _listingId,
        accountId: widget.accountId,
        platform: widget.platform,
        channelLabel: widget.channelLabel,
        initialOverride: widget.shippingOverride,
      ),
    );
    if (r != null) {
      widget.onShippingSaved(r);
    }
  }

  Future<void> _openOptionPicker(String mode) async {
    final done = await showListingOptionPickerSheet(
      context,
      mode: mode,
      listingId: _listingId,
      channelLabel: widget.channelLabel,
    );
    if (done) {
      widget.onReload();
    }
  }

  Future<void> _openWing(String sellerProductId) async {
    final opened = await launchUrl(
      Uri.parse(_coupangWingUrl(sellerProductId)),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      showErrorToast(context, '브라우저를 열지 못했습니다.');
    }
  }

  void _openDetailEdit() => context.pushNamed(
        Routes.masterProductDetailEdit,
        pathParameters: {
          'id': '${widget.masterId}',
          'listingId': '$_listingId',
        },
      );

  // ── Menu ───────────────────────────────────────────────────────────────

  List<_MenuGroup> get _menuGroups {
    final status = _status;
    final isDraft = status == ListingStatusCode.draft;
    return [
      _MenuGroup(
        label: '편집',
        items: [
          _MenuItem(key: 'fields', label: '필드값 편집', onTap: _openFieldValues),
          _MenuItem(key: 'detail', label: '상세 편집', onTap: _openDetailEdit),
          // Price · stock · option names are set before registration too.
          _MenuItem(
            key: 'price',
            label: '가격 설정',
            onTap: () => _openOptionsPage(Routes.masterChannelPrice),
          ),
          _MenuItem(
            key: 'stock',
            label: '재고 설정',
            onTap: () => _openOptionsPage(Routes.masterChannelStock),
          ),
          _MenuItem(
            key: 'option-name',
            label: '옵션명',
            onTap: () => _openOptionsPage(Routes.masterChannelOptionName),
          ),
          _MenuItem(
            key: 'shipping',
            label: '채널 배송 설정${_hasShippingOverride ? ' ✓' : ''}',
            onTap: _openShipping,
          ),
          // After upload; a draft picks options in [쿠팡에 올리기].
          if (!isDraft)
            _MenuItem(
              key: 'option-picker',
              label: '올릴 옵션 고르기',
              onTap: () => _openOptionPicker('select'),
            ),
        ],
      ),
      _MenuGroup(
        label: '동기화',
        items: [
          if (!isDraft && _primary != _primaryUpdate)
            _MenuItem(
              key: 'update',
              label: '수정 요청',
              onTap: _confirmUpdateRequest,
            ),
          // Rejected must stay re-checkable → REJECTED too.
          if (status == ListingStatusCode.submitted ||
              status == ListingStatusCode.selling ||
              status == ListingStatusCode.rejected)
            _MenuItem(key: 'fetch', label: '승인 새로고침', onTap: _handleFetch),
          if (status == ListingStatusCode.selling)
            _MenuItem(
              key: 'regenerate',
              label: '재생성',
              onTap: _handleRegenerate,
            ),
          _MenuItem(
            key: 'apply-names',
            label: '마스터 옵션명 반영',
            onTap: _confirmApplyNames,
          ),
        ],
      ),
      _MenuGroup(
        label: '연결',
        items: [
          for (final c in widget.cells)
            if (widget.platform == 'COUPANG' &&
                c.platformProductId != null &&
                c.platformProductId!.isNotEmpty)
              _MenuItem(
                key: 'market-${c.productListingId}',
                label: '쿠팡에서 보기 ↗',
                onTap: () => _openWing(c.platformProductId!),
              ),
          if (widget.usesOwnCategory)
            _MenuItem(
              key: 'category-source',
              label: '마스터 카테고리로 변경',
              onTap: _confirmCategorySource,
            ),
        ],
      ),
    ];
  }

  // Destructive items: unlink when a market ID exists, delete otherwise.
  List<_MenuItem> get _dangerItems {
    final many = widget.cells.length > 1;
    return [
      for (final c in widget.cells)
        if (c.platformProductId != null && c.platformProductId!.isNotEmpty)
          _MenuItem(
            key: 'unlink-${c.productListingId}',
            label: '마스터 연결 해제${many ? ' · ${c.platformProductId}' : ''}',
            onTap: () => _confirmUnlink(c),
          )
        else
          _MenuItem(
            key: 'delete-${c.productListingId}',
            label: '채널 삭제${many ? ' · 미전송' : ''}',
            onTap: () => _confirmDeleteCell(c),
          ),
    ];
  }

  Widget _menuButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final groups = _menuGroups.where((g) => g.items.isNotEmpty).toList();
    final danger = _dangerItems;
    final actions = <String, VoidCallback>{
      for (final g in groups)
        for (final item in g.items) item.key: item.onTap,
      for (final item in danger) item.key: item.onTap,
    };
    final busy = _busy;
    return PopupMenuButton<String>(
      icon: busy != null && busy != _primary
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.more_horiz),
      tooltip: '더 보기',
      enabled: busy == null,
      onSelected: (key) => actions[key]?.call(),
      itemBuilder: (_) => [
        for (final g in groups) ...[
          PopupMenuItem<String>(
            enabled: false,
            height: 24,
            child: Text(
              g.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final item in g.items)
            PopupMenuItem<String>(
              value: item.key,
              child: Text(item.label, style: const TextStyle(fontSize: 12)),
            ),
        ],
        if (danger.isNotEmpty) ...[
          const PopupMenuDivider(),
          for (final item in danger)
            PopupMenuItem<String>(
              value: item.key,
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: scheme.error,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _primaryButton(BuildContext context) {
    final primary = _primary;
    final busy = _busy;
    final blockedIcon = _shippingBlocked
        ? const InfoBubbleIcon(message: kShippingBlockedReason)
        : null;
    ButtonStyle style(Color color) => OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          foregroundColor: color,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        );
    switch (primary) {
      case _primaryUpload:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: busy != null || _shippingBlocked
                  ? null
                  : () => _openOptionPicker('upload'),
              style: style(AppColors.infoForeground),
              child: const Text('쿠팡에 올리기'),
            ),
            if (blockedIcon != null) blockedIcon,
          ],
        );
      case _primaryRegister:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed:
                  busy != null || _shippingBlocked ? null : _handleRegister,
              style: style(AppColors.infoForeground),
              child: busy == _busyRegister
                  ? const _BusyLabel('요청 중...')
                  : const Text('마켓 등록'),
            ),
            if (blockedIcon != null) blockedIcon,
          ],
        );
      case _primaryUpdate:
        return OutlinedButton(
          onPressed: busy != null ? null : _confirmUpdateRequest,
          style: style(AppColors.warningForeground),
          child: busy == _busyUpdate
              ? const _BusyLabel('요청 중...')
              : const Text('수정 요청'),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusResult = _statusResult;
    final hasFeedback =
        (_status == ListingStatusCode.draft && _shippingBlocked) ||
            _pushedBanner.isNotEmpty ||
            statusResult != null ||
            _error.isNotEmpty;
    final small = TextStyle(fontSize: 11, color: scheme.onSurfaceVariant);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (_primary != null) _primaryButton(context),
            _menuButton(context),
          ],
        ),
        if (hasFeedback) ...[
          const SizedBox(height: 4),
          // A disabled button's reason is also shown as a visible line.
          if (_status == ListingStatusCode.draft && _shippingBlocked)
            Text(kShippingBlockedReason, style: small),
          if (_pushedBanner.isNotEmpty)
            Text(
              _pushedBanner,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.successForeground,
              ),
            ),
          if (statusResult != null)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (statusResult.status == ListingStatusCode.selling)
                  const Text(
                    '판매중으로 전환됨',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.successForeground,
                    ),
                  ),
                for (final o in statusResult.options)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: o.approvalStatus == 'APPROVED'
                          ? AppColors.successSurface
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _optionName(o.optionId),
                      style: TextStyle(
                        fontSize: 10,
                        color: o.approvalStatus == 'APPROVED'
                            ? AppColors.successForeground
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          // Review reasons are not stored — visible only right after a refresh.
          if (statusResult?.reviewNoteState == 'FOUND')
            Text(
              '심사 사유: ${statusResult?.reviewNote ?? ''}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.warningForeground,
              ),
            ),
          if (statusResult?.reviewNoteState == 'NOT_FOUND')
            Text('사유 기록을 찾지 못했습니다', style: small),
          if (statusResult?.reviewNoteState == 'FAILED')
            Text('사유를 불러오지 못했습니다', style: small),
          if (_error.isNotEmpty)
            Text(_error, style: TextStyle(fontSize: 11, color: scheme.error)),
        ],
      ],
    );
  }
}

/// Spinner + label (web `<Spinner label=… />`).
class _BusyLabel extends StatelessWidget {
  final String label;

  const _BusyLabel(this.label);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      );
}
