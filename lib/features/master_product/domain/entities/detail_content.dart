// Detail-page block and master image pool domain types — web
// `domain/entities/DetailTemplateEntity.ts` (@09208a0).

/// Reserved cover-photo key. Same value as the web/backend `SOURCE_ZONE`.
const String kSourceZone = '__source__';

/// Web `DetailBlock`. [type] = 'text' | 'imageZone' | 'asset' | 'spacer'.
class DetailBlock {
  final String type;
  final String? bind;
  final String? src;
  final String? defaultValue;
  final int? widthPercent;
  final String? align;
  final int? heightPx;
  final Map<String, String>? textStyle;
  final int? processingPresetId;

  const DetailBlock({
    required this.type,
    this.bind,
    this.src,
    this.defaultValue,
    this.widthPercent,
    this.align,
    this.heightPx,
    this.textStyle,
    this.processingPresetId,
  });
}

/// Web `DetailTemplateResponse`.
class DetailTemplate {
  final int id;
  final String name;
  final List<DetailBlock> blocks;
  final bool active;
  final bool isDefault;
  final int? blockCount;
  final int? imageProcessingPresetId;

  const DetailTemplate({
    required this.id,
    required this.name,
    required this.blocks,
    required this.active,
    required this.isDefault,
    this.blockCount,
    this.imageProcessingPresetId,
  });
}

/// Web `MasterPoolImage`. [imageUrl] is a complete URL (render it directly
/// with `MasterNetworkImage`).
class MasterPoolImage {
  final int id;
  final String imageUrl;
  final int sortOrder;
  final List<String> assignedZones;
  final bool isSource;
  final int? productImageId;

  const MasterPoolImage({
    required this.id,
    required this.imageUrl,
    required this.sortOrder,
    required this.assignedZones,
    required this.isSource,
    this.productImageId,
  });
}
