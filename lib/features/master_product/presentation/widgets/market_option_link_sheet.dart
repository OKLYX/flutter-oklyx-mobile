import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/master_format.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';

String _formatWon(num v) => '${koNumber(v)}원';

/// Opens the Coupang option link sheet (2609_74/D13) — FEATURE_2609_80 / 08.
///
/// **File**: lib/features/master_product/presentation/widgets/market_option_link_sheet.dart
/// **Web original**: `master-products/[id]/components/MarketOptionLinkModal.tsx` @09208a0
///
/// Links a channel option that never received its option ID to one of the
/// options that really exist on Coupang — **picked by a person** (recovery
/// path when Coupang renamed the option).
/// - Reads Coupang's option list on open (one Coupang call), never cached.
/// - 🔴 Nothing is preselected — a similar-looking name must not silently
///   save a wrong link.
/// - Unpickable rows: no option ID yet (before approval) · already linked.
///
/// Returns `true` when linked (web `onLinked` — the caller reloads), `false`
/// when dismissed.
///
/// **Usage**:
/// ```dart
/// if (await showMarketOptionLinkSheet(context,
///     listingId: id, optionId: o.optionId, optionName: o.name)) {
///   onSaved();
/// }
/// ```
Future<bool> showMarketOptionLinkSheet(
  BuildContext context, {
  required int listingId,
  required int optionId,
  required String optionName,
}) async {
  final result = await showAppSheet<bool>(
    context,
    builder: (_) => _MarketOptionLinkSheet(
      listingId: listingId,
      optionId: optionId,
      optionName: optionName,
    ),
  );
  return result ?? false;
}

class _MarketOptionLinkSheet extends StatefulWidget {
  final int listingId;
  final int optionId;
  final String optionName;

  const _MarketOptionLinkSheet({
    required this.listingId,
    required this.optionId,
    required this.optionName,
  });

  @override
  State<_MarketOptionLinkSheet> createState() => _MarketOptionLinkSheetState();
}

class _MarketOptionLinkSheetState extends State<_MarketOptionLinkSheet> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  List<MarketOption> _marketOptions = [];
  bool _loading = true;
  String? _picked;
  bool _saving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final res = await _useCase.getMarketOptions(widget.listingId);
    if (!mounted) {
      return;
    }
    setState(() {
      res.fold(
        (failure) =>
            _error = failureText(failure, '쿠팡 옵션을 불러오지 못했습니다.'),
        (options) => _marketOptions = options,
      );
      _loading = false;
    });
  }

  Future<void> _handleLink() async {
    final picked = _picked;
    if (picked == null || _saving) {
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
    });
    final res = await _useCase.linkMarketOption(
      widget.listingId,
      widget.optionId,
      picked,
    );
    if (!mounted) {
      return;
    }
    res.fold(
      (failure) => setState(() {
        _error = failureText(failure, '쿠팡 옵션 연결에 실패했습니다.');
        _saving = false;
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  String? _blockedReason(MarketOption o) {
    if (o.vendorItemId == null) {
      return '승인 전 — 옵션 ID 가 없어 연결할 수 없습니다';
    }
    if (o.linkedOptionId != null) {
      return '이미 연결됨 — ${o.linkedOptionName ?? '다른 옵션'}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_saving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              '쿠팡 옵션 연결',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: widget.optionName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const TextSpan(text: ' 옵션과 이을 쿠팡 옵션을 고르세요.'),
                    ],
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                if (_loading)
                  const Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 4),
                      Text('쿠팡에서 불러오는 중'),
                    ],
                  )
                else if (_marketOptions.isEmpty)
                  if (_error.isEmpty)
                    Text(
                      '쿠팡에 옵션이 없습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  else
                    const SizedBox.shrink()
                else
                  RadioGroup<String>(
                    groupValue: _picked,
                    onChanged: (value) => setState(() => _picked = value),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: scheme.outlineVariant),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < _marketOptions.length; i++) ...[
                            if (i > 0)
                              Divider(height: 1, color: scheme.outlineVariant),
                            _optionTile(context, _marketOptions[i], i),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  '연결하면 이 옵션에 쿠팡 옵션 ID 가 저장됩니다. 쿠팡에는 아무것도 전송하지 않습니다.',
                  style:
                      TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _picked == null || _saving ? null : _handleLink,
                  child: _saving
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 4),
                            Text('연결 중…'),
                          ],
                        )
                      : const Text('연결'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionTile(BuildContext context, MarketOption o, int index) {
    final scheme = Theme.of(context).colorScheme;
    final reason = _blockedReason(o);
    final vendorItemId = o.vendorItemId;
    final salePrice = o.salePrice;
    return RadioListTile<String>(
      // Rows without an option ID cannot be picked (value never matches).
      value: vendorItemId ?? '__pending_$index',
      enabled: reason == null && !_saving,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      title: Text(
        o.itemName ?? '(이름 없음)',
        style: TextStyle(
          fontSize: 14,
          color: reason != null ? scheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                if (vendorItemId != null)
                  TextSpan(
                    text: vendorItemId,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                if (vendorItemId != null && salePrice != null)
                  const TextSpan(text: ' · '),
                if (salePrice != null) TextSpan(text: _formatWon(salePrice)),
              ],
            ),
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          if (reason != null)
            Text(
              reason,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
