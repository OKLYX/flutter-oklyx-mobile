import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/listing_option_picker_sheet.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';

/// Opens the Coupang [수정 요청] compare sheet — FEATURE_2611_25 / 04.
///
/// **File**: lib/features/master_product/presentation/widgets/coupang_update_request_sheet.dart
/// **Web original**: `master-products/[id]/components/CoupangUpdateRequestModal.tsx`
///
/// Shows the items whose Coupang value differs from the oclyx value and lets
/// a person pick which ones to overwrite (D3 · D12).
/// - Reads Coupang on open (one call), never cached — every open starts from
///   the first picks again (D10).
/// - Unchecked items are sent with Coupang's current value.
/// - Rows oclyx cannot build (`selectable=false`) cannot be checked (D15).
/// - Option rows: new options without a Coupang pair (D24) · before approval
///   every option of the listing (D29). Mixed bundle = one option only (D30).
/// - Texts come from the server as-is (R4); labels match the web (R8 · R10).
///
/// Returns `true` when sent (the caller shows the banner and reloads),
/// `false` when dismissed.
///
/// **Usage**:
/// ```dart
/// if (await showCoupangUpdateRequestSheet(context, listingId: id)) {
///   onReload();
/// }
/// ```
///
/// ⚠️ Coupang only — other markets keep the confirm dialog (D12).
Future<bool> showCoupangUpdateRequestSheet(
  BuildContext context, {
  required int listingId,
}) async {
  final result = await showAppSheet<bool>(
    context,
    builder: (_) => _CoupangUpdateRequestSheet(listingId: listingId),
  );
  return result ?? false;
}

class _CoupangUpdateRequestSheet extends StatefulWidget {
  final int listingId;

  const _CoupangUpdateRequestSheet({required this.listingId});

  @override
  State<_CoupangUpdateRequestSheet> createState() =>
      _CoupangUpdateRequestSheetState();
}

