import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

String _placeholderFor(String key) =>
    kBuiltinFieldKeys.contains(key) ? '등록상품값 사용' : '템플릿 기본값 사용';

/// Master template field values inline edit panel on the master detail
/// screen — FEATURE_2609_80 / 07.
///
/// **File**: lib/features/master_product/presentation/widgets/master_field_values_panel.dart
/// **Web original**: `master-products/[id]/components/MasterFieldValuesPanel.tsx` @09208a0
///
/// Field **list** = the default thumbnail template's `fields` (S13, loaded
/// once on mount); field **values** = the parent [master]'s `fieldValues`.
/// Blank values are omitted on save (built-in keys fall back to the listing
/// value, custom keys to the template default). Save PATCHes only
/// `{fieldValues}` and notifies [onSaved].
///
/// ⚠️ The backend replaces the whole non-null map — cleared fields are applied.
/// ❌ Draws no card shell or title — the detail page wraps it (09).
class MasterFieldValuesPanel extends StatefulWidget {
  final MasterProduct master;
  final ValueChanged<MasterProduct> onSaved;

  const MasterFieldValuesPanel({
    required this.master,
    required this.onSaved,
    super.key,
  });

  @override
  State<MasterFieldValuesPanel> createState() => _MasterFieldValuesPanelState();
}

class _MasterFieldValuesPanelState extends State<MasterFieldValuesPanel> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();
  // One controller per field key (R2) — created on first edit, kept
  // until dispose.
  final Map<String, TextEditingController> _controllers = {};

  List<TemplateField> _fields = [];
  Map<String, String> _values = {};
  bool _isLoading = true;
  String _loadError = '';
  bool _isEditing = false;
  bool _isSaving = false;
  String _error = '';
  bool _saved = false;
  Timer? _savedTimer;

  @override
  void initState() {
    super.initState();
    _values = Map.of(widget.master.fieldValues);
    unawaited(_loadFields());
  }

  @override
  void dispose() {
    _savedTimer?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFields() async {
    final result = await _useCase.listThumbnailTemplates();
    if (!mounted) {
      return;
    }
    setState(() {
      result.fold(
        (_) {
          _fields = [];
          _loadError = '템플릿 필드를 불러오지 못했습니다. 필드값을 편집할 수 없습니다.';
        },
        (templates) {
          final defaults = templates.where((t) => t.isDefault);
          _fields = defaults.isEmpty ? [] : defaults.first.fields;
        },
      );
      _isLoading = false;
    });
  }

  TextEditingController _controllerFor(String key) =>
      _controllers.putIfAbsent(key, TextEditingController.new);

  void _startEdit() {
    setState(() {
      _values = Map.of(widget.master.fieldValues);
      for (final f in _fields) {
        _controllerFor(f.key).text = _values[f.key] ?? '';
      }
      _error = '';
      _saved = false;
      _isEditing = true;
    });
  }

  Future<void> _handleSave() async {
    // Omit blank values so the backend falls back to product/template defaults.
    final cleaned = <String, String>{
      for (final e in _values.entries)
        if (e.value.trim().isNotEmpty) e.key: e.value,
    };
    setState(() {
      _isSaving = true;
      _error = '';
      _saved = false;
    });
    final result = await _useCase.updateMaster(
      widget.master.id,
      MasterProductUpdateRequest(fieldValues: cleaned),
    );
    if (!mounted) {
      return;
    }
    result.fold(
      (failure) => setState(() {
        _error = failureText(failure, '템플릿 필드값 저장에 실패했습니다.');
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error.isNotEmpty) ...[
            _Banner(
              text: _error,
              background: scheme.errorContainer,
              foreground: scheme.error,
            ),
            const SizedBox(height: 12),
          ],
          if (_loadError.isNotEmpty) ...[
            _Banner(
              text: _loadError,
              background: AppColors.warningSurface,
              foreground: AppColors.warningForeground,
            ),
            const SizedBox(height: 12),
          ],
          if (_isLoading)
            const SizedBox(
              height: 64,
              child: Center(child: _BusyLabel('불러오는 중...', size: 20)),
            )
          else if (_fields.isEmpty)
            Text(
              '기본 템플릿에 정의된 필드가 없습니다.',
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            )
          else
            _buildFields(context),
        ],
      ),
    );
  }

  Widget _buildFields(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: scheme.onSurfaceVariant,
    );
    final stored = widget.master.fieldValues;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final f in _fields) ...[
          Text(f.label, style: labelStyle),
          const SizedBox(height: 4),
          if (_isEditing)
            TextField(
              controller: _controllerFor(f.key),
              enabled: !_isSaving,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: _placeholderFor(f.key),
              ),
              onChanged: (next) => setState(() {
                _values = {..._values, f.key: next};
                _saved = false;
              }),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: (stored[f.key] ?? '').trim().isNotEmpty
                  ? Text(stored[f.key]!, style: const TextStyle(fontSize: 14))
                  : Text(
                      _placeholderFor(f.key),
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
            ),
          const SizedBox(height: 12),
        ],
        Text(
          '비우면 예약 필드는 등록상품 정보, 커스텀 필드는 템플릿 기본값으로 채워집니다. 채널마다 '
          '다르게 하려면 셀의 [필드값 편집]에서 조정하세요.',
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
        if (_saved && _error.isEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            '템플릿 필드값을 저장했습니다.',
            style: TextStyle(fontSize: 14, color: AppColors.successForeground),
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
                onPressed: _isSaving ? null : _handleSave,
                child:
                    _isSaving ? const _BusyLabel('저장 중...') : const Text('저장'),
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
            ],
          )
        else
          OutlinedButton(onPressed: _startEdit, child: const Text('수정')),
      ],
    );
  }
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
