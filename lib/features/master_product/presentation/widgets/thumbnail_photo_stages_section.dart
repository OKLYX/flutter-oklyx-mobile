import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/thumbnail_photo.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/thumbnail_photo_labels.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_image_picker_sheet.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_network_image.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';

/// 「단계별 썸네일 사진」 block of the master 「이미지」 tab — port of web
/// `master-products/[id]/components/ThumbnailPhotoStagesPanel.tsx`
/// (FEATURE_2610_32 D29 · D30 (나) · D14 · D32).
/// **File**: lib/features/master_product/presentation/widgets/thumbnail_photo_stages_section.dart
///
/// One row per seller that has a listing of this master and per listing (the
/// master stage is edited only in the 「썸네일 사진」 card of the pool above):
/// the stage, the photo it uses with its status text, the collage notice,
/// [고르기] (one photo of this master's pool) and, for a stage with its own
/// choice, [지우기(위 단계를 따름)]. The block title comes from the caller.
///
/// **Usage**:
/// ```dart
/// ThumbnailPhotoStagesSection(
///   masterId: master.id,
///   reloadKey: _thumbnailPhotoVersion,
///   onChanged: _bumpThumbnailPhotoVersion,
/// )
/// ```
///
/// ⚠️ Choosing never regenerates a thumbnail (D9) — the listing's
///    [저장 후 재생성] applies it.
/// ❌ No collage API call here — the collage notice comes from the same
///    thumbnail-photo response (D31).
class ThumbnailPhotoStagesSection extends StatefulWidget {
  final int masterId;

  /// A change reloads the stages (the pool bumps it after a mapping change).
  final int reloadKey;

  /// Called after a stage was chosen or cleared, so the pool reloads its
  /// 「사용중」 state.
  final VoidCallback onChanged;

  const ThumbnailPhotoStagesSection({
    required this.masterId,
    required this.reloadKey,
    required this.onChanged,
    super.key,
  });

  @override
  State<ThumbnailPhotoStagesSection> createState() =>
      _ThumbnailPhotoStagesSectionState();
}

class _ThumbnailPhotoStagesSectionState
    extends State<ThumbnailPhotoStagesSection> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  List<ThumbnailPhotoStageView> _stages = [];
  bool _isLoading = true;
  bool _busy = false;
  String _error = '';
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant ThumbnailPhotoStagesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadKey != widget.reloadKey ||
        oldWidget.masterId != widget.masterId) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final seq = ++_loadSeq;
    final result = await _useCase.listThumbnailPhotoStages(widget.masterId);
    if (!mounted || seq != _loadSeq) {
      return;
    }
    setState(() {
      result.fold(
        (_) => _error = '썸네일 사진 상태를 불러오지 못했습니다.',
        (stages) {
          _stages = stages;
          _error = '';
        },
      );
      _isLoading = false;
    });
  }

  Future<void> _pick(ThumbnailPhotoStageView view) async {
    setState(() => _error = '');
    final pool = await _useCase.listPoolImages(widget.masterId);
    if (!mounted) {
      return;
    }
    final images = pool.fold((_) => null, (list) {
      final sorted = [...list]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return [
        for (final img in sorted) PickerImage(token: img.id, url: img.imageUrl),
      ];
    });
    if (images == null) {
      setState(() => _error = '이미지 풀을 불러오지 못했습니다.');
      return;
    }
    final tokens = await showAppSheet<List<int>>(
      context,
      builder: (sheetContext) => MasterImagePickerSheet(
        fieldLabel: '단계별 썸네일 사진 · ${thumbnailPhotoStageLabel(view)}',
        single: true,
        images: images,
        initialSelected: view.source == 'OWN' && view.imageId != null
            ? [view.imageId!]
            : const <int>[],
      ),
    );
    if (tokens == null || !mounted) {
      return;
    }
    await _save(view, tokens.isEmpty ? null : tokens.first);
  }

  Future<void> _save(ThumbnailPhotoStageView view, int? imageId) async {
    setState(() {
      _busy = true;
      _error = '';
    });
    final result = await _useCase.setThumbnailPhoto(
      widget.masterId,
      stage: view.stage,
      sellerId: view.stage == 'SELLER' ? view.sellerId : null,
      listingId: view.stage == 'LISTING' ? view.listingId : null,
      imageId: imageId,
    );
    if (!mounted) {
      return;
    }
    var changed = false;
    setState(() {
      result.fold(
        (_) => _error = '썸네일 사진을 바꾸지 못했습니다.',
        (stages) {
          _stages = stages;
          changed = true;
        },
      );
      _busy = false;
    });
    if (changed) {
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = _stages.where((s) => s.stage != 'MASTER').toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '썸네일 사진을 골라도 썸네일은 바로 바뀌지 않습니다. '
            '판매상품 상세 「썸네일」 탭의 [저장 후 재생성]으로 반영됩니다.',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          if (_error.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(_error,
                  style: TextStyle(fontSize: 14, color: scheme.error)),
            ),
            const SizedBox(height: 8),
          ],
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '이 마스터의 판매상품이 없습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
                    _row(context, rows[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, ThumbnailPhotoStageView view) {
    final scheme = Theme.of(context).colorScheme;
    final isListing = view.stage == 'LISTING';
    return Padding(
      padding: EdgeInsets.fromLTRB(isListing ? 32 : 12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            thumbnailPhotoStageLabel(view),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isListing ? FontWeight.w400 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (view.imageUrl != null) ...[
                MasterNetworkImage(url: view.imageUrl, width: 40, height: 40),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kThumbnailPhotoSourceLabel[view.source] ?? view.source,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                    if (view.collageUsed)
                      const Text(
                        kThumbnailPhotoCollageNotice,
                        style: TextStyle(
                            fontSize: 11, color: AppColors.warningForeground),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _busy ? null : () => unawaited(_pick(view)),
                child: const Text('고르기'),
              ),
              if (view.source == 'OWN')
                OutlinedButton(
                  onPressed: _busy ? null : () => unawaited(_save(view, null)),
                  child: const Text('지우기(위 단계를 따름)'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
