// Channel registration / approval / option domain types — web
// `domain/entities/ListingRegistrationEntity.ts` (@09208a0).
// Status and source strings keep the web union values (ListingStatusCode,
// GeneratedSourceCode).

/// Web `ListingStatus`.
abstract final class ListingStatusCode {
  static const draft = 'DRAFT';
  static const submitted = 'SUBMITTED';
  static const selling = 'SELLING';
  static const rejected = 'REJECTED';
  static const suspended = 'SUSPENDED';
}

/// Web `GeneratedSource` · `priceSource` · `optionNameSource`.
abstract final class GeneratedSourceCode {
  static const auto = 'AUTO';
  static const manualOverride = 'MANUAL_OVERRIDE';
}

/// Web `OptionPrice`.
class OptionPrice {
  final int optionId;
  final String? optionName;
  final num sellingPrice;
  final bool? active;
  final bool? onMarket;
  final int? stockQuantity;
  final int maxStock;
  final String? priceSource;
  final String? optionNameSource;
  final bool? channelOnly;

  /// FEATURE_2610_26 / D50: on a Gmarket · Auction (ESM) listing [sellingPrice]
  /// is the Gmarket price and this is the Auction price; null on every other
  /// platform.
  final num? auctionSellingPrice;

  /// FEATURE_2610_26 / D53 ②: origin of [auctionSellingPrice]; null elsewhere.
  final String? auctionPriceSource;

  const OptionPrice({
    required this.optionId,
    required this.sellingPrice,
    required this.maxStock,
    this.optionName,
    this.active,
    this.onMarket,
    this.stockQuantity,
    this.priceSource,
    this.optionNameSource,
    this.channelOnly,
    this.auctionSellingPrice,
    this.auctionPriceSource,
  });
}

/// Web `GeneratedProductResponse`.
class GeneratedProduct {
  final int productListingId;
  final String? thumbnailUrl;
  final String? detailHtml;
  final String source;
  final String thumbnailSource;
  final Map<String, String> fieldValues;
  final List<String> tags;
  final List<OptionPrice> optionPrices;
  final Map<String, String>? shippingOverride;
  final bool? shippingReady;
  final int? detailTemplateId;
  // FEATURE_2610_13 / D120 · FEATURE_2610_26 / D65: 1 when this 11st or ESM
  // listing's re-price failed after a shipping save, else 0.
  final int priceRecalcFailedCount;

  const GeneratedProduct({
    required this.productListingId,
    required this.source,
    required this.thumbnailSource,
    required this.fieldValues,
    required this.tags,
    required this.optionPrices,
    this.thumbnailUrl,
    this.detailHtml,
    this.shippingOverride,
    this.shippingReady,
    this.detailTemplateId,
    this.priceRecalcFailedCount = 0,
  });
}

/// Web `ChannelAddResponse`.
class ChannelAddResult {
  final int productListingId;
  final String status;
  final GeneratedProduct generated;
  final String? categoryWarning;

  const ChannelAddResult({
    required this.productListingId,
    required this.status,
    required this.generated,
    this.categoryWarning,
  });
}

/// Web `BatchChannelAddRequest.targets[]`.
class ChannelTarget {
  final int sellerId;
  final String platform;

  const ChannelTarget({required this.sellerId, required this.platform});
}

/// Web `BatchChannelAddResult`.
class BatchChannelAddItem {
  final int sellerId;
  final String platform;
  final bool success;
  final int? productListingId;
  final String? errorMessage;

  const BatchChannelAddItem({
    required this.sellerId,
    required this.platform,
    required this.success,
    this.productListingId,
    this.errorMessage,
  });
}

/// Web `BatchChannelAddResponse`.
class BatchChannelAddResult {
  final int requested;
  final int succeeded;
  final int failed;
  final List<BatchChannelAddItem> results;

  const BatchChannelAddResult({
    required this.requested,
    required this.succeeded,
    required this.failed,
    required this.results,
  });
}

/// Web `ListingRegisterResponse`.
class ListingRegisterResult {
  final int productListingId;
  final String status;
  final String? platformProductId;

  const ListingRegisterResult({
    required this.productListingId,
    required this.status,
    this.platformProductId,
  });
}

/// Web `ListingStatusOption`. [approvalStatus] = 'APPROVED' | 'NOT_APPROVED'.
class ListingStatusOption {
  final int optionId;
  final String approvalStatus;
  final String? platformOptionId;

  const ListingStatusOption({
    required this.optionId,
    required this.approvalStatus,
    this.platformOptionId,
  });
}

