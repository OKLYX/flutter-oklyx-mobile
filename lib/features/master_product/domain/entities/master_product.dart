// Master product domain types — fields of web
// `domain/entities/MasterProductEntity.ts` (@09208a0).
// Only `data/models/master_json.dart` knows JSON (this file does not).

class MasterComponent {
  final int productId;
  final String productName;
  final String? netContent;
  final String? netContentUnit;

  const MasterComponent({
    required this.productId,
    required this.productName,
    this.netContent,
    this.netContentUnit,
  });
}

class MasterOptionItem {
  final int productId;
  final String productName;
  final int quantity;

  const MasterOptionItem({
    required this.productId,
    required this.productName,
    required this.quantity,
  });
}

/// Web `MasterOptionResponse`.
class MasterOption {
  final int id;
  final String name;
  final List<MasterOptionItem> items;
  final int? deliveryId;
  final int? packageId;
  final Map<String, String>? categoryAttributes;
  final Map<String, String>? categoryNotices;
  final bool? marketRegistered;
  final int? stockQuantity;
  final int? clampedChannels;

  const MasterOption({
    required this.id,
    required this.name,
    required this.items,
    this.deliveryId,
    this.packageId,
    this.categoryAttributes,
    this.categoryNotices,
    this.marketRegistered,
    this.stockQuantity,
    this.clampedChannels,
  });
}

/// Web `MasterProductResponse`.
class MasterProduct {
  final int id;
  final String name;
  final String? sourceImageUrl;
  final Map<String, String> fieldValues;
  final int? defaultDeliveryId;
  final int? defaultPackageId;
  final List<MasterComponent> components;
  final List<MasterOption> options;
  final List<String> tags;
  final String? registrationName;
  final bool? optionCheckSuffixEnabled;
  final String? optionCheckSuffix;
  final Map<String, String>? shippingOverride;

  const MasterProduct({
    required this.id,
    required this.name,
    required this.fieldValues,
    required this.components,
    required this.options,
    required this.tags,
    this.sourceImageUrl,
    this.defaultDeliveryId,
    this.defaultPackageId,
    this.registrationName,
    this.optionCheckSuffixEnabled,
    this.optionCheckSuffix,
    this.shippingOverride,
  });
}

/// Web `MasterProductPageResponse`.
class MasterProductPage {
  final List<MasterProduct> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;

  const MasterProductPage({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
  });
}

/// Web `MasterProductByComponents`.
class MasterByComponents {
  final int id;
  final String name;
  final int optionCount;

  const MasterByComponents({
    required this.id,
    required this.name,
    required this.optionCount,
  });
}

class MasterComponentRef {
  final int productId;
  final String productName;

  const MasterComponentRef(
      {required this.productId, required this.productName});
}

/// Web `MasterProductByAnyComponent`.
class MasterByAnyComponent {
  final int id;
  final String name;
  final List<MasterComponentRef> components;

  const MasterByAnyComponent({
    required this.id,
    required this.name,
    required this.components,
  });
}

/// Web `MasterCategoryResponse`. The repository returns `null` when unset.
class MasterCategory {
  final int categoryId;
  final String categoryName;

  const MasterCategory({required this.categoryId, required this.categoryName});
}

/// Web `CategoryAttribute`. [inputType] = 'TEXT' | 'SELECT' | 'NUMBER'.
class CategoryAttribute {
  final String name;
  final bool required;
  final String inputType;
  final List<String> options;
  final String? basicUnit;

  const CategoryAttribute({
    required this.name,
    required this.required,
    required this.inputType,
    required this.options,
    this.basicUnit,
  });
}

/// Web `CategoryNotice`.
class CategoryNotice {
  final String key;
  final String label;
  final bool required;
  final String? groupName;

  const CategoryNotice({
    required this.key,
    required this.label,
    required this.required,
    this.groupName,
  });
}

/// Web `CategoryMetaValues`.
class CategoryMetaValues {
  final Map<String, String> attributes;
  final Map<String, String> notices;
  final String? noticeGroup;

  const CategoryMetaValues({
    required this.attributes,
    required this.notices,
    this.noticeGroup,
  });
}

/// Web `CategoryMetaResponse`.
class CategoryMeta {
  final List<CategoryAttribute> attributes;
  final List<CategoryNotice> notices;
  final CategoryMetaValues values;

  const CategoryMeta({
    required this.attributes,
    required this.notices,
    required this.values,
  });
}

