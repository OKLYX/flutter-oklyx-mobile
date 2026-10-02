import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_network_image.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';

bool _isReserved(String key) => kBuiltinFieldKeys.contains(key);

// Korean labels for the reserved keys (shown even when the template omits them).
const Map<String, String> _reservedLabels = {
  'brandName': '브랜드명',
  'productName': '상품명',
};

/// Tab 4 — channel cell thumbnail (view / regenerate / upload override /
/// clear override). FEATURE_2609_80 / 06.
///
/// **File**: lib/features/master_product/presentation/widgets/thumbnail_pane.dart
/// **Web original**: `master-products/[id]/detail/[listingId]/components/ThumbnailPane.tsx` @09208a0
///
/// Badge / override state always derive from `generated.thumbnailSource`
/// (separate from the detail `source`). Field values are edited inline;
/// [저장 후 재생성] saves them with updateListingFieldValues, which regenerates
/// thumbnail + detail. Reserved keys fall back to the product value when blank,
/// custom keys to the template default. While overridden only the thumbnail is
/// kept (field values and detail still update).
class ThumbnailPane extends StatefulWidget {
  final int listingId;
  final GeneratedProduct generated;
  final ValueChanged<GeneratedProduct> onGenerated;

  const ThumbnailPane({
    required this.listingId,
    required this.generated,
    required this.onGenerated,
    super.key,
  });

  @override
  State<ThumbnailPane> createState() => _ThumbnailPaneState();
}

