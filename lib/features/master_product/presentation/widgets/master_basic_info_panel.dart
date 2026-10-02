import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';

/// Master basic info (name) inline edit + read-only component list on the
/// master detail screen — FEATURE_2609_80 / 07.
///
/// **File**: lib/features/master_product/presentation/widgets/master_basic_info_panel.dart
/// **Web original**: `master-products/[id]/components/MasterBasicInfoPanel.tsx` @09208a0
///
/// Initial values come from the parent [master] (no refetch here). Save
/// PATCHes only `{name}` — sending other fields would overwrite other
/// sections of the same screen. Success notifies [onSaved] only.
///
/// ⚠️ Components are read-only here; [구성상품 변경] opens the composition page.
/// ⚠️ The delete button lives in the detail header, not here — do not add one.
/// ❌ Draws no card shell or title — the detail page wraps it (09).
class MasterBasicInfoPanel extends StatefulWidget {
  final MasterProduct master;
  final ValueChanged<MasterProduct> onSaved;

  const MasterBasicInfoPanel({
    required this.master,
    required this.onSaved,
    super.key,
  });

  @override
  State<MasterBasicInfoPanel> createState() => _MasterBasicInfoPanelState();
}

class _MasterBasicInfoPanelState extends State<MasterBasicInfoPanel> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();
  final TextEditingController _nameController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  String _error = '';
  bool _saved = false;
  Timer? _savedTimer;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.master.name;
  }

  @override
  void dispose() {
    _savedTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() {
      _nameController.text = widget.master.name;
      _error = '';
      _saved = false;
      _isEditing = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _error = '';
    });
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _error = '';
      _saved = false;
    });
    final result = await _useCase.updateMaster(
      widget.master.id,
      MasterProductUpdateRequest(name: _nameController.text.trim()),
    );
    if (!mounted) {
      return;
    }
    result.fold(
      (failure) => setState(() {
        _error = failureText(failure, '기본 정보 저장에 실패했습니다.');
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
    final nameBlank = _nameController.text.trim().isEmpty;
    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: scheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error.isNotEmpty) ...[
            _ErrorBox(_error),
            const SizedBox(height: 12),
          ],
          Text('마스터 이름 *', style: labelStyle),
          const SizedBox(height: 4),
          if (_isEditing)
            TextField(
              controller: _nameController,
              enabled: !_isSaving,
              onChanged: (_) => setState(() => _saved = false),
            )
          else
            _ReadOnlyBox(master.name),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '구성상품 (${master.components.length}개)',
                  style: labelStyle,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => context.pushNamed(
                  Routes.masterProductComposition,
                  pathParameters: {'id': '${master.id}'},
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text('구성상품 변경'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 256),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(4),
            ),
            child: master.components.isEmpty
                ? Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      '구성상품이 없습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: master.components.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        master.components[i].productName,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            '구성상품을 바꾸려면 [구성상품 변경] 에서 옵션별 수량과 함께 저장하세요.',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          if (_saved && _error.isEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              '기본 정보를 저장했습니다.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.successForeground,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_isEditing)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton(
                  onPressed: _isSaving || nameBlank ? null : _handleSave,
                  child: _isSaving
                      ? const AppBusyLabel('저장 중...')
                      : const Text('저장'),
                ),
                OutlinedButton(
                  onPressed: _isSaving ? null : _cancelEdit,
                  child: const Text('취소'),
                ),
                if (nameBlank)
                  Text(
                    '마스터 이름을 입력하세요.',
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

/// Red error line (web `rounded bg-red-50 px-3 py-2 text-sm text-red-700`).
class _ErrorBox extends StatelessWidget {
  final String text;

  const _ErrorBox(this.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 14, color: scheme.error)),
    );
  }
}
