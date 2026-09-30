import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/detail_content.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_route_args.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/detail_editor_tabs.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

/// Detail page editor for one channel cell (FEATURE_2609_80 / 06 — web
/// `master-products/[id]/detail/[listingId]/page.tsx` @09208a0).
///
/// **File**: lib/features/master_product/presentation/pages/master_detail_edit_page.dart
///
/// The page owns `generated` (single source) and the resolved `template`;
/// child tabs lift updates via `onGenerated` / `onTemplateChanged`.
/// `source` always derives from `generated.source`.
///
/// Entry = master detail channel row [⋯ > 상세 편집].
/// ⚠️ No ADMIN gate (PLAN R-a) — a 403 surfaces as the load error.
class MasterDetailEditPage extends StatefulWidget {
  final int masterId;
  final int listingId;

  const MasterDetailEditPage({
    required this.masterId,
    required this.listingId,
    super.key,
  });

  @override
  State<MasterDetailEditPage> createState() => _MasterDetailEditPageState();
}

class _MasterDetailEditPageState extends State<MasterDetailEditPage> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  GeneratedProduct? _generated;
  DetailTemplate? _template;
  String _masterName = '';
  bool _isLoading = true;
  String _error = '';

  // Web `alive` guard.
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MasterDetailEditPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.masterId != widget.masterId ||
        oldWidget.listingId != widget.listingId) {
      _load();
    }
  }

  Future<void> _load() async {
    final seq = ++_loadSeq;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final generatedFuture = _useCase.getGenerated(widget.listingId);
    final templateFuture = _useCase.getResolvedDetailTemplate(widget.listingId);
    final masterFuture = _useCase.getMaster(widget.masterId);
    await Future.wait<Object>([generatedFuture, templateFuture, masterFuture]);
    final generatedResult = await generatedFuture;
    final templateResult = await templateFuture;
    final masterResult = await masterFuture;
    if (!mounted || seq != _loadSeq) {
      return;
    }
    final failed = generatedResult.isLeft() ||
        templateResult.isLeft() ||
        masterResult.isLeft();
    setState(() {
      if (failed) {
        _error = '상세 편집 정보를 불러오지 못했습니다.';
      } else {
        _generated = generatedResult.fold((_) => null, (g) => g);
        _template = templateResult.fold((_) => null, (t) => t);
        _masterName = masterResult.fold((_) => '', (m) => m.name);
      }
      _isLoading = false;
    });
  }

  void _toDetail() {
    context.goNamed(
      Routes.masterProductDetail,
      pathParameters: {'id': '${widget.masterId}'},
      extra: const MasterDetailArgs(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final generated = _generated;
    final template = _template;
    final source = generated?.source;
    final isManual = source == GeneratedSourceCode.manualOverride;
    return ScaffoldWithNavBar(
      title: _masterName.isEmpty ? '상세 편집' : _masterName,
      navBarIndex: 2,
      onBackPressed: _toDetail,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          kBottomNavigationBarHeight + 24,
        ),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '채널 리스팅 #${widget.listingId} 상세페이지',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (source != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isManual
                        ? AppColors.warningSurface
                        : AppColors.successSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isManual ? '수동 수정됨' : '자동생성',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isManual
                          ? AppColors.warningForeground
                          : AppColors.successForeground,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error.isNotEmpty) ...[
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
            const SizedBox(height: 16),
          ],
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
          else if (generated != null && template != null)
            DetailEditorTabs(
              masterId: widget.masterId,
              listingId: widget.listingId,
              generated: generated,
              template: template,
              onGenerated: (next) => setState(() => _generated = next),
              onTemplateChanged: (next) => setState(() => _template = next),
            )
          else if (_error.isEmpty)
            Text(
              '표시할 상세 데이터가 없습니다.',
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
