import 'package:flutter_oklyn_mobile/core/utils/platform_display.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/thumbnail_photo.dart';

/// Screen labels of the thumbnail photo stages — port of web
/// `app/dashboard/master-products/components/thumbnailPhotoLabels.ts`
/// (FEATURE_2610_32 D14 · D27 · D30 · D32). Shared by the master 「이미지」 tab
/// block 「단계별 썸네일 사진」 and the listing 「썸네일」 tab.
/// **File**: lib/features/master_product/presentation/logic/thumbnail_photo_labels.dart

/// Status text per `ThumbnailPhotoStageView.source` (D14 · D32 — six texts).
const Map<String, String> kThumbnailPhotoSourceLabel = {
  'OWN': '따로 고름',
  'SELLER': '판매자 것을 따름',
  'MASTER': '마스터 썸네일 사진을 따름',
  'COVER': '대표사진을 따름',
  'LEGACY_UPLOAD': '옛 바탕사진을 따름',
  'FIRST_COMPONENT': '첫 구성품 사진을 따름',
};

/// Shown next to the status when a switched-on collage is used (D6 · D14).
const String kThumbnailPhotoCollageNotice = '콜라주가 쓰임 — 썸네일 사진은 콜라주를 끄면 쓰인다';

/// Name of one stage row (same wording as the web).
String thumbnailPhotoStageLabel(ThumbnailPhotoStageView view) {
  if (view.stage == 'MASTER') {
    return '마스터';
  }
  if (view.stage == 'SELLER') {
    return '판매자 · ${view.sellerName ?? ''}';
  }
  final platform =
      view.platform == null ? '' : platformDisplayName(view.platform!);
  return '판매상품 · ${view.sellerName ?? ''} · $platform #${view.listingId}';
}