class _ThumbnailPaneState extends State<ThumbnailPane> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();
  final ImagePicker _picker = ImagePicker();

  bool _isRegenerating = false;
  bool _isUploading = false;
  bool _isClearing = false;
  String _error = '';

  // Cache-buster: the same S3 URL after a re-upload would hit the image cache.
  // Bumped after each action (0 on first render = no buster on the untouched image).
  int _bust = 0;

  // Default-template fields drive the inline field-value panel. Non-fatal: on
  // failure the panel shows only the reserved keys and the backend uses defaults.
  List<TemplateField> _fields = [];
  bool _fieldsLoading = true;
  Map<String, String> _values = {};
  final Map<String, TextEditingController> _controllers = {};

  bool get _busy => _isRegenerating || _isUploading || _isClearing;

  bool get _isOverridden =>
      widget.generated.thumbnailSource == GeneratedSourceCode.manualOverride;

  // Reserved keys (brandName/productName) are always editable, even if the
  // template omits them; template-defined fields override the label and add
  // custom keys.
  List<TemplateField> get _effectiveFields {
    final byKey = <String, TemplateField>{};
    for (final key in kBuiltinFieldKeys) {
      byKey[key] = TemplateField(
        key: key,
        label: _reservedLabels[key] ?? key,
        defaultValue: '',
      );
    }
    for (final f in _fields) {
      byKey[f.key] = f;
    }
    return byKey.values.toList();
  }

  @override
  void initState() {
    super.initState();
    _values = {...widget.generated.fieldValues};
    _syncControllers();
    _loadFields();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// One controller per effective field (R2 — never created in build).
  void _syncControllers() {
    for (final f in _effectiveFields) {
      _controllers.putIfAbsent(
        f.key,
        () => TextEditingController(text: _values[f.key] ?? ''),
      );
    }
  }

  Future<void> _loadFields() async {
    setState(() => _fieldsLoading = true);
    final result = await _useCase.listThumbnailTemplates();
    if (!mounted) {
      return;
    }
    setState(() {
      // Non-fatal on failure: regenerate still uses persisted/default values.
      result.fold((_) {}, (templates) {
        for (final t in templates) {
          if (t.isDefault) {
            _fields = t.fields;
            break;
          }
        }
      });
      _syncControllers();
      _fieldsLoading = false;
    });
  }

  String? get _imageUrl {
    final url = widget.generated.thumbnailUrl;
    if (url == null || url.isEmpty) {
      return null;
    }
    return _bust == 0 ? url : '$url${url.contains('?') ? '&' : '?'}t=$_bust';
  }

  Future<void> _handleRegenerate() async {
    setState(() {
      _isRegenerating = true;
      _error = '';
    });
    // Omit blank values so the backend falls back to product/template defaults.
    final result = await _useCase.updateListingFieldValues(widget.listingId, {
      for (final e in _values.entries)
        if (e.value.trim().isNotEmpty) e.key: e.value,
    });
    if (!mounted) {
      return;
    }
    result.fold(
      (_) => setState(() {
        _error = '썸네일 처리에 실패했습니다.';
        _isRegenerating = false;
      }),
      (res) {
        widget.onGenerated(res);
        setState(() {
          _bust = DateTime.now().millisecondsSinceEpoch;
          _isRegenerating = false;
        });
      },
    );
  }

  Future<void> _handleUpload() async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery);
    if (xFile == null || !mounted) {
      return;
    }
    setState(() {
      _isUploading = true;
      _error = '';
    });
    final result = await _useCase.overrideListingThumbnail(
      widget.listingId,
      File(xFile.path),
    );
    if (!mounted) {
      return;
    }
    result.fold(
      (failure) => setState(() {
        _error = failure is ServerFailure && failure.statusCode == 400
            ? '파일을 확인해 주세요 (JPG/PNG).'
            : '썸네일 처리에 실패했습니다.';
        _isUploading = false;
      }),
      (res) {
        widget.onGenerated(res);
        setState(() {
          _bust = DateTime.now().millisecondsSinceEpoch;
          _isUploading = false;
        });
      },
    );
  }

  Future<void> _handleClear() async {
    final ok = await showAppConfirmDialog(
      context,
      message: '수동 썸네일을 삭제하고 자동 생성으로 되돌립니다.',
      confirmText: '되돌리기',
      isDangerous: true,
    );
    if (!ok || !mounted) {
      return;
    }
    setState(() {
      _isClearing = true;
      _error = '';
    });
    final result = await _useCase.clearListingThumbnail(widget.listingId);
    if (!mounted) {
      return;
    }
    result.fold(
      (_) => setState(() {
        _error = '썸네일 처리에 실패했습니다.';
        _isClearing = false;
      }),
      (res) {
        widget.onGenerated(res);
        setState(() {
          _bust = DateTime.now().millisecondsSinceEpoch;
          _isClearing = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOverridden = _isOverridden;
    return Column(
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
          const SizedBox(height: 16),
        ],
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(4),
              ),
              clipBehavior: Clip.antiAlias,
              child: MasterNetworkImage(
                url: _imageUrl,
                width: 192,
                height: 192,
                placeholder: '썸네일 없음',
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverridden
                        ? AppColors.warningSurface
                        : AppColors.successSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isOverridden ? '수동 교체됨' : '자동 생성',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isOverridden
                          ? AppColors.warningForeground
                          : AppColors.successForeground,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isOverridden
                      ? '직접 올린 이미지가 적용된 상태입니다. [저장 후 재생성]해도 썸네일은 그대로 유지되고 필드값·상세만 갱신됩니다. 자동 생성으로 되돌리려면 [자동 생성으로 되돌리기]를 누르세요.'
                      : '아래 필드값을 채우고 [저장 후 재생성]하면 썸네일·상세에 반영됩니다.',
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Text(
          '필드값 (재생성 시 적용)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (_fieldsLoading)
          const SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppBusyLabel('필드 불러오는 중...'),
            ),
          )
        else
          for (final f in _effectiveFields) ..._fieldInput(f),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: _busy ? null : _handleRegenerate,
              child: _isRegenerating
                  ? const AppBusyLabel('재생성 중...')
                  : const Text('저장 후 재생성'),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _handleUpload,
              child: _isUploading
                  ? const AppBusyLabel('업로드 중...')
                  : const Text('이미지 업로드로 교체'),
            ),
            if (isOverridden)
              OutlinedButton(
                onPressed: _busy ? null : _handleClear,
                child: _isClearing
                    ? const AppBusyLabel('되돌리는 중...')
                    : const Text('자동 생성으로 되돌리기'),
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> _fieldInput(TemplateField f) {
    final controller = _controllers[f.key];
    if (controller == null) {
      return const [];
    }
    return [
      const SizedBox(height: 12),
      TextField(
        controller: controller,
        enabled: !_busy,
        decoration: InputDecoration(
          labelText: f.label,
          hintText: _isReserved(f.key) ? '등록상품값 사용' : '템플릿 기본값 사용',
        ),
        onChanged: (value) =>
            setState(() => _values = {..._values, f.key: value}),
      ),
    ];
  }
}
