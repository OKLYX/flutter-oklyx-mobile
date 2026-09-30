import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/detail_content.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';

/// Server calls of the six master product screens — one method per web
/// repository method (FEATURE_2609_80 R3, M1~M23 · L1~L37 · S1~S19).
/// **File**: lib/features/master_product/domain/repositories/master_product_repository.dart
abstract class MasterProductRepository {
  /// M1
  Future<Either<Failure, MasterProductPage>> listMasters(
      {required int page,
      required int size,
      required String sort,
      String? search});

  /// M2
  Future<Either<Failure, MasterProduct>> getMaster(int id);

  /// M3
  Future<Either<Failure, List<MasterByComponents>>> findByComponents(
      List<int> productIds);

  /// M4
  Future<Either<Failure, List<MasterByAnyComponent>>> findByAnyComponent(
      List<int> productIds);

  /// M5
  Future<Either<Failure, MasterProduct>> createMaster(
      MasterProductRequest request);

  /// M6
  Future<Either<Failure, MasterProduct>> updateMaster(
      int id, MasterProductUpdateRequest request);

  /// M7
  Future<Either<Failure, MasterProduct>> updateComposition(
      int id, MasterCompositionRequest request);

  /// M8
  Future<Either<Failure, Unit>> deleteMaster(int id);

  /// M9
  Future<Either<Failure, MasterOption>> addOption(
      int id, MasterOptionRequest request);

  /// M10
  Future<Either<Failure, MasterOption>> updateOption(
      int id, int optionId, MasterOptionRequest request);

  /// M11
  Future<Either<Failure, Unit>> deleteOption(int id, int optionId);

  /// M12
  Future<Either<Failure, ListingMatrix>> getMatrix(int id);

  /// M13
  Future<Either<Failure, MasterChannelOptions>> getChannelOptions(int id);

  /// M14
  Future<Either<Failure, MasterCategory?>> getMasterCategory(int id);

  /// M15
  Future<Either<Failure, MasterCategory?>> setMasterCategory(
      int id, int categoryId);

  /// M16
  Future<Either<Failure, Unit>> clearMasterCategory(int id);

  /// M17
  Future<Either<Failure, CategoryMeta>> getCategoryMeta(
      int id, String platform);

  /// M18
  Future<Either<Failure, CategoryMetaSchema>> getCategorySchema(
      int categoryId, String platform);

  /// M19
  Future<Either<Failure, Unit>> setCategoryAttributes(
      int id, CategoryAttributesRequest request);

  /// M20
  Future<Either<Failure, MasterProduct>> updateMasterTags(
      int id, List<String> tags);

  /// M21
  Future<Either<Failure, Unit>> updateRegistrationNameSuffix(int id,
      {required bool? enabled, required String? suffix});

  /// M22
  Future<Either<Failure, MasterProduct>> updateMasterShippingOverride(
      int id, Map<String, String> override);

  /// M23
  Future<Either<Failure, ShippingForceApplyResult>>
      applyShippingOverrideToChannels(int id, List<int> listingIds);

  /// L1
  Future<Either<Failure, ChannelAddResult>> addChannel(int masterId,
      {required int sellerId, required String platform});

  /// L2
  Future<Either<Failure, BatchChannelAddResult>> addChannelsBatch(
      int masterId, List<ChannelTarget> targets);

  /// L3
  Future<Either<Failure, ListingRegisterResult>> registerListing(int listingId);

  /// L4
  Future<Either<Failure, ListingRegisterResult>> requestListingUpdate(
      int listingId);

  /// L5
  Future<Either<Failure, ListingStatusResult>> fetchListingStatus(
      int listingId);

  /// L6
  Future<Either<Failure, GeneratedProduct>> getGenerated(int listingId);

  /// L7
  Future<Either<Failure, GeneratedProduct>> regenerate(int listingId);

  /// L8
  Future<Either<Failure, GeneratedProduct>> overrideListingThumbnail(
      int listingId, File file);

  /// L9
  Future<Either<Failure, GeneratedProduct>> clearListingThumbnail(
      int listingId);

  /// L10
  Future<Either<Failure, GeneratedProduct>> updateListingFieldValues(
      int listingId, Map<String, String> fieldValues);

  /// L11
  Future<Either<Failure, Unit>> updateDisplayName(int listingId, String name);

  /// L12
  Future<Either<Failure, GeneratedProduct>> updateListingTags(
      int listingId, List<String> tags);

  /// L13
  Future<Either<Failure, GeneratedProduct>> updateListingShippingOverride(
      int listingId, Map<String, String> override);

  /// L14
  Future<Either<Failure, ShippingSettings>> getInheritedShipping(int listingId);

  /// L15
  Future<Either<Failure, PropagateResult>> propagate(int masterId);

  /// L16
  Future<Either<Failure, ChannelSyncPreview>> getChannelSyncPreview(
      int masterId);

