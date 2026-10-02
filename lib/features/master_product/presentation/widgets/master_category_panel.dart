import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/category_tree_list.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';

/// Standard category assignment panel on the master detail screen —
/// FEATURE_2609_80 / 07. A master points at one standard category; per-mall
/// codes are resolved by the category mappings.
///
/// **File**: lib/features/master_product/presentation/widgets/master_category_panel.dart
/// **Web original**: `master-products/[id]/components/MasterCategoryPanel.tsx` @09208a0
///
/// Assign = one-level-at-a-time tree drill-down ([CategoryTreeList], R-h);
/// picking a leaf assigns it immediately. Mapping badges are read-only — the
/// `카테고리 관리` links open the existing category screen.
///
/// ⚠️ The category feeds sibling sections (category meta, option inheritance)
///    → every assign/clear is reported through [onCategoryChanged]
///    (assign = the server response, clear = `null`). The parent swaps only
///    that value and does not refetch the whole detail.
/// ❌ Draws no card shell or title — the detail page wraps it (09).
class MasterCategoryPanel extends StatefulWidget {
  final int masterId;
  final ValueChanged<MasterCategory?>? onCategoryChanged;

  const MasterCategoryPanel({
    required this.masterId,
    super.key,
    this.onCategoryChanged,
  });

  @override
  State<MasterCategoryPanel> createState() => _MasterCategoryPanelState();
}

class _MasterCategoryPanelState extends State<MasterCategoryPanel> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  MasterCategory? _current;
  List<CategoryMapping> _mappings = [];
  bool _isLoading = true;
  String _error = '';

  // Whether the tree drill-down is open for (re)assigning the category.
  bool _isTreeOpen = false;
  bool _isSaving = false;
  bool _isClearing = false;

  bool get _busy => _isSaving || _isClearing;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant MasterCategoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.masterId != widget.masterId) {
      unawaited(_load());
    }
  }

  // Stable method tear-off so CategoryTreeList does not reload every build.
  Future<List<CategoryTreeNode>> _browseTree(int? parentId) async {
    final result = await _useCase.browseCategoryTree(parentId: parentId);
    return result.fold(
      // CategoryTreeList contract: throw the Failure to show its message.
      // ignore: only_throw_errors
      (failure) => throw failure,
      (nodes) => nodes,
    );
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final result = await _useCase.getMasterCategory(widget.masterId);
    if (!mounted) {
      return;
    }
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      setState(() {
        _error = failureText(failure, '표준 카테고리를 불러오지 못했습니다.');
        _isLoading = false;
      });
      return;
    }
    final cat = result.getOrElse((_) => null);
    var mappings = <CategoryMapping>[];
    if (cat != null) {
      final m = await _useCase.getCategoryMappings(cat.categoryId);
      if (!mounted) {
        return;
      }
      mappings = m.getOrElse((_) => <CategoryMapping>[]);
    }
    setState(() {
      _current = cat;
      _mappings = mappings;
      _isLoading = false;
    });
  }

  // Leaf picked in the tree → assign it to this master immediately,
  // then reload.
  Future<void> _handleSelectLeaf(CategoryTreeNode leaf) async {
    setState(() {
      _isSaving = true;
      _error = '';
    });
    final result = await _useCase.setMasterCategory(widget.masterId, leaf.id);
    if (!mounted) {
      return;
    }
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      setState(() {
        _error = failureText(failure, '카테고리 지정에 실패했습니다.');
        _isSaving = false;
      });
      return;
    }
    setState(() => _isTreeOpen = false);
    await _load();
    if (!mounted) {
      return;
    }
    widget.onCategoryChanged?.call(result.getOrElse((_) => null));
    setState(() => _isSaving = false);
  }

  Future<void> _handleClear() async {
    final ok = await showAppConfirmDialog(
      context,
      message: '표준 카테고리 지정을 해제하시겠습니까?',
      confirmText: '해제',
      isDangerous: true,
    );
    if (!ok || !mounted) {
      return;
    }
    setState(() {
      _isClearing = true;
      _error = '';
    });
    final result = await _useCase.clearMasterCategory(widget.masterId);
    if (!mounted) {
      return;
    }
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      setState(() {
        _error = failureText(failure, '해제에 실패했습니다.');
        _isClearing = false;
      });
      return;
    }
    await _load();
    if (!mounted) {
      return;
    }
    widget.onCategoryChanged?.call(null);
    setState(() => _isClearing = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = _current;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error.isNotEmpty) ...[
            _ErrorBox(_error),
            const SizedBox(height: 12),
          ],
          if (_isLoading)
            const SizedBox(
              height: 64,
              child: Center(child: AppBusyLabel('불러오는 중...', size: 20)),
            )
          else if (current != null) ...[
            Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 14),
                children: [
                  const TextSpan(text: '현재 표준 카테고리: '),
                  TextSpan(
                    text: current.categoryName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_mappings.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final m in _mappings)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.infoSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${m.platform} ✓',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.infoForeground,
                        ),
                      ),
                    ),
                ],
              )
            else
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    '몰 매핑이 없습니다 — 해당 채널 등록 시 매핑이 필요합니다. ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warningForeground,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pushNamed(Routes.categoryList),
                    style: _linkStyle(AppColors.warningForeground),
                    child: const Text('카테고리 관리에서 매핑'),
                  ),
                ],
              ),
            const SizedBox(height: 12),
          ] else ...[
            Text(
              '표준 카테고리 미설정 — 채널 등록 전 지정이 필요합니다.',
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
          ],
          if (!_isLoading) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _isTreeOpen = !_isTreeOpen),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.infoForeground,
                    side: const BorderSide(color: AppColors.infoBorder),
                  ),
                  child: Text(
                    _isTreeOpen
                        ? '트리 닫기'
                        : current != null
                            ? '카테고리 변경'
                            : '카테고리 지정',
                  ),
                ),
                if (current != null)
                  OutlinedButton(
                    onPressed: _busy ? null : _handleClear,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                    ),
                    child: _isClearing
                        ? const AppBusyLabel('해제 중...')
                        : const Text('해제'),
                  ),
                if (_isSaving) const AppBusyLabel('저장 중...'),
              ],
            ),
            if (_isTreeOpen) ...[
              const SizedBox(height: 12),
              CategoryTreeList(
                browse: _browseTree,
                selectedId: current?.categoryId,
                onSelectLeaf: (leaf, _) => unawaited(_handleSelectLeaf(leaf)),
              ),
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '세부(leaf) 카테고리를 선택하면 즉시 지정됩니다. 카테고리가 없으면 ',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pushNamed(Routes.categoryList),
                    style: _linkStyle(AppColors.infoForeground),
                    child: const Text('카테고리 관리'),
                  ),
                  Text(
                    '에서 import·추가하세요.',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  // Inline underlined text link (web `<Link className="underline">`).
  ButtonStyle _linkStyle(Color color) => TextButton.styleFrom(
        foregroundColor: color,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(
          fontSize: 12,
          decoration: TextDecoration.underline,
        ),
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