/// Web `ListingStatusResponse`.
class ListingStatusResult {
  final int productListingId;
  final String status;
  final List<ListingStatusOption> options;
  final String? reviewNote;
  final String? reviewNoteState;

  const ListingStatusResult({
    required this.productListingId,
    required this.status,
    required this.options,
    this.reviewNote,
    this.reviewNoteState,
  });
}

/// Web `PropagateResponse`.
class PropagateResult {
  final int propagated;
  final int skipped;
  final int failed;

  const PropagateResult({
    required this.propagated,
    required this.skipped,
    required this.failed,
  });
}

/// Web `ChannelSyncTotals`.
class ChannelSyncTotals {
  final int affectedChannels;
  final int missingOptions;
  final int channelOnlyOptions;
  final int quantityMismatch;

  const ChannelSyncTotals({
    required this.affectedChannels,
    required this.missingOptions,
    required this.channelOnlyOptions,
    required this.quantityMismatch,
  });
}

/// Web `ChannelSyncChannel`.
class ChannelSyncChannel {
  final int listingId;
  final String sellerName;
  final String platform;
  final bool onMarket;
  final List<String> missingOptions;
  final List<String> channelOnlyOptions;
  final List<String> marketChannelOnlyOptions;
  final List<String> quantityMismatchOptions;

  const ChannelSyncChannel({
    required this.listingId,
    required this.sellerName,
    required this.platform,
    required this.onMarket,
    required this.missingOptions,
    required this.channelOnlyOptions,
    required this.marketChannelOnlyOptions,
    required this.quantityMismatchOptions,
  });
}

/// Web `ChannelSyncPreview`.
class ChannelSyncPreview {
  final bool inSync;
  final ChannelSyncTotals totals;
  final List<ChannelSyncChannel> channels;

  const ChannelSyncPreview({
    required this.inSync,
    required this.totals,
    required this.channels,
  });
}

/// Web `ListingOptionSummary`.
class ListingOptionSummary {
  final int optionId;
  final String optionName;
  final num sellingPrice;
  final bool active;
  final String approvalStatus;
  final int? stockQuantity;
  final int maxStock;
  final String? priceSource;
  final String? optionNameSource;
  final bool? channelOnly;
  final String? platformOptionId;
  final int? masterOptionId;

  /// FEATURE_2610_26 / D50: the Auction price of an ESM option ([sellingPrice]
  /// = Gmarket); null elsewhere.
  final num? auctionSellingPrice;

  /// FEATURE_2610_26 / D53 ②: origin of [auctionSellingPrice]; null elsewhere.
  final String? auctionPriceSource;

  const ListingOptionSummary({
    required this.optionId,
    required this.optionName,
    required this.sellingPrice,
    required this.active,
    required this.approvalStatus,
    required this.maxStock,
    this.stockQuantity,
    this.priceSource,
    this.optionNameSource,
    this.channelOnly,
    this.platformOptionId,
    this.masterOptionId,
    this.auctionSellingPrice,
    this.auctionPriceSource,
  });
}

/// Web `ListingOptionsResponse`.
class ListingOptions {
  final int productListingId;
  final String status;
  final List<ListingOptionSummary> options;
  final bool? needsResync;
  final String? registrationName;

  const ListingOptions({
    required this.productListingId,
    required this.status,
    required this.options,
    this.needsResync,
    this.registrationName,
  });
}

/// Web `MasterChannelOptionCell`.
class ChannelOptionCell {
  final int productListingId;
  final String? platformProductId;
  final String status;
  final List<ListingOptionSummary> options;

  const ChannelOptionCell({
    required this.productListingId,
    required this.status,
    required this.options,
    this.platformProductId,
  });
}

/// Web `MasterChannelOptionsResponse`.
class MasterChannelOptions {
  final int masterId;
  final List<ChannelOptionCell> cells;

  const MasterChannelOptions({required this.masterId, required this.cells});
}

/// Web `OptionStocksRequest.stocks[]` — [stockQuantity] null = back to
/// inherited (the key is still sent).
class OptionStockChange {
  final int optionId;
  final int? stockQuantity;

  const OptionStockChange({required this.optionId, this.stockQuantity});
}

/// Web `OptionPricesRequest.prices[]` — [sellingPrice] null = back to the
/// auto-calculated price (the key is still sent).
class OptionPriceChange {
  final int optionId;
  final num? sellingPrice;

  /// FEATURE_2610_26 / D53 ②: true on an ESM option — then
  /// [auctionSellingPrice] is sent too (null = back to the calculated Auction
  /// price); false leaves the key out.
  final bool esm;
  final num? auctionSellingPrice;

