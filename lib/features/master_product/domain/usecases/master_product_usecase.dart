import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/detail_content.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/repositories/master_product_repository.dart';

/// The only gateway the six master product screens use to call the server (thin delegation) — FEATURE_2609_80.
class MasterProductUseCase {
  final MasterProductRepository repository;

  MasterProductUseCase({required this.repository});

  /// M1
  Future<Either<Failure, MasterProductPage>> listMasters(
          {required int page,
          required int size,
          required String sort,
          String? search}) =>
      repository.listMasters(
          page: page, size: size, sort: sort, search: search);

  /// M2
  Future<Either<Failure, MasterProduct>> getMaster(int id) =>
      repository.getMaster(id);

  /// M3
  Future<Either<Failure, List<MasterByComponents>>> findByComponents(
          List<int> productIds) =>
      repository.findByComponents(productIds);

  /// M4
  Future<Either<Failure, List<MasterByAnyComponent>>> findByAnyComponent(
          List<int> productIds) =>
      repository.findByAnyComponent(productIds);

  /// M5
  Future<Either<Failure, MasterProduct>> createMaster(
          MasterProductRequest request) =>
      repository.createMaster(request);

  /// M6
  Future<Either<Failure, MasterProduct>> updateMaster(
          int id, MasterProductUpdateRequest request) =>
      repository.updateMaster(id, request);

  /// M7
  Future<Either<Failure, MasterProduct>> updateComposition(
          int id, MasterCompositionRequest request) =>
      repository.updateComposition(id, request);

  /// M8
  Future<Either<Failure, Unit>> deleteMaster(int id) =>
      repository.deleteMaster(id);

  /// M9
  Future<Either<Failure, MasterOption>> addOption(
          int id, MasterOptionRequest request) =>
      repository.addOption(id, request);

  /// M10
  Future<Either<Failure, MasterOption>> updateOption(
          int id, int optionId, MasterOptionRequest request) =>
      repository.updateOption(id, optionId, request);

  /// M11
  Future<Either<Failure, Unit>> deleteOption(int id, int optionId) =>
      repository.deleteOption(id, optionId);

  /// M12
  Future<Either<Failure, ListingMatrix>> getMatrix(int id) =>
      repository.getMatrix(id);

  /// M13
  Future<Either<Failure, MasterChannelOptions>> getChannelOptions(int id) =>
      repository.getChannelOptions(id);

  /// M14
  Future<Either<Failure, MasterCategory?>> getMasterCategory(int id) =>
      repository.getMasterCategory(id);

  /// M15
  Future<Either<Failure, MasterCategory?>> setMasterCategory(
          int id, int categoryId) =>
      repository.setMasterCategory(id, categoryId);

  /// M16
  Future<Either<Failure, Unit>> clearMasterCategory(int id) =>
      repository.clearMasterCategory(id);

  /// M17
  Future<Either<Failure, CategoryMeta>> getCategoryMeta(
          int id, String platform) =>
      repository.getCategoryMeta(id, platform);

  /// M18
  Future<Either<Failure, CategoryMetaSchema>> getCategorySchema(
          int categoryId, String platform) =>
      repository.getCategorySchema(categoryId, platform);

  /// M19
  Future<Either<Failure, Unit>> setCategoryAttributes(
          int id, CategoryAttributesRequest request) =>
      repository.setCategoryAttributes(id, request);

  /// M20
  Future<Either<Failure, MasterProduct>> updateMasterTags(
          int id, List<String> tags) =>
      repository.updateMasterTags(id, tags);

  /// M21
  Future<Either<Failure, Unit>> updateRegistrationNameSuffix(int id,
          {required bool? enabled, required String? suffix}) =>
      repository.updateRegistrationNameSuffix(id,
          enabled: enabled, suffix: suffix);

  /// M22
  Future<Either<Failure, MasterProduct>> updateMasterShippingOverride(
          int id, Map<String, String> override) =>
      repository.updateMasterShippingOverride(id, override);

  /// M23
  Future<Either<Failure, ShippingForceApplyResult>>
      applyShippingOverrideToChannels(int id, List<int> listingIds) =>
          repository.applyShippingOverrideToChannels(id, listingIds);

  /// L1
  Future<Either<Failure, ChannelAddResult>> addChannel(int masterId,
          {required int sellerId, required String platform}) =>
      repository.addChannel(masterId, sellerId: sellerId, platform: platform);

  /// L2
  Future<Either<Failure, BatchChannelAddResult>> addChannelsBatch(
          int masterId, List<ChannelTarget> targets) =>
      repository.addChannelsBatch(masterId, targets);

  /// L3
  Future<Either<Failure, ListingRegisterResult>> registerListing(
          int listingId) =>
      repository.registerListing(listingId);

