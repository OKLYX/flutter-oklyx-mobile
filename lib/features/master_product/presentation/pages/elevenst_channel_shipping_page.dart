import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/elevenst_shipping.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_tool_args.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/elevenst_shipping_fields.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/shipping_override_fields.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/info_bubble_icon.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

/// 11st listing shipping override — the 11st branch of `Routes.masterChannelShipping` (FEATURE_2610_13 / D85 ·
/// D104). Port of web `master-products/[id]/components/ElevenstChannelShippingModal.tsx`.
///
/// **File**: lib/features/master_product/presentation/pages/elevenst_channel_shipping_page.dart
///
/// Same flow as `ChannelShippingPage`: the form opens pre-filled with the inherited baseline (master ?? 11st channel
/// default) and the listing's own values winning per key; saving stores only the keys changed from that baseline;
/// [처음 설정으로 초기화] saves an empty map.
/// Result: the saved `GeneratedProduct` (`null` = closed without saving).
/// ⚠️ The router opens this page instead of `ChannelShippingPage` when the listing is on 11st.
class ElevenstChannelShippingPage extends StatefulWidget {
  final ChannelShippingArgs args;

  const ElevenstChannelShippingPage({required this.args, super.key});

  @override
  State<ElevenstChannelShippingPage> createState() =>
      _ElevenstChannelShippingPageState();
}

class _ElevenstChannelShippingPageState
    extends State<ElevenstChannelShippingPage> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  Map<String, String> _form = {};
  Map<String, String> _inherited = {};
  List<OutboundPlace> _outbound = [];
  List<ReturnCenter> _returns = [];
  bool _placesLoading = true;
  bool _isSaving = false;
  bool _isResetting = false;
  String _error = '';
  GeneratedProduct? _result;

  bool get _busy => _isSaving || _isResetting;

  bool get _hasOverride {
    final initial = widget.args.initialOverride;
    return initial != null && initial.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _form = pickElevenst(widget.args.initialOverride);
    unawaited(_load());
  }

  Future<void> _load() async {
    final accountId = widget.args.accountId;
    final outboundFuture = _useCase.listOutboundPlaces(accountId);
    final returnFuture = _useCase.listReturnCenters(accountId);
    final inheritedFuture =
        _useCase.getInheritedElevenstShipping(widget.args.listingId);
    final outboundList =
        (await outboundFuture).fold((_) => <OutboundPlace>[], (l) => l);
    final returnList =
        (await returnFuture).fold((_) => <ReturnCenter>[], (l) => l);
    final baseline =
        (await inheritedFuture).fold((_) => <String, String>{}, (m) => m);
    if (!mounted) {
      return;
    }
    setState(() {
      _outbound = outboundList;
      _returns = returnList;
      _inherited = baseline;
      _form = mergeElevenstPreset(
          pickElevenst(widget.args.initialOverride), baseline);
      _placesLoading = false;
    });
  }

  void _close() {
    if (_busy) {
      return;
    }
    context.pop(_result);
  }

  // D124: when the server could not re-price some 11st listings, a one-button
  // notice comes first; the page closes after it, however it is dismissed.
  Future<void> _closeAfterRecalcNotice(String title, int failed) async {
    final note = recalcFailureNote(failed);
    if (note != null) {
      await showAppConfirmDialog(
        context,
        title: title,
        message: note,
        showCancel: false,
      );
      if (!mounted) {
        return;
      }
    }
    _close();
  }

  Future<void> _handleSave() async {
    final tierMessage = tierError(_form);
    if (tierMessage != null) {
      setState(() => _error = tierMessage);
      return;
    }
    setState(() {
      _isSaving = true;
      _error = '';
    });
    final res = await _useCase.updateListingShippingOverride(
      widget.args.listingId,
      diffElevenst(_form, _inherited),
    );
    if (!mounted) {
      return;
    }
    final failed = res.fold<int?>(
      (failure) {
        setState(() {
          _error = failureText(failure, '배송 설정 저장에 실패했습니다.');
          _isSaving = false;
        });
        return null;
      },
      (updated) {
        _result = updated;
        _isSaving = false;
        return updated.priceRecalcFailedCount;
      },
    );
    if (failed != null) {
      await _closeAfterRecalcNotice('배송 설정 저장', failed);
    }
  }

  Future<void> _openResetConfirm() async {
    final ok = await showAppConfirmDialog(
      context,
      title: '채널 배송 설정 초기화',
      message: '이 채널의 개별 배송 설정을 모두 지우고 처음 상태로 되돌립니다. 출고지·반품지 지정도 함께 '
          '지워지며, 되돌릴 수 없습니다.',
      confirmText: '초기화',
      isDangerous: true,
    );
    if (!ok || !mounted) {
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
    final failed = res.fold<int?>(
      (failure) {
        setState(() {
          _error = failureText(failure, '배송 설정 초기화에 실패했습니다.');
          _isResetting = false;
        });
        return null;
      },
      (updated) {
        _result = updated;
        _isResetting = false;
        return updated.priceRecalcFailedCount;
      },
    );
    if (failed != null) {
      await _closeAfterRecalcNotice('채널 배송 설정 초기화', failed);
    }
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
        body: AppPageBody(
          children: [
            Text(
              '판매자·마스터 배송 설정이 채워져 있습니다. 바꾼 값만 이 채널에 저장되고, 그대로 둔 값은 '
              '기본 설정을 그대로 따릅니다.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (_error.isNotEmpty) ...[
              AppErrorBox(message: _error),
              const SizedBox(height: 12),
            ],
            ElevenstShippingFields(
              level: ShippingOverrideLevel.listing,
              value: _form,
              onChanged: (next) => setState(() => _form = next),
              outbound: _outbound,
              returns: _returns,
              inherited: _inherited,
              placesLoading: _placesLoading,
              disabled: _busy,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: _busy || !_hasOverride ? null : _openResetConfirm,
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
                        ? const AppBusyLabel('저장 중...')
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
