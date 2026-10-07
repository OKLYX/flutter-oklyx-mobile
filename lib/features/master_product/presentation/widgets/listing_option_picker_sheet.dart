import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/listing_detail_panel.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/info_bubble_icon.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';

/// Why the listing cannot go to Coupang yet (77). [쿠팡에 올리기] and this
/// sheet share the text.
const String kShippingBlockedReason =
    '배송 설정 미완료 — 마스터/채널/계정 중 한 곳에서 배송 설정 필요';

const String kUploadSuccessMessage =
    '쿠팡에 올렸습니다. 승인 결과는 ⋯ 메뉴의 [승인 새로고침]으로 확인하세요.';

/// Opens the "options to upload" sheet — **the same sheet before and after
/// the first upload** (FEATURE_2609_77, UX D43 · D57) — FEATURE_2609_80 / 08.
///
/// **File**: lib/features/master_product/presentation/widgets/listing_option_picker_sheet.dart
/// **Web original**: `master-products/[id]/components/ListingOptionPickerDialog.tsx` @09208a0
///
/// - [mode] `'upload'`: pick options, check prices, [올리기] → (active options
///   saved when changed) → Coupang register. 🔴 This sheet IS the confirmation
///   for the market push (D29) — nothing is sent before [올리기].
/// - [mode] `'select'`: [저장] → saves active options only (no Coupang call).
/// - Upload mode only: a 노출상품명 field prefilled with [displayName] and its
///   own [저장] — the same save as the listing detail panel
///   (`updateDisplayName`, blank cannot be saved). It is separate from
///   [올리기]; on success [onDisplayNameSaved] runs (the caller reloads, like
///   the panel's `onSaved`).
///
/// Returns `true` on success (web `onDone` — the caller reloads), `false` on
/// cancel / dismiss (web `onClose`).
///
/// **Usage**:
/// ```dart
/// if (await showListingOptionPickerSheet(context,
///     mode: 'upload', listingId: id, channelLabel: label,
///     displayName: cell.name, onDisplayNameSaved: onReload)) {
///   onReload();
/// }
/// ```
///
/// ⚠️ Options on the market (`onMarket && active`) cannot be switched off.
/// ⚠️ At least one option must be picked (the backend also answers 400).
/// ❌ Prices are not edited here — [⋯ > 가격 설정] does that.
/// ❌ Do not chain the name save into [올리기] — they are separate actions.
Future<bool> showListingOptionPickerSheet(
  BuildContext context, {
  required String mode,
  required int listingId,
  required String channelLabel,
  String displayName = '',
  VoidCallback? onDisplayNameSaved,
}) async {
  final result = await showAppSheet<bool>(
    context,
    builder: (_) => _ListingOptionPickerSheet(
      mode: mode,
      listingId: listingId,
      channelLabel: channelLabel,
      displayName: displayName,
      onDisplayNameSaved: onDisplayNameSaved,
    ),
  );
  return result ?? false;
}

class _ListingOptionPickerSheet extends StatefulWidget {
  final String mode;
  final int listingId;
  final String channelLabel;

  /// Current display name (upload mode prefill).
  final String displayName;

  /// Runs after the display name is saved (upload mode).
  final VoidCallback? onDisplayNameSaved;

  const _ListingOptionPickerSheet({
    required this.mode,
    required this.listingId,
    required this.channelLabel,
    required this.displayName,
    required this.onDisplayNameSaved,
  });

  @override
  State<_ListingOptionPickerSheet> createState() =>
      _ListingOptionPickerSheetState();
}

