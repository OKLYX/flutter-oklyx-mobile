import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_tool_args.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/listing_margin.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';

/// Web `String(number)` — integers without a decimal point.
String _jsString(num v) =>
    v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

/// Per-channel (cell) option selling price page (2609_19) — FEATURE_2609_80 / 08.
///
/// **File**: lib/features/master_product/presentation/pages/channel_price_page.dart
/// **Web original**: `master-products/[id]/components/ChannelPriceModal.tsx` @09208a0
///
/// The selling price is the margin-derived auto price; this page overrides it
/// for **this channel only**.
/// - Inputs are prefilled with the current value. A blank row locks [저장] —
///   use [기본값으로 변경] to go back to the auto price (sent as `null`).
/// - Save **pushes to the market** too; the result (pushed / skipped / failed)
///   is shown on this page.
/// - Inactive options are hidden.
/// - FEATURE_2610_27 / D6 · D7 · D20 · D21 · D38: under each input, the margin
///   of the typed price ([MarginPreviewText], asked 300 ms after typing stops)
///   — red when under the margin preset minimum. It never blocks a save.
///
/// Result: `true` once something was saved (`null` = closed without saving).
/// ⚠️ A partial result (skipped or failed rows) keeps the page open so the
///    failures stay visible — back then returns `true`.
/// FEATURE_2610_26 / D53 ②: a Gmarket · Auction (ESM) option
/// (`auctionSellingPrice != null`) has two fields, 「G마켓」 and 「옥션」, each
/// with its own [기본값으로 변경]. An untouched field is sent as its current
/// value when it was set by hand and as `null` when it is automatic, so saving
/// one site never changes the other site's origin.
class ChannelPricePage extends StatefulWidget {
  final ChannelOptionsArgs args;

  const ChannelPricePage({required this.args, super.key});

  @override
  State<ChannelPricePage> createState() => _ChannelPricePageState();
}

