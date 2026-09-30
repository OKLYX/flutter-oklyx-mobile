import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/shipping_override.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_tool_args.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/shipping_override_fields.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/info_bubble_icon.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

/// Per-channel (listing) shipping override page — FEATURE_2609_80 / 08.
///
/// **File**: lib/features/master_product/presentation/pages/channel_shipping_page.dart
/// **Web original**: `master-products/[id]/components/ChannelShippingOverrideModal.tsx` @09208a0
///
/// Loads outbound/return places of this channel's **account** plus the
/// inherited baseline (master ?? account) and pre-fills the form with it —
/// the channel's own override wins per field. Save = **only fields that differ
/// from the baseline** become this channel's override.
///
/// [처음 설정으로 초기화] = deletes this channel's override entirely (places
/// included) — the channel follows master ?? account again (confirmation, D32).
///
/// Result: the saved `GeneratedProduct` (`null` = closed without saving).
/// ⚠️ Each lookup failure degrades quietly (empty list / no baseline) — it
///    never blocks saving.
class ChannelShippingPage extends StatefulWidget {
  final ChannelShippingArgs args;

  const ChannelShippingPage({required this.args, super.key});

  @override
  State<ChannelShippingPage> createState() => _ChannelShippingPageState();
}

class _ChannelShippingPageState extends State<ChannelShippingPage> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  ShippingSettings _override = kEmptyShippingOverride;
  List<OutboundPlace> _outbound = [];
  List<ReturnCenter> _returns = [];
  ShippingSettings? _inherited;
  bool _placesLoading = true;
  bool _isSaving = false;
  bool _isResetting = false;
  String _error = '';
  GeneratedProduct? _result;

  bool get _busy => _isSaving || _isResetting;

  // Nothing stored for this channel → resetting would be a no-op call.
  bool get _hasOverride {
    final initial = widget.args.initialOverride;
    return initial != null && initial.isNotEmpty;
  }

  // Reset drops the place keys too — warn when the account has none.
  // _inherited == null (both lookups failed) → say nothing rather than guess.
  bool get _placesMissingAfterReset {
    final inherited = _inherited;
    return inherited != null &&
        (inherited.outboundShippingPlaceCode == null ||
            inherited.returnCenterCode == null);
  }

  @override
  void initState() {
    super.initState();
    _override = mapToOverride(widget.args.initialOverride);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant ChannelShippingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.args.listingId != widget.args.listingId ||
        oldWidget.args.accountId != widget.args.accountId ||
        oldWidget.args.initialOverride != widget.args.initialOverride) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    setState(() => _placesLoading = true);
    final accountId = widget.args.accountId;
    final outboundFuture = _useCase.listOutboundPlaces(accountId);
    final returnFuture = _useCase.listReturnCenters(accountId);
    final inheritedFuture = _useCase.getInheritedShipping(widget.args.listingId);
    final accountFuture = _useCase.getShippingConfig(accountId);
    final outboundList =
        (await outboundFuture).fold((_) => <OutboundPlace>[], (l) => l);
    final returnList =
        (await returnFuture).fold((_) => <ReturnCenter>[], (l) => l);
    final inheritedConfig =
        (await inheritedFuture).fold((_) => null, (c) => c);
    final accountConfig = (await accountFuture).fold((_) => null, (c) => c);
    if (!mounted) {
      return;
    }
    // master ?? account (resolved) if available, else the account preset.
    final baseline = inheritedConfig ?? accountConfig;
    setState(() {
      _outbound = outboundList;
      _returns = returnList;
      _inherited = baseline;
      // Pre-fill with the baseline; the channel's own override wins per field.
      _override = mergePreset(
        mapToOverride(widget.args.initialOverride),
        configToOverride(baseline),
      );
      _placesLoading = false;
    });
  }

  void _close() {
    if (_busy) {
      return;
    }
    context.pop(_result);
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _error = '';
    });
    // Only fields changed from the baseline are persisted as this channel's override.
    final res = await _useCase.updateListingShippingOverride(
      widget.args.listingId,
      diffOverride(_override, configToOverride(_inherited)),
    );
    if (!mounted) {
      return;
    }
    res.fold(
      (failure) => setState(() {
        _error = failureText(failure, '배송 설정 저장에 실패했습니다.');
        _isSaving = false;
      }),
      (updated) {
        _result = updated;
        _isSaving = false;
        _close();
      },
    );
  }

  Future<void> _openResetConfirm() async {
    final message = StringBuffer(
      '이 채널의 개별 배송 설정을 모두 지우고 처음 상태로 되돌립니다. 출고지·반품지 지정도 함께 '
      '지워지며, 되돌릴 수 없습니다.',
    );
    if (_placesMissingAfterReset) {
      message.write(
        '\n계정에 출고지/반품지가 지정돼 있지 않습니다. 초기화하면 이 채널의 출고지·반품지가 비어 '
        '배송 설정 미완료가 되고 [쿠팡에 올리기]가 비활성화됩니다.',
      );
    }
    final ok = await showMasterConfirmDialog(
      context,
      title: '채널 배송 설정 초기화',
      message: message.toString(),
      confirmText: '초기화',
      isDangerous: true,
    );
    if (!ok || !mounted) {
      return;
    }
    await _handleReset();
  }

  // Reset = delete this channel's override entirely (an empty map becomes null
  // on the backend) — back to the just-created state.
  Future<void> _handleReset() async {
    if (_isResetting) {
      return;
    }
    setState(() {
      _isResetting = true;
      _error = '';
    });
    final res = await _useCase.updateListingShippingOverride(
      widget.args.listingId,
      const <String, String>{},
    );
    if (!mounted) {
      return;
    }
    res.fold(
      (failure) => setState(() {
        _error = failureText(failure, '배송 설정 초기화에 실패했습니다.');
        _isResetting = false;
      }),
      (updated) {
        _result = updated;
        _isResetting = false;
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
        title: '배송 설정 — ${widget.args.channelLabel}',
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
              '판매자·마스터 배송 설정이 채워져 있습니다. 바꾼 값만 이 채널에 저장되고, 그대로 둔 값은 '
              '기본 설정을 그대로 따릅니다.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (_error.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 16, color: scheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error,
                        style: TextStyle(fontSize: 14, color: scheme.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            ShippingOverrideFields(
              value: _override,
              onChanged: (next) => setState(() => _override = next),
              level: ShippingOverrideLevel.listing,
              platform: widget.args.platform,
              outbound: _outbound,
              returns: _returns,
              inherited: _inherited,
              placesLoading: _placesLoading,
              disabled: _busy,
            ),
            // Destructive action on its own line as a text button — never a
            // peer of [저장].
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed:
                      _busy || !_hasOverride ? null : _openResetConfirm,
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.onSurfaceVariant,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  child: const Text('처음 설정으로 초기화'),
                ),
                if (!_hasOverride)
                  const InfoBubbleIcon(message: '이 채널에는 개별 배송 설정이 없습니다.'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _close,
                    child: const Text('닫기'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : _handleSave,
                    child: _isSaving
                        ? const _BusyLabel('저장 중...')
                        : const Text('저장'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      );
}