  /// L4
  Future<Either<Failure, ListingRegisterResult>> requestListingUpdate(
          int listingId) =>
      repository.requestListingUpdate(listingId);

  /// L5
  Future<Either<Failure, ListingStatusResult>> fetchListingStatus(
          int listingId) =>
      repository.fetchListingStatus(listingId);

  /// L6
  Future<Either<Failure, GeneratedProduct>> getGenerated(int listingId) =>
      repository.getGenerated(listingId);

  /// L7
  Future<Either<Failure, GeneratedProduct>> regenerate(int listingId) =>
      repository.regenerate(listingId);

  /// L8
  Future<Either<Failure, GeneratedProduct>> overrideListingThumbnail(
          int listingId, File file) =>
      repository.overrideListingThumbnail(listingId, file);

  /// L9
  Future<Either<Failure, GeneratedProduct>> clearListingThumbnail(
          int listingId) =>
      repository.clearListingThumbnail(listingId);

  /// L10
  Future<Either<Failure, GeneratedProduct>> updateListingFieldValues(
          int listingId, Map<String, String> fieldValues) =>
      repository.updateListingFieldValues(listingId, fieldValues);

  /// L11
  Future<Either<Failure, Unit>> updateDisplayName(int listingId, String name) =>
      repository.updateDisplayName(listingId, name);

  /// L12
  Future<Either<Failure, GeneratedProduct>> updateListingTags(
          int listingId, List<String> tags) =>
      repository.updateListingTags(listingId, tags);

  /// L13
  Future<Either<Failure, GeneratedProduct>> updateListingShippingOverride(
          int listingId, Map<String, String> override) =>
      repository.updateListingShippingOverride(listingId, override);

  /// L14
  Future<Either<Failure, ShippingSettings>> getInheritedShipping(
          int listingId) =>
      repository.getInheritedShipping(listingId);

  /// L15
  Future<Either<Failure, PropagateResult>> propagate(int masterId) =>
      repository.propagate(masterId);

  /// L16
  Future<Either<Failure, ChannelSyncPreview>> getChannelSyncPreview(
          int masterId) =>
      repository.getChannelSyncPreview(masterId);

  /// L17
  Future<Either<Failure, String>> previewDetail(int listingId,
          {int? templateId}) =>
      repository.previewDetail(listingId, templateId: templateId);

  /// L18
  Future<Either<Failure, GeneratedProduct>> overrideDetailHtml(
          int listingId, String html) =>
      repository.overrideDetailHtml(listingId, html);

  /// L19
  Future<Either<Failure, GeneratedProduct>> clearDetailHtml(int listingId) =>
      repository.clearDetailHtml(listingId);

  /// L20
  Future<Either<Failure, DetailTemplate>> getResolvedDetailTemplate(
          int listingId) =>
      repository.getResolvedDetailTemplate(listingId);

  /// L21
  Future<Either<Failure, GeneratedProduct>> updateDetailTemplate(
          int listingId, int? templateId) =>
      repository.updateDetailTemplate(listingId, templateId);

  /// L22
  Future<Either<Failure, ListingOptions>> getListingOptions(int listingId) =>
      repository.getListingOptions(listingId);

  /// L23
  Future<Either<Failure, ListingOptions>> setActiveOptions(
          int listingId, List<int> activeOptionIds) =>
      repository.setActiveOptions(listingId, activeOptionIds);

  /// L24
  Future<Either<Failure, ListingOptions>> setOptionStocks(
          int listingId, List<OptionStockChange> stocks) =>
      repository.setOptionStocks(listingId, stocks);

  /// L25
  Future<Either<Failure, ChannelPriceUpdateResult>> setOptionPrices(
          int listingId, List<OptionPriceChange> prices) =>
      repository.setOptionPrices(listingId, prices);

  /// L26
  Future<Either<Failure, ListingOptions>> setOptionNames(
          int listingId, List<OptionNameChange> names) =>
      repository.setOptionNames(listingId, names);

  /// L27
  Future<Either<Failure, ApplyOptionNamesResult>> applyMasterOptionNames(
          int masterId) =>
      repository.applyMasterOptionNames(masterId);

  /// L28
  Future<Either<Failure, ChannelApplyOptionNamesResult>>
      applyMasterOptionNamesToListing(int listingId) =>
          repository.applyMasterOptionNamesToListing(listingId);

  /// L29
  Future<Either<Failure, ImportPreview>> importPreview(int masterId,
          {required int sellerId,
          required String platform,
          required String platformProductId}) =>
      repository.importPreview(masterId,
          sellerId: sellerId,
          platform: platform,
          platformProductId: platformProductId);

  /// L30
  Future<Either<Failure, ChannelAddResult>> importListing(int masterId,
          {required int sellerId,
          required String platform,
          required String platformProductId,
          required List<ImportOptionSpec> options}) =>
      repository.importListing(masterId,
          sellerId: sellerId,
          platform: platform,
          platformProductId: platformProductId,
          options: options);

