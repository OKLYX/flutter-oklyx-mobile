import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
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
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/core/utils/platform_display.dart';

/// 11st channel default shipping settings — the 11st branch of `Routes.masterShippingConfig`
/// (FEATURE_2610_13 / D84). Port of web `sellers/list/components/ElevenstShippingConfigModal.tsx`.
///
/// **File**: lib/features/master_product/presentation/pages/elevenst_shipping_config_page.dart
///
/// Loads the stored settings and the 11st address lists (1014 · 1015) in parallel; a failed list read degrades to
/// an empty list and never blocks saving. Saving replaces the whole map.
/// ⚠️ The router opens this page instead of `MasterShippingConfigPage` when the account is an 11st account.
class ElevenstShippingConfigPage extends StatefulWidget {
  final ShippingConfigArgs args;

  const ElevenstShippingConfigPage({required this.args, super.key});

  @override
  State<ElevenstShippingConfigPage> createState() =>
      _ElevenstShippingConfigPageState();
}

class _ElevenstShippingConfigPageState
    extends State<ElevenstShippingConfigPage> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  Map<String, String> _form = {};
  List<OutboundPlace> _outbound = [];
  List<ReturnCenter> _returns = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final accountId = widget.args.account.id;
    final configFuture = _useCase.getElevenstShippingConfig(accountId);
    final outboundFuture = _useCase.listOutboundPlaces(accountId);
    final returnFuture = _useCase.listReturnCenters(accountId);
    final config =
        (await configFuture).fold((_) => <String, String>{}, (c) => c);
    final outboundList =
        (await outboundFuture).fold((_) => <OutboundPlace>[], (l) => l);
    final returnList =
        (await returnFuture).fold((_) => <ReturnCenter>[], (l) => l);
    if (!mounted) {
      return;
    }
    setState(() {
      _form = config;
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
    final res = await _useCase.upsertElevenstShippingConfig(
      widget.args.account.id,
      cleanElevenstMap(_form),
    );
    if (!mounted) {
      return;
    }
    final failed = res.fold<int?>(
      (failure) {
        setState(() {
          _error = failureText(failure, '배송설정 저장에 실패했습니다.');
          _isSaving = false;
        });
        return null;
      },
      (count) {
        _isSaving = false;
        return count;
      },
    );
    if (failed != null) {
      await _closeAfterRecalcNotice('배송 설정 저장', failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alias = widget.args.account.accountAlias;
    final label =
        alias == null || alias.isEmpty ? platformName('ELEVENST') : alias;
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
            ? const Center(child: AppBusyLabel('불러오는 중...', size: 24))
            : AppPageBody(
                children: [
                  if (_error.isNotEmpty) ...[
                    AppErrorBox(message: _error),
                    const SizedBox(height: 20),
                  ],
                  ElevenstShippingFields(
                    level: ShippingOverrideLevel.account,
                    value: _form,
                    onChanged: (next) => setState(() => _form = next),
                    outbound: _outbound,
                    returns: _returns,
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
