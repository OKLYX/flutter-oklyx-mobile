import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/shipping_override.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_tool_args.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/shipping_override_fields.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';

/// Shipping management page for one sales channel (marketplace account) =
/// the account default — FEATURE_2609_80 / 08 (UX D83).
///
/// **File**: lib/features/master_product/presentation/pages/master_shipping_config_page.dart
/// **Web original**: `sellers/list/components/ShippingConfigModal.tsx` @09208a0
///
/// Field editing is delegated to `ShippingOverrideFields(level: account)` so
/// account / master / channel all render the same fields. Lookup first: the
/// outbound/return lists drive the pickers; a lookup failure never blocks
/// saving (each fetch degrades on its own).
///
/// No result — the caller re-reads when the page closes.
/// ⚠️ Opened **only from the master detail screen** (D83).
/// ❌ Do not add an entry to the mobile seller / marketplace account screens.
class MasterShippingConfigPage extends StatefulWidget {
  final ShippingConfigArgs args;

  const MasterShippingConfigPage({required this.args, super.key});

  @override
  State<MasterShippingConfigPage> createState() =>
      _MasterShippingConfigPageState();
}

class _MasterShippingConfigPageState extends State<MasterShippingConfigPage> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  ShippingSettings _form = kEmptyShippingOverride;
  List<OutboundPlace> _outbound = [];
  List<ReturnCenter> _returns = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant MasterShippingConfigPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.args.account.id != widget.args.account.id) {
      unawaited(_load());
    }
  }

  // Open-load: config + lookups in parallel, each caught independently.
  Future<void> _load() async {
    final accountId = widget.args.account.id;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final configFuture = _useCase.getShippingConfig(accountId);
    final outboundFuture = _useCase.listOutboundPlaces(accountId);
    final returnFuture = _useCase.listReturnCenters(accountId);
    final config = (await configFuture).fold((_) => null, (c) => c);
    final outboundList =
        (await outboundFuture).fold((_) => <OutboundPlace>[], (l) => l);
    final returnList =
        (await returnFuture).fold((_) => <ReturnCenter>[], (l) => l);
    if (!mounted) {
      return;
    }
    setState(() {
      _form = config == null ? kEmptyShippingOverride : configToOverride(config);
      _outbound = outboundList;
      _returns = returnList;
      _isLoading = false;
    });
  }

  void _close() {
    if (_isSaving) {
      return;
    }
    context.pop();
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _error = '';
    });
    final res = await _useCase.upsertShippingConfig(
      widget.args.account.id,
      _form,
    );
    if (!mounted) {
      return;
    }
    res.fold(
      (failure) => setState(() {
        _error = failureText(failure, '배송설정 저장에 실패했습니다.');
        _isSaving = false;
      }),
      (_) {
        _isSaving = false;
        _close();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.args.account;
    final alias = account.accountAlias;
    final label = alias == null || alias.isEmpty ? account.platform : alias;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _close();
        }
      },
      child: ScaffoldWithNavBar(
        title: '배송관리 — $label',
        navBarIndex: 2,
        onBackPressed: _close,
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(height: 8),
                    Text('불러오는 중...'),
                  ],
                ),
              )
            : AppPageBody(
                children: [
                  if (_error.isNotEmpty) ...[
                    AppErrorBox(message: _error),
                    const SizedBox(height: 20),
                  ],
                  ShippingOverrideFields(
                    value: _form,
                    onChanged: (next) => setState(() => _form = next),
                    level: ShippingOverrideLevel.account,
                    platform: account.platform,
                    outbound: _outbound,
                    returns: _returns,
                    placesLoading: _isLoading,
                    disabled: _isSaving,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _close,
                          child: const Text('닫기'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSaving ? null : _handleSave,
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
