// Surrounding domain types the master screens read — web entities (@09208a0).
// Sources: CategoryEntity.ts · ProductImage.ts · ThumbnailEntity.ts(TemplateField) ·
//       DetailImageGroupEntity.ts · CategoryMappingEntity.ts · ShippingEntity.ts · PackageEntity.ts

/// Web `Category` (one standard category).
class StandardCategory {
  final int id;
  final String name;
  final String platform;
  final String platformCategoryId;
  final int? parentId;

  const StandardCategory({
    required this.id,
    required this.name,
    required this.platform,
    required this.platformCategoryId,
    this.parentId,
  });
}

/// Web `CategoryTreeNode`.
class CategoryTreeNode {
  final int id;
  final String name;
  final bool leaf;

  const CategoryTreeNode(
      {required this.id, required this.name, required this.leaf});
}

/// Web `ProductImage` (one product gallery image). [imageUrl] is the stored
/// value — render it directly when it is an http URL.
class ProductGalleryImage {
  final int id;
  final int productId;
  final int sortOrder;
  final String imageUrl;

  const ProductGalleryImage({
    required this.id,
    required this.productId,
    required this.sortOrder,
    required this.imageUrl,
  });
}

/// Web `TemplateField`.
class TemplateField {
  final String key;
  final String label;
  final String defaultValue;

  const TemplateField({
    required this.key,
    required this.label,
    required this.defaultValue,
  });
}

/// Web `BUILTIN_FIELD_KEYS`.
const List<String> kBuiltinFieldKeys = ['brandName', 'productName'];

/// Thumbnail template — the master screens read [name], [isDefault], [fields]
/// and [imageGroupKey] (the zone id of this template's image group, built by
/// the server — never assembled on the client, FEATURE_2610_33 D9 · D15).
class ThumbnailTemplateSummary {
  final int id;
  final String name;
  final bool isDefault;
  final List<TemplateField> fields;
  final String imageGroupKey;

  const ThumbnailTemplateSummary({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.fields,
    required this.imageGroupKey,
  });
}

/// Web `DetailImageGroup`. ⚠️ [code] is never shown (the visible value is
/// [name]).
class DetailImageGroup {
  final int id;
  final String code;
  final String name;
  final int sortOrder;
  final int templateCount;
  final int imageCount;
  final List<String> usedByTemplateNames;

  const DetailImageGroup({
    required this.id,
    required this.code,
    required this.name,
    required this.sortOrder,
    required this.templateCount,
    required this.imageCount,
    required this.usedByTemplateNames,
  });
}

/// Web `CategoryMapping` — also web `MasterPlatformCategory` (the master's own
/// platform category, 「개별 지정」, FEATURE_2610_12 / D48): same fields.
class CategoryMapping {
  final String platform;
  final String platformCategoryId;
  final String? platformCategoryName;

  /// FEATURE_2610_34 / D20: new Coupang registrations of this category leave
  /// 총 수량 out.
  final bool grandTotalOmitted;

  const CategoryMapping({
    required this.platform,
    required this.platformCategoryId,
    this.platformCategoryName,
    this.grandTotalOmitted = false,
  });
}

/// The part of web `Package` the master screens read. Only purchased boxes are
/// queried (`boxKind=PURCHASED`).
class MasterBox {
  final int id;
  final String type;
  final num cost;
  final bool isDefault;

  const MasterBox({
    required this.id,
    required this.type,
    required this.cost,
    required this.isDefault,
  });
}

/// Web `OutboundPlace`.
class OutboundPlace {
  final String code;
  final String name;

  const OutboundPlace({required this.code, required this.name});
}

/// Web `ReturnCenter`.
class ReturnCenter {
  final String code;
  final String name;
  final String? chargeName;
  final String? contactNumber;
  final String? zipCode;
  final String? address;
  final String? addressDetail;
  final num? returnCharge;
  final num? deliveryChargeOnReturn;

  const ReturnCenter({
    required this.code,
    required this.name,
    this.chargeName,
    this.contactNumber,
    this.zipCode,
    this.address,
    this.addressDetail,
    this.returnCharge,
    this.deliveryChargeOnReturn,
  });
}

