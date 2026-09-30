import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/detail_html_view.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// Tab 1 — preview of the AUTO generated result that ignores any override
/// (for comparison). FEATURE_2609_80 / 06.
///
/// **File**: lib/features/master_product/presentation/widgets/auto_preview_pane.dart
/// **Web original**: `master-products/[id]/detail/[listingId]/components/AutoPreviewPane.tsx` @09208a0
///
/// Re-fetches the preview whenever [generated] changes (after a save).
class AutoPreviewPane extends StatefulWidget {
  final int listingId;
  final GeneratedProduct generated;

  const AutoPreviewPane({
    required this.listingId,
    required this.generated,
    super.key,
  });

  @override
  State<AutoPreviewPane> createState() => _AutoPreviewPaneState();
}

class _AutoPreviewPaneState extends State<AutoPreviewPane> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  String _html = '';
  bool _isLoading = true;
  String _error = '';

  // Web `alive` guard — only the latest request may write state.
  int _requestSeq = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AutoPreviewPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-fetch after a save (generated identity changes).
    if (oldWidget.listingId != widget.listingId ||
        !identical(oldWidget.generated, widget.generated)) {
      _load();
    }
  }

  Future<void> _load() async {
    final seq = ++_requestSeq;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final result = await _useCase.previewDetail(widget.listingId);
    if (!mounted || seq != _requestSeq) {
      return;
    }
    setState(() {
      result.fold(
        (_) => _error = '미리보기를 불러오지 못했습니다.',
        (html) => _html = html,
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOverridden =
        widget.generated.source == GeneratedSourceCode.manualOverride;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _notice(
          '현재 저장본이 아니라 자동생성 결과 미리보기입니다.',
          AppColors.infoSurface,
          AppColors.infoForeground,
        ),
        if (isOverridden) ...[
          const SizedBox(height: 12),
          _notice(
            '수동 override 가 적용 중입니다 — 실제 저장본은 "상세 페이지 > HTML 직접수정" 에서 확인하세요.',
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
        if (_isLoading)
          const SizedBox(
            height: 160,
            child: Center(
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
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: DetailHtmlView(html: _html, height: 480),
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
