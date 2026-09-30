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

/// Thumbnail template — the master screens read only [isDefault] and [fields].
class ThumbnailTemplateSummary {
  final int id;
  final String name;
  final bool isDefault;
  final List<TemplateField> fields;

  const ThumbnailTemplateSummary({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.fields,
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

/// Web `CategoryMapping`.
class CategoryMapping {
  final String platform;
  final String platformCategoryId;
  final String? platformCategoryName;

  const CategoryMapping({
    required this.platform,
    required this.platformCategoryId,
    this.platformCategoryName,
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