class _ChannelPricePageState extends State<ChannelPricePage> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();
  // One controller per option id (R2).
  final Map<int, TextEditingController> _controllers = {};

  List<ListingOptionSummary> _rows = [];
  // Per-row input buffer — parsed once on save.
  Map<int, String> _draft = {};
  // Rows where [기본값으로 변경] is on — saved as sellingPrice: null.
  Set<int> _restore = {};
  // FEATURE_2610_26 / D53 ②: the Auction field of an ESM option — its own
  // controller, input buffer and [기본값으로 변경].
  final Map<int, TextEditingController> _auctionControllers = {};
  Map<int, String> _draftAuction = {};
  Set<int> _restoreAuction = {};
  ChannelPriceUpdateResult? _saveResult;
  bool _isLoading = true;
  bool _isSaving = false;
  String _error = '';
  bool? _result;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant ChannelPricePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.args.listingId != widget.args.listingId) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final c in _auctionControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int optionId) =>
      _controllers.putIfAbsent(optionId, TextEditingController.new);

  TextEditingController _auctionControllerFor(int optionId) =>
      _auctionControllers.putIfAbsent(optionId, TextEditingController.new);

  // Server response → reseed. [keep] = rows the market rejected (NOT saved) —
  // only those keep their input buffer and restore state.
  void _applyOptions(List<ListingOptionSummary> options, [Set<int>? keep]) {
    final kept = keep ?? <int>{};
    final visible = options.where((o) => o.active).toList();
    final prev = _draft;
    _rows = visible;
    _draft = {
      for (final o in visible)
        o.optionId: kept.contains(o.optionId)
            ? (prev[o.optionId] ?? _jsString(o.sellingPrice))
            : _jsString(o.sellingPrice),
    };
    for (final o in visible) {
      final controller = _controllerFor(o.optionId);
      if (controller.text != _draft[o.optionId]) {
        controller.text = _draft[o.optionId]!;
      }
    }
    _restore = _restore.where(kept.contains).toSet();
    final prevAuction = _draftAuction;
    _draftAuction = {
      for (final o in visible)
        if (o.auctionSellingPrice != null)
          o.optionId: kept.contains(o.optionId)
              ? (prevAuction[o.optionId] ?? _jsString(o.auctionSellingPrice!))
              : _jsString(o.auctionSellingPrice!),
    };
    for (final e in _draftAuction.entries) {
      final controller = _auctionControllerFor(e.key);
      if (controller.text != e.value) {
        controller.text = e.value;
      }
    }
    _restoreAuction = _restoreAuction.where(kept.contains).toSet();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final res = await _useCase.getListingOptions(widget.args.listingId);
    if (!mounted) {
      return;
    }
    setState(() {
      res.fold(
        (_) => _error = '옵션 판매가를 불러오지 못했습니다.',
        (listing) => _applyOptions(listing.options),
      );
      _isLoading = false;
    });
  }

  void _close() => context.pop(_result);

  String _raw(int id) => _draft[id] ?? '';

  num? _parsed(int id) => num.tryParse(_raw(id).trim());

  // Whole won only — the backend normalizes to won before saving/pushing.
  bool _validRow(int id) {
    final v = _parsed(id);
    return _raw(id).trim() != '' &&
        v != null &&
        v.isFinite &&
        v == v.truncateToDouble() &&
        v >= 10;
  }

  // FEATURE_2610_26 / D53 ②: the same helpers for the Auction field.
  String _rawAuction(int id) => _draftAuction[id] ?? '';

  num? _parsedAuction(int id) => num.tryParse(_rawAuction(id).trim());

  bool _validAuction(int id) {
    final v = _parsedAuction(id);
    return _rawAuction(id).trim() != '' &&
        v != null &&
        v.isFinite &&
        v == v.truncateToDouble() &&
        v >= 10;
  }

  bool _isEsmRow(ListingOptionSummary r) => r.auctionSellingPrice != null;

  bool _sellingTouched(ListingOptionSummary r) =>
      _restore.contains(r.optionId) || _parsed(r.optionId) != r.sellingPrice;

  bool _auctionTouched(ListingOptionSummary r) =>
      _isEsmRow(r) &&
      (_restoreAuction.contains(r.optionId) ||
          _parsedAuction(r.optionId) != r.auctionSellingPrice);

  bool get _invalid => _rows.any(
        (r) =>
            (!_restore.contains(r.optionId) && !_validRow(r.optionId)) ||
            (_isEsmRow(r) &&
                !_restoreAuction.contains(r.optionId) &&
                !_validAuction(r.optionId)),
      );

  List<ListingOptionSummary> get _dirty => _rows
      .where((r) => _sellingTouched(r) || _auctionTouched(r))
      .toList();

  void _toggleRestoreAuction(int optionId) => setState(() {
        final next = {..._restoreAuction};
        if (!next.remove(optionId)) {
          next.add(optionId);
        }
        _restoreAuction = next;
      });

  // D53 ②: an untouched site keeps its origin — its value when set by hand,
  // null when automatic.
  OptionPriceChange _esmChange(ListingOptionSummary r) => OptionPriceChange(
        optionId: r.optionId,
        sellingPrice: _restore.contains(r.optionId) ||
                (!_sellingTouched(r) &&
                    r.priceSource != GeneratedSourceCode.manualOverride)
            ? null
            : _parsed(r.optionId),
        esm: true,
        auctionSellingPrice: _restoreAuction.contains(r.optionId) ||
                (!_auctionTouched(r) &&
                    r.auctionPriceSource != GeneratedSourceCode.manualOverride)
            ? null
            : _parsedAuction(r.optionId),
      );

  void _toggleRestore(int optionId) => setState(() {
        final next = {..._restore};
        if (!next.remove(optionId)) {
          next.add(optionId);
        }
        _restore = next;
      });

  Future<void> _handleSave() async {
    final dirty = _dirty;
    if (dirty.isEmpty) {
      _close();
      return;
    }
    setState(() {
      _isSaving = true;
      _error = '';
      // Clear the previous partial banner — an old failure would read as new.
      _saveResult = null;
    });
    final res = await _useCase.setOptionPrices(
      widget.args.listingId,
      [
        for (final r in dirty)
          if (_isEsmRow(r))
            _esmChange(r)
          else
            OptionPriceChange(
              optionId: r.optionId,
              sellingPrice:
                  _restore.contains(r.optionId) ? null : _parsed(r.optionId),
            ),
      ],
    );
    if (!mounted) {
      return;
    }
    res.fold(
      // Surface the backend 400 text (not this listing's option, no margin preset …).
      (failure) => setState(() {
        _error = failureText(failure, '판매가 저장에 실패했습니다.');
        _isSaving = false;
      }),
      (saved) {
        // Failed rows are identified by option name only → map back to ids.
        final failedIds = _rows
            .where((r) => saved.failed.any((f) => f.optionName == r.optionName))
            .map((r) => r.optionId)
            .toSet();
        setState(() {
          _applyOptions(saved.listing.options, failedIds);
          _saveResult = saved;
          _isSaving = false;
        });
        // The matrix refreshes in every case.
        _result = true;
        if (saved.failed.isEmpty && saved.skipped.isEmpty) {
          _close();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final saveResult = _saveResult;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _close();
        }
      },
      child: ScaffoldWithNavBar(
        title: '채널별 판매가',
        navBarIndex: 2,
        onBackPressed: _close,
        body: AppPageBody(
          children: [
            Text(
              widget.args.channelLabel,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            if (_error.isNotEmpty) ...[
              AppErrorBox(message: _error),
              const SizedBox(height: 16),
            ],
            if (saveResult != null) ...[
              if (saveResult.pushed > 0) ...[
                _Banner(
                  text: '마켓에 ${saveResult.pushed}건 반영했습니다.',
                  background: AppColors.successSurface,
                  foreground: AppColors.successForeground,
                ),
                const SizedBox(height: 4),
              ],
              if (saveResult.skipped.isNotEmpty) ...[
                _Banner(
                  text: '아직 마켓에 없는 옵션은 저장만 했습니다: '
                      '${saveResult.skipped.join(', ')}. [마켓에 올리기] 시 '
                      '이 가격으로 올라갑니다.',
                  background: scheme.surfaceContainerLow,
                  foreground: scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
              ],
              for (final f in saveResult.failed) ...[
                _Banner(
                  text: '마켓 반영 실패(저장되지 않음): ${f.optionName} — ${f.message}',
                  background: scheme.errorContainer,
                  foreground: scheme.error,
                ),
                const SizedBox(height: 4),
              ],
              const SizedBox(height: 12),
            ],
            if (_isLoading)
              const SizedBox(
                height: 128,
                child: Center(child: AppBusyLabel('불러오는 중...', size: 24)),
              )
            else if (_rows.isEmpty)
              const AppEmpty('이 채널에서 판매 중인 옵션이 없습니다.')
            else ...[
              Text(
                '입력한 가격은 이 채널에만 적용됩니다. 자동계산가로 되돌리려면 [기본값으로 변경]을 '
                '누르세요.',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              for (final r in _rows) ...[
                if (_isEsmRow(r)) _esmRow(context, r) else _row(context, r),
                const SizedBox(height: 8),
              ],
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : _close,
                  child: const Text('취소'),
                ),
                if (_rows.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isLoading ||
                            _isSaving ||
                            _invalid ||
                            _dirty.isEmpty
                        ? null
                        : _handleSave,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: _isSaving
                        ? const AppBusyLabel('저장 중...')
                        : const Text('저장'),
                  ),
                ],
              ],
            ),
            if (_isSaving) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '마켓에 반영하는 중이라 몇 초 걸릴 수 있습니다.',
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

  // FEATURE_2610_26 / D53 ②: 「G마켓」 and 「옥션」, each field with its own
  // [기본값으로 변경].
  Widget _esmRow(BuildContext context, ListingOptionSummary r) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.optionName, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          _siteField(
            context,
            label: 'G마켓',
            manual: r.priceSource == GeneratedSourceCode.manualOverride,
            restoring: _restore.contains(r.optionId),
            value: _raw(r.optionId),
            controller: _controllerFor(r.optionId),
            onChanged: (next) =>
                setState(() => _draft = {..._draft, r.optionId: next}),
            onRestore: () => _toggleRestore(r.optionId),
            marginPreview: MarginPreviewText(
              listingId: widget.args.listingId,
              optionId: r.optionId,
              auction: false,
              price: !_restore.contains(r.optionId) && _validRow(r.optionId)
                  ? _parsed(r.optionId)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          _siteField(
            context,
            label: '옥션',
            manual: r.auctionPriceSource == GeneratedSourceCode.manualOverride,
            restoring: _restoreAuction.contains(r.optionId),
            value: _rawAuction(r.optionId),
            controller: _auctionControllerFor(r.optionId),
            onChanged: (next) => setState(
                () => _draftAuction = {..._draftAuction, r.optionId: next}),
            onRestore: () => _toggleRestoreAuction(r.optionId),
            marginPreview: MarginPreviewText(
              listingId: widget.args.listingId,
              optionId: r.optionId,
              auction: true,
              price: !_restoreAuction.contains(r.optionId) &&
                      _validAuction(r.optionId)
                  ? _parsedAuction(r.optionId)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _siteField(
    BuildContext context, {
    required String label,
    required bool manual,
    required bool restoring,
    required String value,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required VoidCallback onRestore,
    required Widget marginPreview,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final empty = !restoring && value.trim() == '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                  if (manual)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warningSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '수동',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.warningForeground,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 112,
              child: TextField(
                controller: controller,
                enabled: !restoring && !_isSaving,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '원',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(alignment: Alignment.centerRight, child: marginPreview),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: _isSaving ? null : onRestore,
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              foregroundColor: restoring ? AppColors.infoForeground : null,
              backgroundColor: restoring ? AppColors.infoSurface : null,
            ),
            child: const Text('기본값으로 변경'),
          ),
        ),
        if (restoring) ...[
          const SizedBox(height: 4),
          Text(
            '저장하면 자동계산가로 돌아갑니다',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
        if (empty) ...[
          const SizedBox(height: 4),
          Text(
            '값을 입력하거나 [기본값으로 변경]을 누르세요',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, ListingOptionSummary r) {
    final scheme = Theme.of(context).colorScheme;
    final willRestore = _restore.contains(r.optionId);
    final empty = !willRestore && _raw(r.optionId).trim() == '';
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
            children: [
              Expanded(
                child: Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(r.optionName, style: const TextStyle(fontSize: 14)),
                    if (r.priceSource == GeneratedSourceCode.manualOverride)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warningSurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '수동',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.warningForeground,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 112,
                child: TextField(
                  controller: _controllerFor(r.optionId),
                  enabled: !willRestore && !_isSaving,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  onChanged: (next) => setState(
                    () => _draft = {..._draft, r.optionId: next},
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '원',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: MarginPreviewText(
              listingId: widget.args.listingId,
              optionId: r.optionId,
              auction: false,
              price: !willRestore && _validRow(r.optionId)
                  ? _parsed(r.optionId)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => _toggleRestore(r.optionId),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                foregroundColor: willRestore ? AppColors.infoForeground : null,
                backgroundColor: willRestore ? AppColors.infoSurface : null,
              ),
              child: const Text('기본값으로 변경'),
            ),
          ),
          if (willRestore) ...[
            const SizedBox(height: 4),
            Text(
              '저장하면 자동계산가로 돌아갑니다',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
          if (empty) ...[
            const SizedBox(height: 4),
            Text(
              '값을 입력하거나 [기본값으로 변경]을 누르세요',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
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
