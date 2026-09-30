import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/category_meta_validation.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/measure_attributes.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/notice_templates.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/option_meta_fields.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/category_meta_fields.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

// When every master-owned notice of the selected group is empty, fill them
// with "전체 상품 상세페이지 참조" (checked by default).
Map<String, String> _withNoticeRefDefault(
  List<CategoryNotice> notices,
  Map<String, String> values,
  String group,
) =>
    defaultNoticeRefAll(
      notices
          .where((n) => !isOptionNotice(n) && noticeGroupName(n) == group)
          .toList(),
      values,
    );

/// Category required attributes / product-info notice panel on the master
/// detail screen (container) — FEATURE_2609_80 / 07.
///
/// **File**: lib/features/master_product/presentation/widgets/category_meta_panel.dart
/// **Web original**: `master-products/[id]/components/CategoryMetaPanel.tsx` @09208a0
///
/// Owns the value state and passes it to [CategoryMetaFields] through
/// callbacks. The save gate is `computeMissingRequired`.
/// - COUPANG: loads schema + values (M17) → edit + save (M19).
/// - other platforms: schema only (M18) → read-only, save disabled.
///
/// ⚠️ Renders nothing while [categoryCode] is `null` (no fetch either).
/// ❌ Draws no card shell or title — the detail page wraps it (09).
class CategoryMetaPanel extends StatefulWidget {
  final int masterId;

  /// Assigned standard category id (`null` = unset); a change refetches.
  final String? categoryCode;

  /// Default 'COUPANG' (only registration mall for now).
  final String platform;

  /// Component kinds ≥ 2 — computed by the parent.
  final bool isBundle;
  final VoidCallback? onSaved;

  const CategoryMetaPanel({
    required this.masterId,
    required this.categoryCode,
    super.key,
    this.platform = 'COUPANG',
    this.isBundle = false,
    this.onSaved,
  });

  @override
  State<CategoryMetaPanel> createState() => _CategoryMetaPanelState();
}

