import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/detail_content.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/detail_html_view.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';

/// "상세 페이지 > 템플릿 변경" (2609_20). Picks the detail template for this
/// channel cell, previews it (not persisted) and then [저장]/[취소].
/// FEATURE_2609_80 / 06.
///
/// **File**: lib/features/master_product/presentation/widgets/template_switch_pane.dart
/// **Web original**: `master-products/[id]/detail/[listingId]/components/TemplateSwitchPane.tsx` @09208a0
///
/// Nothing reaches the server until save (D4). Saving (D7) changes this cell's
/// detailTemplateId and regenerates the detail HTML with the new template.
class TemplateSwitchPane extends StatefulWidget {
  final int listingId;

  /// Used for source / detailTemplateId.
  final GeneratedProduct generated;

  /// Currently resolved template (name shown in the default option).
  final DetailTemplate template;
  final ValueChanged<GeneratedProduct> onGenerated;
  final ValueChanged<DetailTemplate> onTemplateChanged;

  const TemplateSwitchPane({
    required this.listingId,
    required this.generated,
    required this.template,
    required this.onGenerated,
    required this.onTemplateChanged,
    super.key,
  });

  @override
  State<TemplateSwitchPane> createState() => _TemplateSwitchPaneState();
}

class _TemplateSwitchPaneState extends State<TemplateSwitchPane> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  List<DetailTemplate> _templates = [];
  int? _selectedId;
  String _previewHtml = '';
  bool _isLoadingList = true;
  bool _isPreviewing = false;
  bool _isSaving = false;
  bool _listFailed = false;
  String _error = '';

  // Web `alive` guard: when the dropdown changes twice quickly, a late older
  // response must not overwrite the latest HTML.
  int _previewSeq = 0;

  bool get _isOverridden =>
      widget.generated.source == GeneratedSourceCode.manualOverride;

  bool get _isDirty => _selectedId != widget.generated.detailTemplateId;

  bool get _busy => _isLoadingList || _isPreviewing || _isSaving;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.generated.detailTemplateId;
    _loadList();
    _loadPreview();
  }

  @override
  void didUpdateWidget(covariant TemplateSwitchPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listingId != widget.listingId) {
      _loadPreview();
    }
  }

  // Dropdown list (once on mount). Switching sub tabs remounts and reloads — intended.
  Future<void> _loadList() async {
    setState(() => _isLoadingList = true);
    final result = await _useCase.listDetailTemplates();
    if (!mounted) {
      return;
    }
    setState(() {
      result.fold(
        (_) {
          _listFailed = true;
          _error = '템플릿 목록을 불러오지 못했습니다.';
        },
        (list) {
          _templates = list.where((t) => t.active).toList();
          _listFailed = false;
        },
      );
      _isLoadingList = false;
    });
  }

  // This alone owns the preview — also runs once right after mount with the
  // current selection.
  Future<void> _loadPreview() async {
    final seq = ++_previewSeq;
    setState(() => _isPreviewing = true);
    final result = await _useCase.previewDetail(
      widget.listingId,
      templateId: _selectedId,
    );
    if (!mounted || seq != _previewSeq) {
      return;
    }
    setState(() {
      result.fold(
        // Keep the previous HTML (a stale preview beats an empty box).
        (_) => _error = '미리보기를 불러오지 못했습니다.',
        (html) {
          _previewHtml = html;
          _error = '';
        },
      );
      _isPreviewing = false;
    });
  }

  void _select(int? id) {
    if (id == _selectedId) {
      return;
    }
    setState(() => _selectedId = id);
    _loadPreview();
  }

  Future<void> _handleSave() async {
    if (_isOverridden) {
      final ok = await showAppConfirmDialog(
        context,
        message: '직접 수정한 HTML 이 사라지고 선택한 템플릿의 자동생성본으로 대체됩니다. 계속하시겠습니까?',
        confirmText: '저장',
        isDangerous: true,
      );
      if (!ok || !mounted) {
        return;
      }
    }
    setState(() {
      _isSaving = true;
      _error = '';
    });
    final result =
        await _useCase.updateDetailTemplate(widget.listingId, _selectedId);
    if (!mounted) {
      return;
    }
    final saved = result.fold((_) => null, (res) => res);
    if (saved == null) {
      setState(() {
        _error = '템플릿 변경을 저장하지 못했습니다.';
        _isSaving = false;
      });
      return;
    }
    widget.onGenerated(saved);
    // The PATCH already succeeded here; a failure below must not be reported
    // as a save failure. The structure tab uses blocks, so refresh the
    // resolved template too.
    final resolved = await _useCase.getResolvedDetailTemplate(widget.listingId);
    if (!mounted) {
      return;
    }
    resolved.fold(
      (_) => setState(() {
        _error = '저장은 완료됐지만 구조 데이터 갱신에 실패했습니다. 새로고침해 주세요.';
      }),
      widget.onTemplateChanged,
    );
    setState(() => _isSaving = false);
  }

  // Only resets the selection; the preview reload follows the selection.
  void _handleCancel() => _select(widget.generated.detailTemplateId);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ids = _templates.map((t) => t.id).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _notice(
          '미리보기는 저장되지 않습니다. [저장]을 눌러야 이 채널 셀에 적용됩니다 — 다른 상품·다른 채널에는 영향 없습니다.',
          AppColors.infoSurface,
          AppColors.infoForeground,
        ),
        if (_isOverridden) ...[
          const SizedBox(height: 12),
          _notice(
            '이 셀은 HTML 직접수정 상태입니다. 템플릿을 저장하면 수정본이 사라집니다.',
            AppColors.warningSurface,
            AppColors.warningForeground,
          ),
        ],
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
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
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          // An id outside the active list falls back to the default row
          // (a value missing from items would assert).
          initialValue: ids.contains(_selectedId) ? _selectedId : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '상세 템플릿'),
          items: [
            DropdownMenuItem<int?>(
              child: Text(
                '기본값 사용 (계정/테넌트 기본: ${widget.template.name})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            for (final t in _templates)
              DropdownMenuItem<int?>(
                value: t.id,
                child: Text(
                  '${t.name}${t.isDefault ? ' (기본)' : ''}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged:
              _isLoadingList || _listFailed || _isSaving ? null : _select,
        ),
        if (_isLoadingList) ...[
          const SizedBox(height: 8),
          const AppBusyLabel('목록 불러오는 중...'),
        ],
        if (!_isLoadingList && !_listFailed && _templates.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '선택 가능한 템플릿이 없습니다',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 12),
        const Text('미리보기', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          clipBehavior: Clip.antiAlias,
          child: _isPreviewing
              ? const SizedBox(
                  height: 160,
                  child: Center(child: AppBusyLabel('불러오는 중...')),
                )
              : DetailHtmlView(html: _previewHtml, height: 480),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: !_isDirty || _busy || _listFailed ? null : _handleSave,
              child: _isSaving ? const AppBusyLabel('저장 중...') : const Text('저장'),
            ),
            OutlinedButton(
              onPressed: !_isDirty || _busy ? null : _handleCancel,
              child: const Text('취소'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _notice(String text, Color background, Color foreground) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text, style: TextStyle(fontSize: 12, color: foreground)),
      );
}
