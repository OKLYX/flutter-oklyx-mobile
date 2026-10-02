import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/master_format.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_tool_args.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/quantity_stepper.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';

// Status enum → screen text. ⚠️ Never show the raw enum.
const Map<String, String> _statusLabel = {
  'DRAFT': '미전송',
  'SUBMITTED': '승인 대기중',
  'SELLING': '판매중',
  'REJECTED': '승인 반려',
  'SUSPENDED': '판매 중지',
};

// Dropdown value of the "create a new option" entry.
const String _newOption = 'new';

/// Keeps the backend message as-is and appends one actionable line only
/// (judged by HTTP status + message substring).
String _importErrorMessage(Failure f) {
  final status = f is ServerFailure ? f.statusCode : null;
  final message = failureText(f, '가져오기에 실패했습니다.');
  if (status == 429) {
    return '잠시 후 다시 시도하세요.';
  }
  if (status == 400 && message.contains('이미 다른 상품에 연결된')) {
    return '$message 그 마스터에서 [마스터 연결 해제] 한 뒤 다시 시도하세요.';
  }
  if ((status == 400 || status == 404) && message.contains('계정')) {
    return '$message 판매자 관리에서 쿠팡 계정을 먼저 등록·활성화하세요.';
  }
  return message;
}

/// Option identity key. Unapproved options have no vendorItemId → itemName.
String _optionKey(ImportPreviewOption o) => o.vendorItemId ?? o.itemName;

/// One option's input. [masterOptionId] `null` = web `'new'` (no option with
/// the same quantities → a new one is created).
class _OptionDraft {
  final int? masterOptionId;

  /// Used only when creating a new option (default = the Coupang option name).
  final String masterOptionName;

  /// productId → typed string (parsed once right before submit).
  final Map<int, String> quantities;

  const _OptionDraft({
    required this.masterOptionId,
    required this.masterOptionName,
    required this.quantities,
  });

  _OptionDraft copyWith({
    int? masterOptionId,
    bool clearMasterOption = false,
    String? masterOptionName,
    Map<int, String>? quantities,
  }) =>
      _OptionDraft(
        masterOptionId:
            clearMasterOption ? null : (masterOptionId ?? this.masterOptionId),
        masterOptionName: masterOptionName ?? this.masterOptionName,
        quantities: quantities ?? this.quantities,
      );
}

/// The master option whose composition **exactly** matches the typed
/// quantities (same rule as the server). `null` when none.
MasterOption? _matchMasterOption(
  List<int> componentIds,
  Map<int, String> quantities,
  List<MasterOption> masterOptions,
) {
  for (final o in masterOptions) {
    if (o.items.length != componentIds.length) {
      continue;
    }
    final allMatch = componentIds.every((id) {
      final item = o.items.where((it) => it.productId == id);
      return item.isNotEmpty &&
          item.first.quantity == num.tryParse(quantities[id] ?? '');
    });
    if (allMatch) {
      return o;
    }
  }
  return null;
}

/// Preview → initial inputs. Quantities start at 1 and the option with that
/// composition is preselected.
Map<String, _OptionDraft> _buildDraft(
  ImportPreview res,
  List<MasterOption> masterOptions,
) {
  final componentIds = res.components.map((c) => c.productId).toList();
  return {
    for (final o in res.options)
      _optionKey(o): () {
        final quantities = {for (final id in componentIds) id: '1'};
        return _OptionDraft(
          masterOptionId:
              _matchMasterOption(componentIds, quantities, masterOptions)?.id,
          masterOptionName: o.itemName,
          quantities: quantities,
        );
      }(),
  };
}

bool _isPositiveInt(String raw) {
  final v = num.tryParse(raw.trim());
  return raw.trim() != '' && v != null && v == v.truncateToDouble() && v >= 1;
}

