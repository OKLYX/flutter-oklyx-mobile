import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/measure_attributes.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/category_meta_fields.dart';

/// Per-platform value held by the parent create form (web
/// `CategoryMetaCreateValue`).
class CategoryMetaCreateValue {
  final Map<String, String> attrValues;
  final Map<String, String> noticeValues;

  /// Selected notice group; null = the effective group. Only this group is
  /// saved.
  final String? noticeGroup;

  const CategoryMetaCreateValue({
    required this.attrValues,
    required this.noticeValues,
    this.noticeGroup,
  });
}

/// Web `EMPTY_META_VALUE`.
const kEmptyMetaValue =
    CategoryMetaCreateValue(attrValues: {}, noticeValues: {});

/// Category required attributes / notices — create container (no master id
/// yet). Port of web
/// `app/dashboard/master-products/[id]/components/CategoryMetaCreateFields.tsx`
/// (@09208a0).
///
/// **Purpose**: loads the schema for [categoryId] (values stay in the
/// parent's [value]) and renders [CategoryMetaFields]. No save button — the
/// parent saves after creating the master. Reloads when [categoryId] or
/// [platform] changes.
/// **File**: lib/features/master_product/presentation/widgets/category_meta_create_fields.dart
///
/// **Usage**:
/// ```dart
/// CategoryMetaCreateFields(
///   categoryId: _categoryId,
///   value: _meta,
///   onChanged: (next) => setState(() => _meta = next),
///   onSchemaLoad: (attrs, notices) => setState(() { _attrs = attrs; _notices = notices; }),
/// )
/// MetaPlatformTabs(builder: (platform) => CategoryMetaCreateFields(platform: platform, ...))
/// ```
///
/// ⚠️ [onSchemaLoad] reports the loaded schema so the parent's submit gate can
///    validate; it is read from the widget at call time (always the latest).
/// ❌ Do not fetch the schema again in the parent.
class CategoryMetaCreateFields extends StatefulWidget {
  final int? categoryId;
  final CategoryMetaCreateValue value;
  final ValueChanged<CategoryMetaCreateValue> onChanged;
  final void Function(
          List<CategoryAttribute> attributes, List<CategoryNotice> notices)
      onSchemaLoad;
  final String platform;
  final bool hideCategoryAttrs;

  const CategoryMetaCreateFields({
    required this.categoryId,
    required this.value,
    required this.onChanged,
    required this.onSchemaLoad,
    super.key,
    this.platform = 'COUPANG',
    this.hideCategoryAttrs = false,
  });

  @override
  State<CategoryMetaCreateFields> createState() =>
      _CategoryMetaCreateFieldsState();
}

class _CategoryMetaCreateFieldsState extends State<CategoryMetaCreateFields> {
  List<CategoryAttribute> _attributes = const [];
  List<CategoryNotice> _notices = const [];
  bool _isLoading = false;
  String _error = '';
  // Display filter, checked by default: 필수 항목만 보기.
  bool _onlyRequired = true;
  // Guards against results of a superseded load (web `alive`).
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _startLoad();
  }

  @override
  void didUpdateWidget(covariant CategoryMetaCreateFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoryId != oldWidget.categoryId ||
        widget.platform != oldWidget.platform) {
      _startLoad();
    }
  }

  // Runs before build (initState / didUpdateWidget) — fields are assigned
  // directly; the parent callback is deferred past the current frame.
  void _startLoad() {
    final seq = ++_loadSeq;
    final categoryId = widget.categoryId;
    if (categoryId == null) {
      _attributes = const [];
      _notices = const [];
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && seq == _loadSeq) {
          widget.onSchemaLoad(const [], const []);
        }
      });
      return;
    }
    _isLoading = true;
    _error = '';
    unawaited(_fetch(seq, categoryId, widget.platform));
  }

  Future<void> _fetch(int seq, int categoryId, String platform) async {
    final result = await getIt<MasterProductUseCase>()
        .getCategorySchema(categoryId, platform);
    if (!mounted || seq != _loadSeq) {
      return;
    }
    result.fold(
      (failure) {
        setState(() {
          _attributes = const [];
          _notices = const [];
          _error = failureText(failure, '카테고리 필수속성을 불러오지 못했습니다. 매핑을 확인하세요.');
          _isLoading = false;
        });
        widget.onSchemaLoad(const [], const []);
      },
      (schema) {
        setState(() {
          _attributes = schema.attributes;
          _notices = schema.notices;
          _isLoading = false;
        });
        widget.onSchemaLoad(schema.attributes, schema.notices);
      },
    );
  }

  CategoryMetaCreateValue _with({
    Map<String, String>? attrValues,
    Map<String, String>? noticeValues,
    String? noticeGroup,
  }) {
    final value = widget.value;
    return CategoryMetaCreateValue(
      attrValues: attrValues ?? value.attrValues,
      noticeValues: noticeValues ?? value.noticeValues,
      noticeGroup: noticeGroup ?? value.noticeGroup,
    );
  }

  // A picked unit clears the other side of the pair.
  void _handleMeasureUnit(MeasurePair p, String unit) {
    final clearName = unit == '중량'
        ? p.volume.name
        : unit == '용량'
            ? p.weight.name
            : '';
    if (clearName.isEmpty) {
      return;
    }
    widget.onChanged(
        _with(attrValues: {...widget.value.attrValues, clearName: ''}));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final grayText = TextStyle(fontSize: 14, color: scheme.onSurfaceVariant);

    if (widget.categoryId == null) {
      return _box(
        context,
        Text('카테고리를 선택하면 필수속성/고시 입력이 표시됩니다.', style: grayText),
      );
    }

    if (_isLoading) {
      return const SizedBox(
        height: 64,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('불러오는 중...'),
            ],
          ),
        ),
      );
    }

    final value = widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: scheme.errorContainer,
            child: Text(_error,
                style: TextStyle(fontSize: 14, color: scheme.error)),
          ),
          const SizedBox(height: 12),
        ],
        CategoryMetaFields(
          attributes: _attributes,
          notices: _notices,
          attrValues: value.attrValues,
          noticeValues: value.noticeValues,
          onAttrChange: (name, v) => widget
              .onChanged(_with(attrValues: {...value.attrValues, name: v})),
          onNoticeChange: (key, v) => widget
              .onChanged(_with(noticeValues: {...value.noticeValues, key: v})),
          onNoticeValuesChange: (next) =>
              widget.onChanged(_with(noticeValues: next)),
          onMeasureUnit: _handleMeasureUnit,
          onlyRequired: _onlyRequired,
          onOnlyRequiredChange: (only) => setState(() => _onlyRequired = only),
          hideCategoryAttrs: widget.hideCategoryAttrs,
          noticeGroup: value.noticeGroup,
          onNoticeGroupChange: (group) =>
              widget.onChanged(_with(noticeGroup: group)),
        ),
        if (widget.platform != 'COUPANG')
          _box(
            context,
            Text(
              '이 플랫폼 값 저장은 후속입니다. 생성 시 COUPANG 값만 반영됩니다.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  Widget _box(BuildContext context, Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
        ),
        child: child,
      );
}