class _ListingOptionPickerSheetState extends State<_ListingOptionPickerSheet> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  GeneratedProduct? _gen;
  String _loadError = '';
  Set<int> _selected = {};
  bool _busy = false;

  // Display name (upload mode)
  final TextEditingController _nameController = TextEditingController();
  bool _savingName = false;

  bool get _isUpload => widget.mode == 'upload';

  String get _trimmedName => _nameController.text.trim();

  List<OptionPrice> get _prices => _gen?.optionPrices ?? const [];

  List<int> get _currentActive => _prices
      .where((p) => p.active != false)
      .map((p) => p.optionId)
      .toList();

  bool get _changed {
    final current = _currentActive;
    return _selected.length != current.length ||
        current.any((id) => !_selected.contains(id));
  }

  bool get _shippingBlocked => _isUpload && _gen?.shippingReady == false;

  bool get _hasLocked =>
      _prices.any((p) => p.onMarket == true && p.active != false);

  bool get _canConfirm =>
      _gen != null &&
      !_busy &&
      !_savingName &&
      _selected.isNotEmpty &&
      !_shippingBlocked;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.displayName;
    unawaited(_load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Same save as the listing detail panel's display name (blank is not saved).
  Future<void> _saveName() async {
    if (_trimmedName.isEmpty) {
      return;
    }
    setState(() => _savingName = true);
    final res =
        await _useCase.updateDisplayName(widget.listingId, _trimmedName);
    if (!mounted) {
      return;
    }
    setState(() => _savingName = false);
    res.fold(
      (_) => showErrorToast(context, '노출상품명 저장에 실패했습니다.'),
      (_) {
        showSuccessToast(context, '노출상품명을 저장했습니다.');
        widget.onDisplayNameSaved?.call();
      },
    );
  }

  Future<void> _load() async {
    final res = await _useCase.getGenerated(widget.listingId);
    if (!mounted) {
      return;
    }
    setState(() {
      res.fold(
        (failure) => _loadError = failureText(failure, '옵션을 불러오지 못했습니다.'),
        (gen) {
          _gen = gen;
          _selected = gen.optionPrices
              .where((p) => p.active != false)
              .map((p) => p.optionId)
              .toSet();
        },
      );
    });
  }

  void _toggle(int optionId) => setState(() {
        final next = {..._selected};
        if (!next.remove(optionId)) {
          next.add(optionId);
        }
        _selected = next;
      });

  Future<void> _handleConfirm() async {
    if (!_canConfirm) {
      return;
    }
    if (!_isUpload && !_changed) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _busy = true);
    var needsResync = false;
    if (_changed) {
      final res =
          await _useCase.setActiveOptions(widget.listingId, _selected.toList());
      if (!mounted) {
        return;
      }
      final failure = res.fold((f) => f, (listing) {
        needsResync = listing.needsResync == true;
        return null;
      });
      if (failure != null) {
        _fail(failure);
        return;
      }
    }
    if (_isUpload) {
      final res = await _useCase.registerListing(widget.listingId);
      if (!mounted) {
        return;
      }
      final failure = res.fold((f) => f, (_) => null);
      if (failure != null) {
        _fail(failure);
        return;
      }
      showSuccessToast(context, kUploadSuccessMessage);
    } else {
      showSuccessToast(
        context,
        needsResync
            ? '올릴 옵션을 저장했습니다. 쿠팡에 반영하려면 [수정 요청]을 누르세요.'
            : '올릴 옵션을 저장했습니다.',
      );
    }
    Navigator.of(context).pop(true);
  }

  // Failure keeps the sheet open with an error toast on top of it.
  void _fail(Failure failure) {
    setState(() => _busy = false);
    showErrorToast(
      context,
      failureText(
        failure,
        _isUpload ? '쿠팡에 올리지 못했습니다.' : '올릴 옵션을 저장하지 못했습니다.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title =
        '${_isUpload ? '쿠팡에 올리기' : '올릴 옵션 고르기'} — ${widget.channelLabel}';
    return PopScope(
      canPop: !_busy && !_savingName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  _isUpload
                      ? '고른 옵션으로 쿠팡에 상품을 올립니다. 올린 뒤 승인 결과는 ⋯ 메뉴의 [승인 새로고침]으로 확인합니다.'
                      : '쿠팡에 올릴 옵션을 고릅니다. 이미 쿠팡에 올린 판매상품은 저장한 뒤 [수정 요청]을 눌러야 쿠팡에 반영됩니다.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                if (_isUpload) ...[
                  _nameRow(context),
                  const SizedBox(height: 12),
                ],
                ..._body(context),
                if (_hasLocked) ...[
                  const SizedBox(height: 12),
                  const Text(
                    kMarketOptionLockReason,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warningForeground,
                    ),
                  ),
                ],
                if (_gen != null && _selected.isEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '옵션을 1개 이상 고르세요.',
                    style: TextStyle(fontSize: 12, color: scheme.error),
                  ),
                ],
                if (_shippingBlocked) ...[
                  const SizedBox(height: 12),
                  Text(
                    kShippingBlockedReason,
                    style: TextStyle(fontSize: 12, color: scheme.error),
                  ),
                ],
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
                  onPressed: _busy || _savingName
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _canConfirm ? _handleConfirm : null,
                  child: _busy
                      ? AppBusyLabel(_isUpload ? '올리는 중...' : '저장 중...')
                      : Text(_isUpload ? '올리기' : '저장'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Display name + its own [저장] (upload mode). Separate from [올리기].
  Widget _nameRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '노출상품명',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                enabled: !_savingName && !_busy,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _savingName || _busy || _trimmedName.isEmpty
                  ? null
                  : _saveName,
              child: _savingName
                  ? const AppBusyLabel('저장 중')
                  : const Text('저장'),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _body(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_gen == null) {
      if (_loadError.isNotEmpty) {
        return [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _loadError,
              style: TextStyle(fontSize: 14, color: scheme.error),
            ),
          ),
        ];
      }
      return const [AppBusyLabel('옵션 불러오는 중', size: 14)];
    }
    if (_prices.isEmpty) {
      return [
        Text('옵션 없음', style: TextStyle(color: scheme.onSurfaceVariant)),
      ];
    }
    return [
      for (final p in _prices) _optionTile(context, p),
    ];
  }

  Widget _optionTile(BuildContext context, OptionPrice p) {
    final scheme = Theme.of(context).colorScheme;
    final locked = p.onMarket == true && p.active != false;
    final checked = _selected.contains(p.optionId);
    final textColor = checked ? null : scheme.onSurfaceVariant;
    return Row(
      children: [
        Expanded(
          child: CheckboxListTile(
            value: checked,
            onChanged:
                _busy || locked ? null : (_) => _toggle(p.optionId),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              p.optionName ?? '옵션 #${p.optionId}',
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            subtitle: Text(
              formatWon(p.sellingPrice),
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ),
        ),
        if (locked) ...[
          Text(
            '🔒',
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
          ),
          const InfoBubbleIcon(message: kMarketOptionLockReason),
        ],
      ],
    );
  }
}