  /// L31
  Future<Either<Failure, List<DetachedListing>>> findDetachedListings(
          int masterId,
          {required int sellerId,
          required String platform,
          String? keyword}) =>
      repository.findDetachedListings(masterId,
          sellerId: sellerId, platform: platform, keyword: keyword);

  /// L32
  Future<Either<Failure, List<MarketOption>>> getMarketOptions(int listingId) =>
      repository.getMarketOptions(listingId);

  /// L33
  Future<Either<Failure, ListingStatusOption>> linkMarketOption(
          int listingId, int optionId, String vendorItemId) =>
      repository.linkMarketOption(listingId, optionId, vendorItemId);

  /// L34
  Future<Either<Failure, Unit>> unlinkChannel(int masterId, int listingId) =>
      repository.unlinkChannel(masterId, listingId);

  /// L35
  Future<Either<Failure, Unit>> deleteDraftChannel(
          int masterId, int listingId) =>
      repository.deleteDraftChannel(masterId, listingId);

  /// L36
  Future<Either<Failure, Unit>> setCategorySource(int listingId,
          {required bool useMasterCategory}) =>
      repository.setCategorySource(listingId,
          useMasterCategory: useMasterCategory);

  /// L37
  Future<Either<Failure, MasterFromChannelPreview>> masterFromChannelPreview(
          {required int sellerId,
          required String platform,
          required String platformProductId}) =>
      repository.masterFromChannelPreview(
          sellerId: sellerId,
          platform: platform,
          platformProductId: platformProductId);

  /// S1
  Future<Either<Failure, List<DetailTemplate>>> listDetailTemplates() =>
      repository.listDetailTemplates();

  /// S2
  Future<Either<Failure, MasterPoolImage>> uploadPoolImage(
          int masterId, File file) =>
      repository.uploadPoolImage(masterId, file);

  /// S3
  Future<Either<Failure, List<MasterPoolImage>>> listPoolImages(int masterId) =>
      repository.listPoolImages(masterId);

  /// S4
  Future<Either<Failure, Unit>> deletePoolImage(int masterId, int imageId) =>
      repository.deletePoolImage(masterId, imageId);

  /// S5
  Future<Either<Failure, List<MasterPoolImage>>> setZoneImages(
          int masterId, String zoneId, List<int> imageIds) =>
      repository.setZoneImages(masterId, zoneId, imageIds);

  /// S6
  Future<Either<Failure, Unit>> setSourceImage(int masterId, int? imageId) =>
      repository.setSourceImage(masterId, imageId);

  /// S7
  Future<Either<Failure, List<MasterPoolImage>>> importProductImages(
          int masterId, List<int> productImageIds) =>
      repository.importProductImages(masterId, productImageIds);

  /// S8
  Future<Either<Failure, List<ProductGalleryImage>>> listProductImages(
          int productId) =>
      repository.listProductImages(productId);

  /// S9
  Future<Either<Failure, List<StandardCategory>>> getStandardCategories() =>
      repository.getStandardCategories();

  /// S10
  Future<Either<Failure, StandardCategory>> getStandardCategory(int id) =>
      repository.getStandardCategory(id);

  /// S11
  Future<Either<Failure, List<CategoryTreeNode>>> browseCategoryTree(
          {int? parentId}) =>
      repository.browseCategoryTree(parentId: parentId);

  /// S12
  Future<Either<Failure, List<CategoryMapping>>> getCategoryMappings(
          int categoryId) =>
      repository.getCategoryMappings(categoryId);

  /// S13
  Future<Either<Failure, List<ThumbnailTemplateSummary>>>
      listThumbnailTemplates() => repository.listThumbnailTemplates();

  /// S14
  Future<Either<Failure, List<DetailImageGroup>>> listDetailImageGroups() =>
      repository.listDetailImageGroups();

  /// S15
  Future<Either<Failure, List<MasterBox>>> getPurchasedBoxes() =>
      repository.getPurchasedBoxes();

  /// S16
  Future<Either<Failure, List<OutboundPlace>>> listOutboundPlaces(
          int accountId) =>
      repository.listOutboundPlaces(accountId);

  /// S17
  Future<Either<Failure, List<ReturnCenter>>> listReturnCenters(
          int accountId) =>
      repository.listReturnCenters(accountId);

  /// S18
  Future<Either<Failure, ShippingSettings>> getShippingConfig(int accountId) =>
      repository.getShippingConfig(accountId);

  /// S19
  Future<Either<Failure, ShippingSettings>> upsertShippingConfig(
          int accountId, ShippingSettings settings) =>
      repository.upsertShippingConfig(accountId, settings);
}
