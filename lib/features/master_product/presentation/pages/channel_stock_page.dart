import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_tool_args.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

/// Per-channel (cell) option stock page (102/103) — FEATURE_2609_80 / 08.
///
/// **File**: lib/features/master_product/presentation/pages/channel_stock_page.dart
/// **Web original**: `master-products/[id]/components/ChannelStockModal.tsx` @09208a0
///
/// The master option stock is the default; this page lowers it for **this
/// channel only**.
/// - Blank = inherit (master value), `0` = sold out — two different values.
/// - The cap (`maxStock`) is the backend SSOT — never recomputed here.
/// - Save = one bulk PUT with the changed rows only. No change = close without
///   a request (the backend rejects an empty array with 400).
/// - Inactive options are hidden.
///
/// Result: `true` once something was saved (`null` = closed without saving).
/// ⚠️ A registered cell (`needsResync`) stays open with a notice after saving.
class ChannelStockPage extends StatefulWidget {
  final ChannelOptionsArgs args;

  const ChannelStockPage({required this.args, super.key});

  @override
  State<ChannelStockPage> createState() => _ChannelStockPageState();
}

class _ChannelStockPageState extends State<ChannelStockPage> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();
  // One controller per option id (R2).
  final Map<int, TextEditingController> _controllers = {};

  List<ListingOptionSummary> _rows = [];
  // Per-row input buffer. '' = inherit (sent as null).
  Map<int, String> _draft = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String _error = '';
  String _notice = '';
  bool? _result;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant ChannelStockPage oldWidget) {
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
    super.dispose();
  }

  TextEditingController _controllerFor(int optionId) =>
      _controllers.putIfAbsent(optionId, TextEditingController.new);

  // Hide inactive options and reseed the input buffer from the server values.
  // ⚠️ `0` (sold out) must stay `0`, never collapse into ''.
  void _applyOptions(List<ListingOptionSummary> options) {
    final visible = options.where((o) => o.active).toList();
    _rows = visible;
    _draft = {
      for (final o in visible) o.optionId: o.stockQuantity?.toString() ?? '',
    };
    for (final o in visible) {
      _controllerFor(o.optionId).text = _draft[o.optionId]!;
    }
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
        (_) => _error = '옵션 재고를 불러오지 못했습니다.',
        (listing) => _applyOptions(listing.options),
      );
      _isLoading = false;
    });
  }

  void _close() => context.pop(_result);

  String _valueOf(int optionId) => _draft[optionId] ?? '';

  int? _numberOf(int optionId) => int.tryParse(_valueOf(optionId));

  // ⚠️ '' (inherit) and 0 (sold out) are compared as different values.
  bool _isDirty(ListingOptionSummary r) {
    final value = _valueOf(r.optionId);
    if (value == '') {
      return r.stockQuantity != null;
    }
    return _numberOf(r.optionId) != r.stockQuantity;
  }

  bool _isOver(ListingOptionSummary r) {
    final value = _valueOf(r.optionId);
    return value != '' && (_numberOf(r.optionId) ?? 0) > r.maxStock;
  }

  List<ListingOptionSummary> get _dirty => _rows.where(_isDirty).toList();

  bool get _invalid => _rows.any(_isOver);

  Future<void> _handleSave() async {
    final dirty = _dirty;
    if (dirty.isEmpty) {
      _close();
      return;
    }
    setState(() {
      _isSaving = true;
      _error = '';
    });
    final res = await _useCase.setOptionStocks(
      widget.args.listingId,
      [
        for (final r in dirty)
          OptionStockChange(
            optionId: r.optionId,
            stockQuantity:
                _valueOf(r.optionId) == '' ? null : _numberOf(r.optionId),
          ),
      ],
    );
    if (!mounted) {
      return;
    }
    res.fold(
      // Surface the backend 400 text (over the cap, not in this listing …).
      (failure) => setState(() {
        _error = failureText(failure, '재고 저장에 실패했습니다.');
        _isSaving = false;
      }),
      (listing) {
        _result = true;
        // A registered cell is not pushed to the market by a stock change —
        // no auto push, only a notice.
        if (listing.needsResync == true) {
          setState(() {
            _notice = '등록된 셀입니다 — 마켓 반영은 [수정 요청]이 필요합니다.';
            _applyOptions(listing.options);
            _isSaving = false;
          });
          return;
        }
        _close();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _close();
        }
      },
      child: ScaffoldWithNavBar(
        title: '채널별 재고 설정',
        navBarIndex: 2,
        onBackPressed: _close,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            kBottomNavigationBarHeight + 24,
          ),
          children: [
            Text(
              widget.args.channelLabel,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            if (_error.isNotEmpty) ...[
              _Banner(
                text: _error,
                background: scheme.errorContainer,
                foreground: scheme.error,
              ),
              const SizedBox(height: 16),
            ],
            if (_notice.isNotEmpty) ...[
              _Banner(
                text: _notice,
                background: AppColors.warningSurface,
                foreground: AppColors.warningForeground,
              ),
              const SizedBox(height: 16),
            ],
            if (_isLoading)
              const SizedBox(
                height: 128,
                child: Center(child: _BusyLabel('불러오는 중...', size: 24)),
              )
            else if (_rows.isEmpty)
              Text(
                '이 채널에 재고를 설정할 활성 옵션이 없습니다.',
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
              )
            else ...[
              Text(
                '비우면 마스터 재고를 그대로 사용하고, 0은 품절입니다. 마스터 재고보다 크게 설정할 수 '
                '없습니다.',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              for (final r in _rows) ...[
                _row(context, r),
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
                  child:
                      _isSaving ? const _BusyLabel('저장 중...') : const Text('저장'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, ListingOptionSummary r) {
    final scheme = Theme.of(context).colorScheme;
    final value = _valueOf(r.optionId);
    final over = _isOver(r);
    Widget? badge;
    if (value == '') {
      badge = const _Chip(
        text: '마스터 재고 기본값 사용중',
        background: AppColors.infoSurface,
        foreground: AppColors.infoForeground,
      );
    } else if (_numberOf(r.optionId) == 0) {
      badge = _Chip(
        text: '품절',
        background: scheme.errorContainer,
        foreground: scheme.error,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                child: Text(r.optionName, style: const TextStyle(fontSize: 14)),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                badge,
              ],
              const SizedBox(width: 8),
              SizedBox(
                width: 96,
                child: TextField(
                  controller: _controllerFor(r.optionId),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    isDense: true,
                    hintText: '마스터 ${r.maxStock}',
                  ),
                  onChanged: (next) => setState(
                    () => _draft = {..._draft, r.optionId: next},
                  ),
                ),
              ),
            ],
          ),
          if (over) ...[
            const SizedBox(height: 4),
            Text(
              '마스터 재고(${r.maxStock})보다 클 수 없습니다',
              style: TextStyle(fontSize: 11, color: scheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small colored chip (web `rounded px-1.5 py-0.5 text-[11px]`).
class _Chip extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Chip({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: foreground,
          ),
        ),
      );
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

/// Spinner + label (web `<Spinner label=… />`).
class _BusyLabel extends StatelessWidget {
  final String label;
  final double size;

  const _BusyLabel(this.label, {this.size = 16});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      );
}