/// Web `CategoryMetaSchemaResponse`.
class CategoryMetaSchema {
  final List<CategoryAttribute> attributes;
  final List<CategoryNotice> notices;

  const CategoryMetaSchema({required this.attributes, required this.notices});
}

/// Web `MatrixCell`.
class MatrixCell {
  final int productListingId;
  final String name;
  final String registrationName;
  final String? platformProductId;
  final num? sellingPrice;
  final String? status;
  final String? categoryCode;
  final String? categoryName;
  final bool? usesOwnCategory;
  final bool? needsMarketSync;

  const MatrixCell({
    required this.productListingId,
    required this.name,
    required this.registrationName,
    this.platformProductId,
    this.sellingPrice,
    this.status,
    this.categoryCode,
    this.categoryName,
    this.usesOwnCategory,
    this.needsMarketSync,
  });
}

/// Web `MatrixRow`.
class MatrixRow {
  final int sellerId;
  final String sellerName;
  final String platform;
  final int accountId;
  final String accountLabel;
  final bool registered;
  final MatrixCell? cell;
  final List<MatrixCell>? cells;

  const MatrixRow({
    required this.sellerId,
    required this.sellerName,
    required this.platform,
    required this.accountId,
    required this.accountLabel,
    required this.registered,
    this.cell,
    this.cells,
  });
}

/// Web `ListingMatrixResponse`.
class ListingMatrix {
  final int masterId;
  final String masterName;
  final List<MatrixRow> rows;
  final String? masterCategoryName;

  const ListingMatrix({
    required this.masterId,
    required this.masterName,
    required this.rows,
    this.masterCategoryName,
  });
}

/// Web `ShippingForceApplyResponse`.
class ShippingForceApplyResult {
  final int affectedChannels;

  const ShippingForceApplyResult({required this.affectedChannels});
}

// ── Requests ─────────────────────────────────────────────────────────────
// A web `?` field (undefined = key omitted) is `null` in Dart = key omitted
// when serialized.

class MasterOptionRequestItem {
  final int productId;
  final int quantity;

  const MasterOptionRequestItem(
      {required this.productId, required this.quantity});
}

/// Web `MasterOptionRequest`. ⚠️ Omitting [stockQuantity] clears it to unset
/// (same as the web).
class MasterOptionRequest {
  final String name;
  final List<MasterOptionRequestItem> items;
  final int? deliveryId;
  final int? packageId;
  final Map<String, String>? categoryAttributes;
  final Map<String, String>? categoryNotices;
  final int? stockQuantity;

  const MasterOptionRequest({
    required this.name,
    required this.items,
    this.deliveryId,
    this.packageId,
    this.categoryAttributes,
    this.categoryNotices,
    this.stockQuantity,
  });
}

/// Web `MasterProductRequest`.
class MasterProductRequest {
  final String name;
  final List<int> componentProductIds;
  final Map<String, String>? fieldValues;
  final int? defaultDeliveryId;
  final int? defaultPackageId;
  final List<MasterOptionRequest>? options;

  const MasterProductRequest({
    required this.name,
    required this.componentProductIds,
    this.fieldValues,
    this.defaultDeliveryId,
    this.defaultPackageId,
    this.options,
  });
}

/// Web `MasterProductUpdateRequest`.
class MasterProductUpdateRequest {
  final String? name;
  final Map<String, String>? fieldValues;
  final List<int>? componentProductIds;
  final int? defaultDeliveryId;
  final int? defaultPackageId;

  const MasterProductUpdateRequest({
    this.name,
    this.fieldValues,
    this.componentProductIds,
    this.defaultDeliveryId,
    this.defaultPackageId,
  });
}

/// Web `MasterCompositionOptionSpec`.
class MasterCompositionOptionSpec {
  final int? optionId;
  final String name;
  final List<MasterOptionRequestItem> items;

  const MasterCompositionOptionSpec({
    required this.name,
    required this.items,
    this.optionId,
  });
}

/// Web `MasterCompositionRequest`.
class MasterCompositionRequest {
  final List<int> componentProductIds;
  final List<MasterCompositionOptionSpec> options;

  const MasterCompositionRequest({
    required this.componentProductIds,
    required this.options,
  });
}

/// Web `CategoryAttributesRequest`. The [noticeGroup] key is sent even when
/// null (web `?? null`).
class CategoryAttributesRequest {
  final Map<String, String> attributes;
  final Map<String, String> notices;
  final String? noticeGroup;

  const CategoryAttributesRequest({
    required this.attributes,
    required this.notices,
    this.noticeGroup,
  });
}
