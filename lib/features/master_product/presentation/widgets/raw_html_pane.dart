import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/detail_html_view.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';

/// "상세 페이지 > HTML 직접수정" — raw HTML override (MANUAL_OVERRIDE). Edits
/// or reverts the current saved copy. FEATURE_2609_80 / 06.
///
/// **File**: lib/features/master_product/presentation/widgets/raw_html_pane.dart
/// **Web original**: `master-products/[id]/detail/[listingId]/components/RawHtmlPane.tsx` @09208a0
///
/// Saving an empty string is allowed (the backend @NotNull only rejects null).
/// Mobile layout = source box on top, live preview below (web shows them side by side).
class RawHtmlPane extends StatefulWidget {
  final int listingId;
  final GeneratedProduct generated;
  final ValueChanged<GeneratedProduct> onGenerated;

  const RawHtmlPane({
    required this.listingId,
    required this.generated,
    required this.onGenerated,
    super.key,
  });

  @override
  State<RawHtmlPane> createState() => _RawHtmlPaneState();
}

class _RawHtmlPaneState extends State<RawHtmlPane> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  final TextEditingController _htmlController = TextEditingController();
  String _html = '';
  bool _isSaving = false;
  bool _isClearing = false;
  String _error = '';

  bool get _busy => _isSaving || _isClearing;

  @override
  void initState() {
    super.initState();
    _html = widget.generated.detailHtml ?? '';
    _htmlController.text = _html;
  }

  @override
  void dispose() {
    _htmlController.dispose();
    super.dispose();
  }

  void _setHtml(String next) {
    _html = next;
    if (_htmlController.text != next) {
      _htmlController.text = next;
    }
  }

  Future<void> _handleOverride() async {
    setState(() {
      _isSaving = true;
      _error = '';
    });
    final result = await _useCase.overrideDetailHtml(widget.listingId, _html);
    if (!mounted) {
      return;
    }
    result.fold(
      (_) => setState(() {
        _error = '직접 작성한 내용을 저장하지 못했습니다.';
        _isSaving = false;
      }),
      (res) {
        setState(() {
          _setHtml(res.detailHtml ?? '');
          _isSaving = false;
        });
        widget.onGenerated(res);
      },
    );
  }

  Future<void> _handleClear() async {
    final ok = await showAppConfirmDialog(
      context,
      message: '직접 수정한 내용을 버리고 템플릿 자동생성 결과로 되돌립니다. 계속하시겠습니까?',
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
    final result = await _useCase.clearDetailHtml(widget.listingId);
    if (!mounted) {
      return;
    }
    result.fold(
      (_) => setState(() {
        _error = '자동생성 복귀에 실패했습니다.';
        _isClearing = false;
      }),
      (res) {
        setState(() {
          _setHtml(res.detailHtml ?? '');
          _isClearing = false;
        });
        widget.onGenerated(res);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.warningSurface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '저장하면 이 채널은 직접 수정한 상태가 되어, 재생성해도 여기 작성한 HTML 이 그대로 유지됩니다.',
            style: TextStyle(fontSize: 12, color: AppColors.warningForeground),
          ),
        ),
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
        SizedBox(
          height: 384,
          child: TextField(
            controller: _htmlController,
            maxLines: null,
            minLines: 16,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'HTML 원본',
              contentPadding: EdgeInsets.all(8),
            ),
            onChanged: (value) => setState(() => _html = value),
          ),
        ),
        const SizedBox(height: 16),
        const Text('미리보기', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          clipBehavior: Clip.antiAlias,
          child: DetailHtmlView(html: _html, height: 384),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: _busy ? null : _handleOverride,
              child:
                  _isSaving ? const AppBusyLabel('저장 중...') : const Text('저장하기'),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _handleClear,
              child: _isClearing
                  ? const AppBusyLabel('초기화 중...')
                  : const Text('변경 초기화'),
            ),
          ],
        ),
      ],
    );
  }
}