/// 「마켓 상품 추가하기」 page (2609_22 → 2609_79 / UX D42 · D78) — attaches a
/// product already on the market to an **existing master** — FEATURE_2609_80 / 08.
///
/// **File**: lib/features/master_product/presentation/pages/market_product_add_page.dart
/// **Web original**: `master-products/[id]/components/ImportCoupangProductModal.tsx` @09208a0
///
/// Two steps — ① look up by product ID ② per option pick a master option or
/// fill the component quantities, then [가져오기] (the two always agree).
/// - Seller and platform come from the matrix row (shown, not editable).
/// - With `initialProductId` (picked from the detached list) the lookup runs
///   right away.
/// - ⚠️ No price/stock inputs — the server re-reads Coupang on commit.
/// - ⚠️ The preview is never cached.
///
/// Result: `MarketProductAddResult` on success (`null` = closed).
/// ⚠️ Shared by every entry (channel row button · detached listing picker ·
///    「마켓 상품으로 시작」). ❌ Do not build a second copy per entry.
class MarketProductAddPage extends StatefulWidget {
  final MarketProductAddArgs args;

  const MarketProductAddPage({required this.args, super.key});

  @override
  State<MarketProductAddPage> createState() => _MarketProductAddPageState();
}

class _MarketProductAddPageState extends State<MarketProductAddPage> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();
  final TextEditingController _productIdController = TextEditingController();
  // One controller per option key for the new option name (R2).
  final Map<String, TextEditingController> _nameControllers = {};

  String _productId = '';
  ImportPreview? _preview;
  Map<String, _OptionDraft> _draft = {};
  bool _busy = false;
  String _error = '';

  MarketProductAddArgs get _args => widget.args;

  @override
  void initState() {
    super.initState();
    final initial = _args.initialProductId;
    _productId = initial ?? '';
    _productIdController.text = _productId;
    // Picked from the detached list → look up immediately.
    if (initial != null) {
      _busy = true;
      unawaited(_initialLookup(initial));
    }
  }

  @override
  void dispose() {
    _productIdController.dispose();
    for (final c in _nameControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _nameControllerFor(String key) =>
      _nameControllers.putIfAbsent(key, TextEditingController.new);

  void _seed(ImportPreview res) {
    _preview = res;
    _draft = _buildDraft(res, _args.masterOptions);
    for (final entry in _draft.entries) {
      _nameControllerFor(entry.key).text = entry.value.masterOptionName;
    }
  }

  Future<void> _initialLookup(String platformProductId) async {
    final res = await _useCase.importPreview(
      _args.masterId,
      sellerId: _args.sellerId,
      platform: _args.platform,
      platformProductId: platformProductId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      res.fold(
        (failure) => _error = _importErrorMessage(failure),
        _seed,
      );
      _busy = false;
    });
  }

  Future<void> _handleLookup() async {
    setState(() {
      _busy = true;
      _error = '';
      // A new lookup drops the previous result and inputs.
      _preview = null;
      _draft = {};
    });
    final res = await _useCase.importPreview(
      _args.masterId,
      sellerId: _args.sellerId,
      platform: _args.platform,
      platformProductId: _productId.trim(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      res.fold(
        (failure) => _error = _importErrorMessage(failure),
        _seed,
      );
      _busy = false;
    });
  }

  _OptionDraft _rowOf(String key) =>
      _draft[key] ??
      const _OptionDraft(
        masterOptionId: null,
        masterOptionName: '',
        quantities: {},
      );

  void _patchRow(String key, _OptionDraft next) =>
      setState(() => _draft = {..._draft, key: next});

  // A name is needed only when a new option is created.
  bool get _nameMissing {
    final preview = _preview;
    return preview != null &&
        preview.options.any((o) {
          final row = _rowOf(_optionKey(o));
          return row.masterOptionId == null &&
              row.masterOptionName.trim() == '';
        });
  }

  bool get _quantityInvalid {
    final preview = _preview;
    return preview != null &&
        preview.options.any(
          (o) => preview.components.any(
            (c) => !_isPositiveInt(
              _rowOf(_optionKey(o)).quantities[c.productId] ?? '',
            ),
          ),
        );
  }

  bool get _canImport =>
      _preview != null && !_nameMissing && !_quantityInvalid && !_busy;

  void _close() {
    if (_busy) {
      return;
    }
    context.pop();
  }

  Future<void> _handleImport() async {
    final preview = _preview;
    if (preview == null || _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    final options = <ImportOptionSpec>[];
    for (final o in preview.options) {
      final row = _rowOf(_optionKey(o));
      final picked = _args.masterOptions
          .where((m) => m.id == row.masterOptionId)
          .firstOrNull;
      options.add(
        ImportOptionSpec(
          vendorItemId: o.vendorItemId,
          itemName: o.itemName,
          // Used by the server only when creating a new option; a picked
          // option sends its own name (blank is rejected).
          masterOptionName:
              picked != null ? picked.name : row.masterOptionName.trim(),
          components: [
            for (final c in preview.components)
              MasterItemQuantity(
                productId: c.productId,
                quantity: int.parse(row.quantities[c.productId]!.trim()),
              ),
          ],
        ),
      );
    }
    final res = await _useCase.importListing(
      _args.masterId,
      sellerId: _args.sellerId,
      platform: _args.platform,
      platformProductId: _productId.trim(),
      options: options,
    );
    if (!mounted) {
      return;
    }
    res.fold(
      (failure) => setState(() {
        _error = _importErrorMessage(failure);
        _busy = false;
      }),
      // ⚠️ The commit re-reads Coupang, so a warning may arrive only here.
      (added) {
        _busy = false;
        context.pop(
          MarketProductAddResult(categoryWarning: added.categoryWarning),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = _preview;
    final lockedToInitial = _args.initialProductId != null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _close();
        }
      },
      child: ScaffoldWithNavBar(
        title: '마켓 상품 추가하기',
        navBarIndex: 2,
        onBackPressed: _close,
        body: AppPageBody(
          children: [
            Text(
              '${_args.sellerName} · ${_args.platform}',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _productIdController,
                    enabled: !_busy && !lockedToInitial,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '쿠팡 상품 ID'),
                    onChanged: (next) => setState(() => _productId = next),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed:
                      _productId.trim() == '' || _busy || lockedToInitial
                          ? null
                          : _handleLookup,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.infoForeground,
                  ),
                  child: Text(_busy && preview == null ? '조회 중…' : '조회'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error.isNotEmpty) ...[
              AppErrorBox(message: _error),
              const SizedBox(height: 12),
            ],
            if (preview != null) ..._previewSection(context, preview),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _busy ? null : _close,
                  child: const Text('취소'),
                ),
                if (preview != null) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _canImport ? _handleImport : null,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: _busy
                        ? const AppBusyLabel('가져오는 중…')
                        : const Text('가져오기'),
                  ),
                ],
              ],
            ),
            // Never hide why the button is disabled.
            if (preview != null && !_busy && _nameMissing) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '새 옵션 이름을 모두 입력하세요',
                  style:
                      TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
            if (preview != null && !_busy && !_nameMissing && _quantityInvalid)
              ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '수량은 1 이상의 정수여야 합니다',
                  style:
                      TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _previewSection(BuildContext context, ImportPreview preview) {
    final scheme = Theme.of(context).colorScheme;
    final warning = preview.categoryWarning;
    return [
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: preview.productName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: ' · ${_statusLabel[preview.status] ?? preview.status} · '
                  '카테고리 ${preview.categoryCode} · '
                  '태그 ${preview.channelTags.length}개',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 14),
      ),
      const SizedBox(height: 8),
      if (preview.reusesExistingListing) ...[
        const _Banner(
          text: '이 쿠팡 상품에는 마스터 연결이 끊긴 판매상품이 있습니다. 새로 만들지 않고 그 판매상품을 '
              '이 마스터에 다시 붙입니다 — 주문·고객문의·정산 기록이 함께 따라옵니다. 판매가·옵션명은 '
              '쿠팡의 현재 값으로 들어오니, 이 마스터 기준으로 자동 계산하려면 가져온 뒤 [가격 설정] → '
              '[기본값으로 변경] 을 누르세요.',
          background: AppColors.infoSurface,
          foreground: AppColors.infoForeground,
        ),
        const SizedBox(height: 8),
      ],
      if (warning != null && warning.isNotEmpty) ...[
        _Banner(
          text: warning,
          background: AppColors.warningSurface,
          foreground: AppColors.warningForeground,
        ),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 4),
      for (final o in preview.options) ...[
        _optionCard(context, preview, o),
        const SizedBox(height: 12),
      ],
      Text(
        '마스터 옵션을 고르면 수량이 그 옵션 값으로 채워지고, 수량을 바꾸면 같은 수량의 옵션이 골라집니다.\n'
        '같은 수량의 옵션이 없으면 새 옵션이 만들어집니다.',
        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
      ),
    ];
  }

  Widget _optionCard(
    BuildContext context,
    ImportPreview preview,
    ImportPreviewOption o,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final key = _optionKey(o);
    final row = _rowOf(key);
    final componentIds = preview.components.map((c) => c.productId).toList();
    final masterOptions = _args.masterOptions;
    final isNew = row.masterOptionId == null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  o.itemName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '판매가 ${koNumber(o.salePrice)}'
                '${o.stockQuantity != null ? ' · 재고 ${o.stockQuantity}' : ''}',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            // Rebuild when a quantity change re-picks the option.
            key: ValueKey('$key:${row.masterOptionId}'),
            initialValue: isNew ? _newOption : '${row.masterOptionId}',
            isExpanded: true,
            decoration: const InputDecoration(labelText: '마스터 옵션'),
            items: [
              for (final m in masterOptions)
                DropdownMenuItem<String>(
                  value: '${m.id}',
                  child: Text(
                    '${m.name} (${m.items.map((it) => '${it.productName}×${it.quantity}').join(', ')})',
                  ),
                ),
              // 'new' cannot be picked by hand — it only reflects "no match".
              DropdownMenuItem<String>(
                value: _newOption,
                enabled: isNew,
                child: const Text('새 옵션 만들기'),
              ),
            ],
            onChanged: _busy
                ? null
                : (value) {
                    final picked = masterOptions
                        .where((m) => '${m.id}' == value)
                        .firstOrNull;
                    if (picked == null) {
                      return;
                    }
                    _patchRow(
                      key,
                      row.copyWith(
                        masterOptionId: picked.id,
                        quantities: {
                          for (final id in componentIds)
                            id: '${picked.items.where((it) => it.productId == id).firstOrNull?.quantity ?? 1}',
                        },
                      ),
                    );
                  },
          ),
          if (isNew) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _nameControllerFor(key),
              enabled: !_busy,
              decoration: const InputDecoration(labelText: '새 옵션 이름'),
              onChanged: (next) =>
                  _patchRow(key, _rowOf(key).copyWith(masterOptionName: next)),
            ),
            const SizedBox(height: 4),
            Text(
              row.masterOptionName.trim() == ''
                  ? '새 옵션 이름을 입력하세요'
                  : '이 수량과 같은 옵션이 마스터에 없어 새 옵션을 만듭니다.',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '구성',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          for (final c in preview.components) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${c.brand != null && c.brand!.isNotEmpty ? '${c.brand} ' : ''}${c.productName}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                QuantityStepper(
                  value: row.quantities[c.productId] ?? '',
                  disabled: _busy,
                  onChanged: (next) {
                    final current = _rowOf(key);
                    final quantities = {
                      ...current.quantities,
                      c.productId: next,
                    };
                    // D31: changing a quantity re-picks the matching option.
                    final match = _matchMasterOption(
                      componentIds,
                      quantities,
                      masterOptions,
                    );
                    _patchRow(
                      key,
                      current.copyWith(
                        quantities: quantities,
                        masterOptionId: match?.id,
                        clearMasterOption: match == null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Colored line (web `rounded bg-… px-3 py-2 text-sm text-…`).
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text, style: TextStyle(fontSize: 14, color: foreground)),
      );
}