/// Web `ShippingConfig` (account shipping config / inherited baseline), also
/// used as `ShippingOverride` / `ShippingConfigRequest` — the three share the
/// same fields (per the web comment). [marketplaceAccountId] only appears in
/// GET responses.
class ShippingSettings {
  final int? marketplaceAccountId;
  final String? outboundShippingPlaceCode;
  final String? returnCenterCode;
  final String? returnChargeName;
  final String? returnContactNumber;
  final String? returnZipCode;
  final String? returnAddress;
  final String? returnAddressDetail;
  final num? returnCharge;
  final num? deliveryChargeOnReturn;
  final String? deliveryMethod;
  final String? deliveryCompanyCode;
  final String? deliveryChargeType;
  final num? deliveryCharge;
  final num? freeShipOverAmount;
  final String? remoteAreaDeliverable;
  final String? unionDeliveryType;
  final String? extraInfoMessage;

  const ShippingSettings({
    this.marketplaceAccountId,
    this.outboundShippingPlaceCode,
    this.returnCenterCode,
    this.returnChargeName,
    this.returnContactNumber,
    this.returnZipCode,
    this.returnAddress,
    this.returnAddressDetail,
    this.returnCharge,
    this.deliveryChargeOnReturn,
    this.deliveryMethod,
    this.deliveryCompanyCode,
    this.deliveryChargeType,
    this.deliveryCharge,
    this.freeShipOverAmount,
    this.remoteAreaDeliverable,
    this.unionDeliveryType,
    this.extraInfoMessage,
  });
}

/// One sales channel's platform and on/off state — the input of the D98 platform set (FEATURE_2610_13).
class AccountPlatform {
  final String platform;
  final bool isActive;

  const AccountPlatform({required this.platform, required this.isActive});
}

/// One 11st notice item of the preview (FEATURE_2610_13 / D97). [ownKey] is set only for an 11st-only item — the
/// notice-map key its value is stored under (`ELEVENST:{code}`, D101).
class ElevenstNoticeLine {
  final String code;
  final String name;
  final String value;
  final String? ownKey;

  const ElevenstNoticeLine({
    required this.code,
    required this.name,
    required this.value,
    this.ownKey,
  });
}

/// The 11st view of the master notice values (`POST /api/admin/elevenst/notice-preview`).
class ElevenstNotification {
  final String typeCode;
  final String typeName;
  final List<ElevenstNoticeLine> lines;

  /// The request's Coupang item keys that some 11st item reads (= the items both platforms share).
  final List<String> usedCoupangItems;

  const ElevenstNotification({
    required this.typeCode,
    required this.typeName,
    required this.lines,
    required this.usedCoupangItems,
  });
}

/// One pickable Gmarket · Auction (ESM) value (FEATURE_2610_26 / D37 · D68):
/// [code] is stored, [name] is shown. Web `EsmChoice`.
class EsmChoice {
  final String code;
  final String name;

  const EsmChoice({required this.code, required this.name});
}

/// One ESM notice item of the preview (FEATURE_2610_26 / D17 · D56). [ownKey]
/// is set only for an ESM-only item — the notice-map key its value is stored
/// under (`ESM:{code}`). Web `EsmNoticeLine`.
class EsmNoticeLine {
  final String code;
  final String name;
  final String value;
  final String? ownKey;

  const EsmNoticeLine({
    required this.code,
    required this.name,
    required this.value,
    this.ownKey,
  });
}

/// The Gmarket · Auction view of the master notice values
/// (`POST /api/admin/esm/notice-preview`). Web `EsmNotification`.
class EsmNotification {
  final String groupNo;
  final String groupName;
  final List<EsmNoticeLine> lines;

  /// The request's Coupang item keys that some ESM item reads (= the items
  /// both platforms share).
  final List<String> usedCoupangItems;

  const EsmNotification({
    required this.groupNo,
    required this.groupName,
    required this.lines,
    required this.usedCoupangItems,
  });
}