class _CategoryMetaPanelState extends State<CategoryMetaPanel> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  List<CategoryAttribute> _attributes = [];
  List<CategoryNotice> _notices = [];
  Map<String, String> _attrValues = {};
  Map<String, String> _noticeValues = {};
  bool _isLoading = false;
  bool _isSaving = false;
  String _error = '';
  bool _saved = false;
  // Display filter, checked by default: 필수 항목만 보기.
  bool _onlyRequired = true;
  // Selected notice group; null = the effective group.
  String? _noticeGroup;

  // COUPANG owns the persisted per-master values; other platforms are
  // schema-only (read-only).
  bool get _readOnly => widget.platform != 'COUPANG';

  // Only COUPANG today, so the detail always has coupangSelected = true.
  bool get _hideCategoryAttrs => widget.isBundle;

  @override
  void initState() {
    super.initState();
    if (widget.categoryCode != null) {
      unawaited(_load());
    }
  }

  @override
  void didUpdateWidget(covariant CategoryMetaPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed = oldWidget.masterId != widget.masterId ||
        oldWidget.categoryCode != widget.categoryCode ||
        oldWidget.platform != widget.platform;
    if (changed && widget.categoryCode != null) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _saved = false;
    });
    const fallback = '카테고리 필수속성을 불러오지 못했습니다. 필요 시 카테고리/매핑을 설정하세요.';
    if (_readOnly) {
      // Non-COUPANG: schema only, no per-master values.
      final result = await _useCase.getCategorySchema(
        int.tryParse(widget.categoryCode ?? '') ?? 0,
        widget.platform,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        result.fold(
          (failure) {
            _attributes = [];
            _notices = [];
            _error = failureText(failure, fallback);
          },
          (schema) {
            _attributes = schema.attributes;
            _notices = schema.notices;
            _attrValues = {};
            _noticeValues = {};
            _noticeGroup = null;
          },
        );
        _isLoading = false;
      });
      return;
    }
    final result = await _useCase.getCategoryMeta(
      widget.masterId,
      widget.platform,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      result.fold(
        (failure) {
          // Lookup failed (e.g. mapping not set → 400): inline guidance.
          _attributes = [];
          _notices = [];
          _error = failureText(failure, fallback);
        },
        (meta) {
          _attributes = meta.attributes;
          _notices = meta.notices;
          _attrValues = Map.of(meta.values.attributes);
          // Restore the saved group; blank = unset → null (fallback decides).
          final savedGroup = (meta.values.noticeGroup ?? '').trim().isNotEmpty
              ? meta.values.noticeGroup
              : null;
          final values = meta.values.notices;
          final group = submitNoticeGroup(meta.notices, values, savedGroup);
          _noticeValues = _withNoticeRefDefault(meta.notices, values, group);
          _noticeGroup = savedGroup;
        },
      );
      _isLoading = false;
    });
  }

  // A picked unit clears the other side of the pair.
  void _handleMeasureUnit(MeasurePair p, String unit) {
    final clearName = unit == '중량'
        ? p.volume.name
        : unit == '용량'
            ? p.weight.name
            : '';
    if (clearName.isNotEmpty) {
      setState(() => _attrValues = {..._attrValues, clearName: ''});
    }
  }

  // Switching group starts it with "전체 상품 상세페이지 참조" when empty.
  void _handleNoticeGroupChange(String group) {
    setState(() {
      _noticeGroup = group;
      _noticeValues = _withNoticeRefDefault(_notices, _noticeValues, group);
    });
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _error = '';
      _saved = false;
    });
    // Compute the effective group once so the sent values and group agree.
    final group = submitNoticeGroup(_notices, _noticeValues, _noticeGroup);
    final result = await _useCase.setCategoryAttributes(
      widget.masterId,
      CategoryAttributesRequest(
        attributes: _attrValues,
        notices: noticesToSubmit(_notices, _noticeValues, group),
        noticeGroup: group,
      ),
    );
    if (!mounted) {
      return;
    }
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      setState(() {
        _error = failureText(failure, '저장에 실패했습니다.');
        _isSaving = false;
      });
      return;
    }
    setState(() {
      _noticeGroup = group;
      _saved = true;
      _isSaving = false;
    });
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categoryCode == null) {
      return const SizedBox.shrink();
    }
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          height: 64,
          child: Center(child: _BusyLabel('불러오는 중...', size: 20)),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final missingRequired = computeMissingRequired(
      _attributes,
      _attrValues,
      _notices,
      _noticeValues,
      _hideCategoryAttrs,
      _noticeGroup,
    );
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
          if (_saved) ...[
            const _Banner(
              text: '저장되었습니다.',
              background: AppColors.successSurface,
              foreground: AppColors.successForeground,
            ),
            const SizedBox(height: 12),
          ],
          CategoryMetaFields(
            attributes: _attributes,
            notices: _notices,
            attrValues: _attrValues,
            noticeValues: _noticeValues,
            onAttrChange: (name, value) =>
                setState(() => _attrValues = {..._attrValues, name: value}),
            onNoticeChange: (key, value) =>
                setState(() => _noticeValues = {..._noticeValues, key: value}),
            onNoticeValuesChange: (next) =>
                setState(() => _noticeValues = next),
            onMeasureUnit: _handleMeasureUnit,
            disabled: _readOnly || _isSaving,
            onlyRequired: _onlyRequired,
            onOnlyRequiredChange: (v) => setState(() => _onlyRequired = v),
            hideCategoryAttrs: _hideCategoryAttrs,
            noticeGroup: _noticeGroup,
            onNoticeGroupChange: _handleNoticeGroupChange,
          ),
          if (_readOnly)
            _Banner(
              text: '이 플랫폼 값 저장은 후속입니다. 현재는 스키마만 표시됩니다.',
              background: scheme.surfaceContainerLow,
              foreground: scheme.onSurfaceVariant,
              fontSize: 12,
            )
          else
            FilledButton(
              onPressed: _isSaving || missingRequired ? null : _handleSave,
              child: _isSaving ? const _BusyLabel('저장 중...') : const Text('저장'),
            ),
        ],
      ),
    );
  }
}

/// Colored line (web `rounded bg-… px-3 py-2 text-sm text-…`).
class _Banner extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final double fontSize;

  const _Banner({
    required this.text,
    required this.background,
    required this.foreground,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: fontSize, color: foreground),
        ),
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