  const OptionPriceChange({
    required this.optionId,
    this.sellingPrice,
    this.esm = false,
    this.auctionSellingPrice,
  });
}

/// Web `OptionNamesRequest.names[]` — [optionName] null = back to the master
/// option name (the key is still sent).
class OptionNameChange {
  final int optionId;
  final String? optionName;

  const OptionNameChange({required this.optionId, this.optionName});
}

class ChannelPriceFailure {
  final String optionName;
  final String message;

  const ChannelPriceFailure({required this.optionName, required this.message});
}

/// Web `ChannelPriceUpdateResponse`.
class ChannelPriceUpdateResult {
  final ListingOptions listing;
  final int pushed;
  final List<String> skipped;
  final List<ChannelPriceFailure> failed;

  const ChannelPriceUpdateResult({
    required this.listing,
    required this.pushed,
    required this.skipped,
    required this.failed,
  });
}

class ImportPreviewComponent {
  final int productId;
  final String? brand;
  final String productName;

  const ImportPreviewComponent({
    required this.productId,
    required this.productName,
    this.brand,
  });
}

class ImportPreviewOption {
  final String itemName;
  final String? vendorItemId;
  final String? sellerProductItemId;
  final num salePrice;
  final int? stockQuantity;

  const ImportPreviewOption({
    required this.itemName,
    required this.salePrice,
    this.vendorItemId,
    this.sellerProductItemId,
    this.stockQuantity,
  });
}

/// Web `ImportPreviewResponse`.
class ImportPreview {
  final String productName;
  final String status;
  final String categoryCode;
  final bool categoryMatched;
  final String? categoryWarning;
  final List<String> channelTags;
  final bool reusesExistingListing;
  final List<ImportPreviewComponent> components;
  final List<ImportPreviewOption> options;

  const ImportPreview({
    required this.productName,
    required this.status,
    required this.categoryCode,
    required this.categoryMatched,
    required this.channelTags,
    required this.reusesExistingListing,
    required this.components,
    required this.options,
    this.categoryWarning,
  });
}

/// Web `ImportOptionSpec` (request). The [vendorItemId] key is sent even when
/// null.
class ImportOptionSpec {
  final String? vendorItemId;
  final String itemName;
  final String masterOptionName;
  final List<MasterItemQuantity> components;

  const ImportOptionSpec({
    required this.itemName,
    required this.masterOptionName,
    required this.components,
    this.vendorItemId,
  });
}

/// A `{productId, quantity}` pair — component quantity in an import request.
class MasterItemQuantity {
  final int productId;
  final int quantity;

  const MasterItemQuantity({required this.productId, required this.quantity});
}

/// Web `DetachedListing`.
class DetachedListing {
  final int productListingId;
  final String platformProductId;
  final String name;
  final String status;

  const DetachedListing({
    required this.productListingId,
    required this.platformProductId,
    required this.name,
    required this.status,
  });
}

/// Web `MarketOption`.
class MarketOption {
  final String? itemName;
  final String? vendorItemId;
  final String? sellerProductItemId;
  final num? salePrice;
  final int? linkedOptionId;
  final String? linkedOptionName;

  const MarketOption({
    this.itemName,
    this.vendorItemId,
    this.sellerProductItemId,
    this.salePrice,
    this.linkedOptionId,
    this.linkedOptionName,
  });
}

/// Web `ApplyOptionNamesResponse`.
class ApplyOptionNamesResult {
  final int updatedCells;
  final int updatedOptions;
  final List<String> warnings;

  const ApplyOptionNamesResult({
    required this.updatedCells,
    required this.updatedOptions,
    required this.warnings,
  });
}

/// Web `ChannelApplyOptionNamesResponse`.
class ChannelApplyOptionNamesResult {
  final int updatedOptions;
  final List<String> skippedAwaitingId;

  const ChannelApplyOptionNamesResult({
    required this.updatedOptions,
    required this.skippedAwaitingId,
  });
}

/// Web `MasterFromChannelOption`.
class MasterFromChannelOption {
  final String itemName;
  final String? platformOptionId;
  final String? sellerProductItemId;
  final num salePrice;
  final int? stockQuantity;
  final Map<String, String> attributes;

  const MasterFromChannelOption({
    required this.itemName,
    required this.salePrice,
    required this.attributes,
    this.platformOptionId,
    this.sellerProductItemId,
    this.stockQuantity,
  });
}