class _CoupangUpdateRequestSheetState
    extends State<_CoupangUpdateRequestSheet> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  ListingUpdatePreview? _preview;
  bool _loading = true;
  bool _sending = false;
  String _error = '';
  final Set<String> _checkedKeys = {};
  final Set<int> _checkedOptions = {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final res = await _useCase.getUpdatePreview(widget.listingId);
    if (!mounted) {
      return;
    }
    setState(() {
      res.fold(
        (failure) => _error = failureText(failure, '쿠팡 상품을 읽지 못했습니다.'),
        (preview) {
          _preview = preview;
          _initPicks(preview);
        },
      );
      _loading = false;
    });
  }

  // D3 · D24 · D29 · R10: first picks.
  void _initPicks(ListingUpdatePreview preview) {
    _checkedKeys
      ..clear()
      ..addAll(preview.items.where((l) => l.selectable).map((l) => l.key));
    final checked = preview.optionLines
        .where((o) => o.checked)
        .map((o) => o.productListingOptionId)
        .toList();
    _checkedOptions
      ..clear()
      ..addAll(preview.mixedBundle && checked.length >= 2
          ? checked.take(1)
          : checked);
  }

  bool _nothingToPick(ListingUpdatePreview preview) =>
      !preview.items.any((l) => l.selectable) && preview.optionLines.isEmpty;

  bool _canSend() {
    final preview = _preview;
    if (preview == null || _loading || _sending) {
      return false;
    }
    if (preview.approvalPending && _checkedOptions.isEmpty) {
      return false;
    }
    return true;
  }

  void _toggleOption(ListingUpdatePreview preview, int id, bool on) {
    setState(() {
      if (!on) {
        _checkedOptions.remove(id);
        return;
      }
      // D30: a mixed bundle carries one option only.
      if (preview.mixedBundle) {
        _checkedOptions.clear();
      }
      _checkedOptions.add(id);
    });
  }

  Future<void> _handleSend() async {
    final preview = _preview;
    if (preview == null || !_canSend()) {
      return;
    }
    final selection = ListingUpdateSelection(
      overwrite: preview.items
          .where((l) => l.selectable && _checkedKeys.contains(l.key))
          .map((l) => l.key)
          .toList(),
      addOptions: preview.optionLines
          .map((o) => o.productListingOptionId)
          .where(_checkedOptions.contains)
          .toList(),
    );
    setState(() {
      _sending = true;
      _error = '';
    });
    final res = await _useCase.requestListingUpdate(
      widget.listingId,
      selection: selection,
    );
    if (!mounted) {
      return;
    }
    res.fold(
      (failure) => setState(() {
        _error = failureText(failure, '수정 요청에 실패했습니다.');
        _sending = false;
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = _preview;
    final nothing = preview != null && _nothingToPick(preview);
    return PopScope(
      canPop: !_sending,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              '수정 요청',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  '쿠팡 지금 값과 oclyx 값이 다른 항목입니다. 체크를 푼 항목은 쿠팡 값 그대로 보냅니다.',
                  style: TextStyle(fontSize: 14),
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
                      Text('쿠팡에서 읽는 중'),
                    ],
                  )
                else if (preview != null) ...[
                  if (nothing)
                    Text(
                      '쿠팡 값과 다른 항목이 없습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (preview.items.isNotEmpty)
                    _box(
                      context,
                      [
                        for (final line in preview.items)
                          _lineTile(context, line)
                      ],
                    ),
                  if (preview.optionLines.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    if (preview.mixedBundle)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          kCoupangOneOptionNotice,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (preview.approvalPending)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          '승인 전 상품입니다 — 보낼 옵션을 고르세요.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    _box(
                      context,
                      [
                        for (final o in preview.optionLines)
                          _optionLineTile(preview, o),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                Text(
                  '보내면 쿠팡 재심사가 시작됩니다.',
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
                      _sending ? null : () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _canSend() ? _handleSend : null,
                  child: _sending
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 4),
                            Text('보내는 중…'),
                          ],
                        )
                      : Text(nothing ? '그대로 다시 심사 요청' : '보내기'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(BuildContext context, List<Widget> tiles) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
            tiles[i],
          ],
        ],
      ),
    );
  }

  Widget _valueText(BuildContext context, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );

  Widget _lineTile(BuildContext context, ListingUpdatePreviewLine line) {
    if (!line.selectable) {
      // D15: oclyx has no value to send — Coupang's value stays.
      final reason = line.unavailableReason;
      return CheckboxListTile(
        value: false,
        onChanged: null,
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
        title: Text(
          '${line.label} · oclyx 값 없음 — 쿠팡 값 유지',
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: reason == null ? null : _valueText(context, reason),
      );
    }
    return CheckboxListTile(
      value: _checkedKeys.contains(line.key),
      onChanged: _sending
          ? null
          : (on) => setState(() {
                if (on == true) {
                  _checkedKeys.add(line.key);
                } else {
                  _checkedKeys.remove(line.key);
                }
              }),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      title: Text(line.label, style: const TextStyle(fontSize: 14)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: line.options.isEmpty
            ? [
                _valueText(context, '쿠팡 ${line.coupangValue ?? '(없음)'}'),
                _valueText(context, 'oclyx ${line.oclyxValue ?? '(없음)'}'),
              ]
            : [
                for (final o in line.options) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      o.optionName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  _valueText(context, '쿠팡 ${o.coupangValue}'),
                  _valueText(context, 'oclyx ${o.oclyxValue}'),
                ],
              ],
      ),
    );
  }

  Widget _optionLineTile(
    ListingUpdatePreview preview,
    ListingUpdateOptionLine o,
  ) {
    final id = o.productListingOptionId;
    return CheckboxListTile(
      value: _checkedOptions.contains(id),
      onChanged:
          _sending ? null : (on) => _toggleOption(preview, id, on == true),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      title: Text(
        preview.approvalPending ? o.optionName : '새 옵션 추가: ${o.optionName}',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