  /// L17
  Future<Either<Failure, String>> previewDetail(int listingId,
      {int? templateId});

  /// L18
  Future<Either<Failure, GeneratedProduct>> overrideDetailHtml(
      int listingId, String html);

  /// L19
  Future<Either<Failure, GeneratedProduct>> clearDetailHtml(int listingId);

  /// L20
  Future<Either<Failure, DetailTemplate>> getResolvedDetailTemplate(
      int listingId);

  /// L21
  Future<Either<Failure, GeneratedProduct>> updateDetailTemplate(
      int listingId, int? templateId);

  /// L22
  Future<Either<Failure, ListingOptions>> getListingOptions(int listingId);

  /// L23
  Future<Either<Failure, ListingOptions>> setActiveOptions(
      int listingId, List<int> activeOptionIds);

  /// L24
  Future<Either<Failure, ListingOptions>> setOptionStocks(
      int listingId, List<OptionStockChange> stocks);

  /// L25
  Future<Either<Failure, ChannelPriceUpdateResult>> setOptionPrices(
      int listingId, List<OptionPriceChange> prices);

  /// L26
  Future<Either<Failure, ListingOptions>> setOptionNames(
      int listingId, List<OptionNameChange> names);

  /// L27
  Future<Either<Failure, ApplyOptionNamesResult>> applyMasterOptionNames(
      int masterId);

  /// L28
  Future<Either<Failure, ChannelApplyOptionNamesResult>>
      applyMasterOptionNamesToListing(int listingId);

  /// L29
  Future<Either<Failure, ImportPreview>> importPreview(int masterId,
      {required int sellerId,
      required String platform,
      required String platformProductId});

  /// L30
  Future<Either<Failure, ChannelAddResult>> importListing(int masterId,
      {required int sellerId,
      required String platform,
      required String platformProductId,
      required List<ImportOptionSpec> options});

  /// L31
  Future<Either<Failure, List<DetachedListing>>> findDetachedListings(
      int masterId,
      {required int sellerId,
      required String platform,
      String? keyword});

  /// L32
  Future<Either<Failure, List<MarketOption>>> getMarketOptions(int listingId);

  /// L33
  Future<Either<Failure, ListingStatusOption>> linkMarketOption(
      int listingId, int optionId, String vendorItemId);

  /// L34
  Future<Either<Failure, Unit>> unlinkChannel(int masterId, int listingId);

  /// L35
  Future<Either<Failure, Unit>> deleteDraftChannel(int masterId, int listingId);

  /// L36
  Future<Either<Failure, Unit>> setCategorySource(int listingId,
      {required bool useMasterCategory});

  /// L37
  Future<Either<Failure, MasterFromChannelPreview>> masterFromChannelPreview(
      {required int sellerId,
      required String platform,
      required String platformProductId});

  /// S1
  Future<Either<Failure, List<DetailTemplate>>> listDetailTemplates();

  /// S2
  Future<Either<Failure, MasterPoolImage>> uploadPoolImage(
      int masterId, File file);

  /// S3
  Future<Either<Failure, List<MasterPoolImage>>> listPoolImages(int masterId);

  /// S4
  Future<Either<Failure, Unit>> deletePoolImage(int masterId, int imageId);

  /// S5
  Future<Either<Failure, List<MasterPoolImage>>> setZoneImages(
      int masterId, String zoneId, List<int> imageIds);

  /// S6
  Future<Either<Failure, Unit>> setSourceImage(int masterId, int? imageId);

  /// S7
  Future<Either<Failure, List<MasterPoolImage>>> importProductImages(
      int masterId, List<int> productImageIds);

  /// S8
  Future<Either<Failure, List<ProductGalleryImage>>> listProductImages(
      int productId);

  /// S9
  Future<Either<Failure, List<StandardCategory>>> getStandardCategories();

  /// S10
  Future<Either<Failure, StandardCategory>> getStandardCategory(int id);

  /// S11
  Future<Either<Failure, List<CategoryTreeNode>>> browseCategoryTree(
      {int? parentId});

  /// S12
  Future<Either<Failure, List<CategoryMapping>>> getCategoryMappings(
      int categoryId);

  /// S13
  Future<Either<Failure, List<ThumbnailTemplateSummary>>>
      listThumbnailTemplates();

  /// S14
  Future<Either<Failure, List<DetailImageGroup>>> listDetailImageGroups();

  /// S15
  Future<Either<Failure, List<MasterBox>>> getPurchasedBoxes();

  /// S16
  Future<Either<Failure, List<OutboundPlace>>> listOutboundPlaces(
      int accountId);

  /// S17
  Future<Either<Failure, List<ReturnCenter>>> listReturnCenters(int accountId);

  /// S18
  Future<Either<Failure, ShippingSettings>> getShippingConfig(int accountId);

  /// S19
  Future<Either<Failure, ShippingSettings>> upsertShippingConfig(
      int accountId, ShippingSettings settings);
}
