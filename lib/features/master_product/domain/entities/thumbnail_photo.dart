// Thumbnail photo stage types — web `domain/entities/ThumbnailPhotoEntity.ts`
// (FEATURE_2610_32 D29 · D31).

/// Field key of the 「썸네일 사진」 card in `MasterImagePool` (D30 (가)).
/// Screen-only: the card reads and writes the MASTER stage through the
/// thumbnail-photo API — never send this key to the zone-mapping API.
const String kThumbnailPhotoField = '__thumbnail_photo__';

/// One stage row of `GET …/thumbnail-photo` (D31).
///
/// [stage] = 'MASTER' | 'SELLER' | 'LISTING'. [source] = 'OWN' | 'SELLER' |
/// 'MASTER' | 'COVER' | 'LEGACY_UPLOAD' | 'FIRST_COMPONENT' (D14 · D32).
/// [imageId] = the chosen pool image (OWN · SELLER · MASTER) or the cover pool
/// image (COVER), otherwise null; [imageUrl] is its complete URL.
/// [collageUsed] = a switched-on collage is used for this stage, so the photo
/// applies only once the collage is switched off (D6).
class ThumbnailPhotoStageView {
  final String stage;
  final int? sellerId;
  final String? sellerName;
  final int? listingId;
  final String? platform;
  final String source;
  final int? imageId;
  final String? imageUrl;
  final bool collageUsed;

  const ThumbnailPhotoStageView({
    required this.stage,
    required this.source,
    required this.collageUsed,
    this.sellerId,
    this.sellerName,
    this.listingId,
    this.platform,
    this.imageId,
    this.imageUrl,
  });
}
