import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/entities/carrier_rate.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/master_format.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';

// Web file-local `formatWon`.
String _formatWon(num? v) => v == null ? '—' : '${koNumber(v)}원';

/// Web `carrierLabel` — `CJ 기본 · 3,000원`.
String carrierLabel(CarrierRate r) =>
    '${r.carrier} ${r.type} · ${_formatWon(r.cost)}';

/// Web `packageLabel` — `소형 · 500원`.
String packageLabel(MasterBox p) => '${p.type} · ${_formatWon(p.cost)}';

/// Master default carrier rate / box inline edit panel on the master detail
/// screen — FEATURE_2609_80 / 07.
///
/// **File**: lib/features/master_product/presentation/widgets/master_default_cost_panel.dart
/// **Web original**: `master-products/[id]/components/MasterDefaultCostPanel.tsx` @09208a0
///
/// Used for every option's price unless the option overrides it. The
/// candidate lists ([carrierRates]/[packages]) are loaded once by the parent.
/// Save PATCHes only `{defaultDeliveryId, defaultPackageId}` then [onSaved].
///
/// ⚠️ Both dropdowns are required — no "none" item. The update request has no
///    way to clear these fields (null = keep), so save is blocked until both
///    are picked and the reason is shown inline.
/// ❌ Draws no card shell or title — the detail page wraps it (09).
class MasterDefaultCostPanel extends StatefulWidget {
  final MasterProduct master;
  final List<CarrierRate> carrierRates;
  final List<MasterBox> packages;
  final ValueChanged<MasterProduct> onSaved;

  const MasterDefaultCostPanel({
    required this.master,
    required this.carrierRates,
    required this.packages,
    required this.onSaved,
    super.key,
  });

  @override
  State<MasterDefaultCostPanel> createState() => _MasterDefaultCostPanelState();
}

class _MasterDefaultCostPanelState extends State<MasterDefaultCostPanel> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  bool _isEditing = false;
  int? _deliveryId;
  int? _packageId;
  bool _isSaving = false;
  String _error = '';
  bool _saved = false;
  Timer? _savedTimer;

  bool get _incomplete => _deliveryId == null || _packageId == null;

  @override
  void initState() {
    super.initState();
    _deliveryId = widget.master.defaultDeliveryId;
    _packageId = widget.master.defaultPackageId;
  }

  @override
  void dispose() {
    _savedTimer?.cancel();
    super.dispose();
  }

  void _startEdit() {
    setState(() {
      _deliveryId = widget.master.defaultDeliveryId;
      _packageId = widget.master.defaultPackageId;
      _error = '';
      _saved = false;
      _isEditing = true;
    });
  }

  Future<void> _handleSave() async {
    if (_incomplete) {
      return;
    }
    setState(() {
      _isSaving = true;
      _error = '';
      _saved = false;
    });
    final result = await _useCase.updateMaster(
      widget.master.id,
      MasterProductUpdateRequest(
        defaultDeliveryId: _deliveryId,
        defaultPackageId: _packageId,
      ),
    );
    if (!mounted) {
      return;
    }
    result.fold(
      (failure) => setState(() {
        _error = failureText(failure, '기본 택배/상자 저장에 실패했습니다.');
        _isSaving = false;
      }),
      (patched) {
        setState(() {
          _isEditing = false;
          _saved = true;
          _isSaving = false;
        });
        // Transient confirmation — auto-dismiss.
        _savedTimer?.cancel();
        _savedTimer = Timer(const Duration(milliseconds: 2500), () {
          if (mounted) {
            setState(() => _saved = false);
          }
        });
        widget.onSaved(patched);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final master = widget.master;
    final carriers = widget.carrierRates
        .where((r) => r.id == master.defaultDeliveryId)
        .toList();
    final boxes =
        widget.packages.where((p) => p.id == master.defaultPackageId).toList();
    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: scheme.onSurfaceVariant,
    );
    final carrierIds = widget.carrierRates.map((r) => r.id).toSet();
    final boxIds = widget.packages.map((p) => p.id).toSet();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _error,
                style: TextStyle(fontSize: 14, color: scheme.error),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text('기본 택배비 *', style: labelStyle),
          const SizedBox(height: 4),
          if (_isEditing)
            // No blank item on purpose — there is no "unset" path.
            DropdownButtonFormField<int>(
              initialValue:
                  carrierIds.contains(_deliveryId) ? _deliveryId : null,
              isExpanded: true,
              hint: const Text('택배를 선택하세요'),
              decoration: const InputDecoration(
              ),
              items: [
                for (final r in widget.carrierRates)
                  DropdownMenuItem<int>(
                    value: r.id,
                    child: Text(
                      carrierLabel(r),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _isSaving
                  ? null
                  : (v) => setState(() {
                        _deliveryId = v;
                        _saved = false;
                      }),
            )
          else
            _ReadOnlyBox(
              carriers.isEmpty ? '미지정' : carrierLabel(carriers.first),
            ),
          const SizedBox(height: 12),
          Text('기본 상자비 *', style: labelStyle),
          const SizedBox(height: 4),
          if (_isEditing)
            DropdownButtonFormField<int>(
              initialValue: boxIds.contains(_packageId) ? _packageId : null,
              isExpanded: true,
              hint: const Text('상자를 선택하세요'),
              decoration: const InputDecoration(
              ),
              items: [
                for (final p in widget.packages)
                  DropdownMenuItem<int>(
                    value: p.id,
                    child: Text(
                      packageLabel(p),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _isSaving
                  ? null
                  : (v) => setState(() {
                        _packageId = v;
                        _saved = false;
                      }),
            )
          else
            _ReadOnlyBox(boxes.isEmpty ? '미지정' : packageLabel(boxes.first)),
          const SizedBox(height: 12),
          Text(
            '옵션에서 개별 지정하지 않으면 이 값이 모든 옵션 판매가 계산에 쓰입니다.',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          if (_saved && _error.isEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              '기본 택배/상자를 저장했습니다.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.successForeground,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_isEditing)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton(
                  onPressed: _isSaving || _incomplete ? null : _handleSave,
                  child: _isSaving
                      ? const AppBusyLabel('저장 중...')
                      : const Text('저장'),
                ),
                OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => setState(() {
                            _isEditing = false;
                            _error = '';
                          }),
                  child: const Text('취소'),
                ),
                if (_incomplete)
                  Text(
                    '기본 택배비와 상자비를 모두 선택해야 저장할 수 있습니다(해제는 불가).',
                    style: TextStyle(fontSize: 12, color: scheme.error),
                  ),
              ],
            )
          else
            OutlinedButton(onPressed: _startEdit, child: const Text('수정')),
        ],
      ),
    );
  }
}

/// Gray read-only value box (web `rounded bg-gray-50 px-3 py-2 text-sm`).
class _ReadOnlyBox extends StatelessWidget {
  final String text;

  const _ReadOnlyBox(this.text);

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text, style: const TextStyle(fontSize: 14)),
      );
}