/// Web `MasterFromChannelPreview`.
class MasterFromChannelPreview {
  final String? productName;
  final String? suggestedMasterName;
  final String status;
  final String? categoryCode;
  final int? suggestedCategoryId;
  final String? suggestedCategoryName;
  final bool categoryResolved;
  final List<MasterFromChannelOption> options;
  final Map<String, String> commonAttributes;
  final Map<String, String> notices;
  final String? noticeGroup;
  final bool reusesExistingListing;

  const MasterFromChannelPreview({
    required this.status,
    required this.categoryResolved,
    required this.options,
    required this.commonAttributes,
    required this.notices,
    required this.reusesExistingListing,
    this.productName,
    this.suggestedMasterName,
    this.categoryCode,
    this.suggestedCategoryId,
    this.suggestedCategoryName,
    this.noticeGroup,
  });
}

/// Web `SiteMargin` — the margin of one price on one site (FEATURE_2610_27 /
/// D2 · D5 · D11 · D12 · FEATURE_2610_28 / D7 · D12 · D13 · D21 · D22). Every
/// amount is null and [components] is empty when the margin cannot be
/// calculated; [reason] then says why.
class SiteMargin {
  /// 'COUPANG' · 'ELEVENST' · 'GMARKET' · 'AUCTION' (FEATURE_2610_28 / D21).
  final String site;

  /// KST wall clock 'yyyy-MM-ddTHH:mm:ss…' (D32); null = never confirmed, and
  /// always null on a preview.
  final String? marketPriceAt;

  /// The price live on the market; null = unknown.
  final num? marketPrice;
  final num? systemPrice;

  /// marketPrice ?? systemPrice (D2); for a preview = the price typed in.
  final num? judgedPrice;

  /// true = no market price, the system price was judged (D2).
  final bool marketPriceMissing;
  final num? costSum;

  /// FEATURE_2610_28 / D7 · D14 · D15: the components behind [costSum], in BOM
  /// order.
  final List<CostComponent> components;
  final num? delivery;
  final num? box;

  /// FEATURE_2610_28 / D12: the sale commission rate with VAT (0.119 = 11.9%).
  final num? commissionRate;

  /// FEATURE_2610_28 / D12: the sale commission in won.
  final num? commissionAmount;

  /// FEATURE_2610_28 / D12: the 11st · ESM delivery-fee commission in won; 0
  /// on every other site.
  final num? shippingFeeCommission;

  /// [commissionAmount] + [shippingFeeCommission].
  final num? feeAmount;
  final num? marginAmount;

  /// 0.1234 = 12.34%.
  final num? marginRate;
  final num? breakEvenPrice;

  /// FEATURE_2610_28 / D13: the margin preset's minimum amount; null = unset.
  final num? minMarginAmount;

  /// FEATURE_2610_28 / D13: the margin preset's minimum rate; null = unset.
  final num? minMarginRate;

  /// Under the margin preset's minimum amount or rate (D5).
  final bool below;
  final String? reason;

  const SiteMargin({
    required this.site,
    required this.marketPriceMissing,
    required this.components,
    required this.below,
    this.marketPriceAt,
    this.marketPrice,
    this.systemPrice,
    this.judgedPrice,
    this.costSum,
    this.delivery,
    this.box,
    this.commissionRate,
    this.commissionAmount,
    this.shippingFeeCommission,
    this.feeAmount,
    this.marginAmount,
    this.marginRate,
    this.breakEvenPrice,
    this.minMarginAmount,
    this.minMarginRate,
    this.reason,
  });
}

/// Web `CostComponent` — one component of [SiteMargin.costSum]
/// (FEATURE_2610_28 / D7 · D14); [unitPrice] · [amount] null = 「단가 없음」.
class CostComponent {
  final String productName;
  final int quantity;
  final num? unitPrice;
  final num? amount;

  const CostComponent({
    required this.productName,
    required this.quantity,
    this.unitPrice,
    this.amount,
  });
}

/// Web `OptionMargin` — one option of `GET …/margins` (FEATURE_2610_27 / D3 ·
/// FEATURE_2610_28 / D20).
class OptionMargin {
  final int optionId;
  final String optionName;

  /// One per site — Gmarket then Auction on an ESM option (FEATURE_2610_28 /
  /// D20 · D21).
  final List<SiteMargin> sites;

  const OptionMargin({
    required this.optionId,
    required this.optionName,
    required this.sites,
  });
}

/// Web `ListingMarginResponse`.
class ListingMargins {
  final int listingId;
  final String platform;
  final List<OptionMargin> options;

  const ListingMargins({
    required this.listingId,
    required this.platform,
    required this.options,
  });
}
