import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/master_product/data/datasources/listing_registration_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/master_product/data/datasources/master_product_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/master_product/data/datasources/master_support_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/detail_content.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/repositories/master_product_repository.dart';

/// Fixed 403 message — same sentence as the mobile precedents (shipping_label · claim).
const String kMasterForbiddenMessage = '권한이 없습니다. 관리자 계정으로 로그인해주세요.';

class MasterProductRepositoryImpl implements MasterProductRepository {
  final MasterProductRemoteDataSource masterDataSource;
  final ListingRegistrationRemoteDataSource listingDataSource;
  final MasterSupportRemoteDataSource supportDataSource;

  MasterProductRepositoryImpl({
    required this.masterDataSource,
    required this.listingDataSource,
    required this.supportDataSource,
  });

  // Value-returning — M* = masterDataSource · L* = listingDataSource · S* = supportDataSource
  // void-returning → Unit

  @override
  Future<Either<Failure, MasterProductPage>> listMasters(
          {required int page,
          required int size,
          required String sort,
          String? search}) =>
      _guard(() => masterDataSource.listMasters(
          page: page, size: size, sort: sort, search: search));

  @override
  Future<Either<Failure, MasterProduct>> getMaster(int id) =>
      _guard(() => masterDataSource.getMaster(id));

  @override
  Future<Either<Failure, List<MasterByComponents>>> findByComponents(
          List<int> productIds) =>
      _guard(() => masterDataSource.findByComponents(productIds));

  @override
  Future<Either<Failure, List<MasterByAnyComponent>>> findByAnyComponent(
          List<int> productIds) =>
      _guard(() => masterDataSource.findByAnyComponent(productIds));

  @override
  Future<Either<Failure, MasterProduct>> createMaster(
          MasterProductRequest request) =>
      _guard(() => masterDataSource.createMaster(request));

  @override
  Future<Either<Failure, MasterProduct>> updateMaster(
          int id, MasterProductUpdateRequest request) =>
      _guard(() => masterDataSource.updateMaster(id, request));

  @override
  Future<Either<Failure, MasterProduct>> updateComposition(
          int id, MasterCompositionRequest request) =>
      _guard(() => masterDataSource.updateComposition(id, request));

  @override
  Future<Either<Failure, Unit>> deleteMaster(int id) => _guard(() async {
        await masterDataSource.deleteMaster(id);
        return unit;
      });

  @override
  Future<Either<Failure, MasterOption>> addOption(
          int id, MasterOptionRequest request) =>
      _guard(() => masterDataSource.addOption(id, request));

  @override
  Future<Either<Failure, MasterOption>> updateOption(
          int id, int optionId, MasterOptionRequest request) =>
      _guard(() => masterDataSource.updateOption(id, optionId, request));

  @override
  Future<Either<Failure, Unit>> deleteOption(int id, int optionId) =>
      _guard(() async {
        await masterDataSource.deleteOption(id, optionId);
        return unit;
      });

  @override
  Future<Either<Failure, ListingMatrix>> getMatrix(int id) =>
      _guard(() => masterDataSource.getMatrix(id));

  @override
  Future<Either<Failure, MasterChannelOptions>> getChannelOptions(int id) =>
      _guard(() => masterDataSource.getChannelOptions(id));

  @override
  Future<Either<Failure, MasterCategory?>> getMasterCategory(int id) =>
      _guard(() => masterDataSource.getMasterCategory(id));

  @override
  Future<Either<Failure, MasterCategory?>> setMasterCategory(
          int id, int categoryId) =>
      _guard(() => masterDataSource.setMasterCategory(id, categoryId));

  @override
  Future<Either<Failure, Unit>> clearMasterCategory(int id) => _guard(() async {
        await masterDataSource.clearMasterCategory(id);
        return unit;
      });

  @override
  Future<Either<Failure, CategoryMeta>> getCategoryMeta(
          int id, String platform) =>
      _guard(() => masterDataSource.getCategoryMeta(id, platform));

  @override
  Future<Either<Failure, CategoryMetaSchema>> getCategorySchema(
          int categoryId, String platform) =>
      _guard(() => masterDataSource.getCategorySchema(categoryId, platform));

  @override
  Future<Either<Failure, Unit>> setCategoryAttributes(
          int id, CategoryAttributesRequest request) =>
      _guard(() async {
        await masterDataSource.setCategoryAttributes(id, request);
        return unit;
      });

  @override
  Future<Either<Failure, MasterProduct>> updateMasterTags(
          int id, List<String> tags) =>
      _guard(() => masterDataSource.updateMasterTags(id, tags));

  @override
  Future<Either<Failure, Unit>> updateRegistrationNameSuffix(int id,
          {required bool? enabled, required String? suffix}) =>
      _guard(() async {
        await masterDataSource.updateRegistrationNameSuffix(id,
            enabled: enabled, suffix: suffix);
        return unit;
      });

  @override
  Future<Either<Failure, MasterProduct>> updateMasterShippingOverride(
          int id, Map<String, String> override) =>
      _guard(() => masterDataSource.updateMasterShippingOverride(id, override));

  @override
  Future<Either<Failure, ShippingForceApplyResult>>
      applyShippingOverrideToChannels(int id, List<int> listingIds) =>
          _guard(() =>
              masterDataSource.applyShippingOverrideToChannels(id, listingIds));

  @override
  Future<Either<Failure, ChannelAddResult>> addChannel(int masterId,
          {required int sellerId, required String platform}) =>
      _guard(() => listingDataSource.addChannel(masterId,
          sellerId: sellerId, platform: platform));

  @override
  Future<Either<Failure, BatchChannelAddResult>> addChannelsBatch(
          int masterId, List<ChannelTarget> targets) =>
      _guard(() => listingDataSource.addChannelsBatch(masterId, targets));

  @override
  Future<Either<Failure, ListingRegisterResult>> registerListing(
          int listingId) =>
      _guard(() => listingDataSource.registerListing(listingId));

  @override
  Future<Either<Failure, ListingRegisterResult>> requestListingUpdate(
          int listingId) =>
      _guard(() => listingDataSource.requestListingUpdate(listingId));

  @override
  Future<Either<Failure, ListingStatusResult>> fetchListingStatus(
          int listingId) =>
      _guard(() => listingDataSource.fetchListingStatus(listingId));

  @override
  Future<Either<Failure, GeneratedProduct>> getGenerated(int listingId) =>
      _guard(() => listingDataSource.getGenerated(listingId));

  @override
  Future<Either<Failure, GeneratedProduct>> regenerate(int listingId) =>
      _guard(() => listingDataSource.regenerate(listingId));

  @override
  Future<Either<Failure, GeneratedProduct>> overrideListingThumbnail(
          int listingId, File file) =>
      _guard(() => listingDataSource.overrideListingThumbnail(listingId, file));

  @override
  Future<Either<Failure, GeneratedProduct>> clearListingThumbnail(
          int listingId) =>
      _guard(() => listingDataSource.clearListingThumbnail(listingId));

  @override
  Future<Either<Failure, GeneratedProduct>> updateListingFieldValues(
          int listingId, Map<String, String> fieldValues) =>
      _guard(() =>
          listingDataSource.updateListingFieldValues(listingId, fieldValues));

  @override
  Future<Either<Failure, Unit>> updateDisplayName(int listingId, String name) =>
      _guard(() async {
        await listingDataSource.updateDisplayName(listingId, name);
        return unit;
      });

  @override
  Future<Either<Failure, GeneratedProduct>> updateListingTags(
          int listingId, List<String> tags) =>
      _guard(() => listingDataSource.updateListingTags(listingId, tags));

  @override
  Future<Either<Failure, GeneratedProduct>> updateListingShippingOverride(
          int listingId, Map<String, String> override) =>
      _guard(() =>
          listingDataSource.updateListingShippingOverride(listingId, override));

  @override
  Future<Either<Failure, ShippingSettings>> getInheritedShipping(
          int listingId) =>
      _guard(() => listingDataSource.getInheritedShipping(listingId));

  @override
  Future<Either<Failure, PropagateResult>> propagate(int masterId) =>
      _guard(() => listingDataSource.propagate(masterId));

  @override
  Future<Either<Failure, ChannelSyncPreview>> getChannelSyncPreview(
          int masterId) =>
      _guard(() => listingDataSource.getChannelSyncPreview(masterId));

  @override
  Future<Either<Failure, String>> previewDetail(int listingId,
          {int? templateId}) =>
      _guard(() =>
          listingDataSource.previewDetail(listingId, templateId: templateId));

  @override
  Future<Either<Failure, GeneratedProduct>> overrideDetailHtml(
          int listingId, String html) =>
      _guard(() => listingDataSource.overrideDetailHtml(listingId, html));

  @override
  Future<Either<Failure, GeneratedProduct>> clearDetailHtml(int listingId) =>
      _guard(() => listingDataSource.clearDetailHtml(listingId));

  @override
  Future<Either<Failure, DetailTemplate>> getResolvedDetailTemplate(
          int listingId) =>
      _guard(() => listingDataSource.getResolvedDetailTemplate(listingId));

  @override
  Future<Either<Failure, GeneratedProduct>> updateDetailTemplate(
          int listingId, int? templateId) =>
      _guard(
          () => listingDataSource.updateDetailTemplate(listingId, templateId));

  @override
  Future<Either<Failure, ListingOptions>> getListingOptions(int listingId) =>
      _guard(() => listingDataSource.getListingOptions(listingId));

  @override
  Future<Either<Failure, ListingOptions>> setActiveOptions(
          int listingId, List<int> activeOptionIds) =>
      _guard(
          () => listingDataSource.setActiveOptions(listingId, activeOptionIds));

  @override
  Future<Either<Failure, ListingOptions>> setOptionStocks(
          int listingId, List<OptionStockChange> stocks) =>
      _guard(() => listingDataSource.setOptionStocks(listingId, stocks));

  @override
  Future<Either<Failure, ChannelPriceUpdateResult>> setOptionPrices(
          int listingId, List<OptionPriceChange> prices) =>
      _guard(() => listingDataSource.setOptionPrices(listingId, prices));

  @override
  Future<Either<Failure, ListingOptions>> setOptionNames(
          int listingId, List<OptionNameChange> names) =>
      _guard(() => listingDataSource.setOptionNames(listingId, names));

  @override
  Future<Either<Failure, ApplyOptionNamesResult>> applyMasterOptionNames(
          int masterId) =>
      _guard(() => listingDataSource.applyMasterOptionNames(masterId));

  @override
  Future<Either<Failure, ChannelApplyOptionNamesResult>>
      applyMasterOptionNamesToListing(int listingId) => _guard(
          () => listingDataSource.applyMasterOptionNamesToListing(listingId));

  @override
  Future<Either<Failure, ImportPreview>> importPreview(int masterId,
          {required int sellerId,
          required String platform,
          required String platformProductId}) =>
      _guard(() => listingDataSource.importPreview(masterId,
          sellerId: sellerId,
          platform: platform,
          platformProductId: platformProductId));

  @override
  Future<Either<Failure, ChannelAddResult>> importListing(int masterId,
          {required int sellerId,
          required String platform,
          required String platformProductId,
          required List<ImportOptionSpec> options}) =>
      _guard(() => listingDataSource.importListing(masterId,
          sellerId: sellerId,
          platform: platform,
          platformProductId: platformProductId,
          options: options));

  @override
  Future<Either<Failure, List<DetachedListing>>> findDetachedListings(
          int masterId,
          {required int sellerId,
          required String platform,
          String? keyword}) =>
      _guard(() => listingDataSource.findDetachedListings(masterId,
          sellerId: sellerId, platform: platform, keyword: keyword));

  @override
  Future<Either<Failure, List<MarketOption>>> getMarketOptions(int listingId) =>
      _guard(() => listingDataSource.getMarketOptions(listingId));

  @override
  Future<Either<Failure, ListingStatusOption>> linkMarketOption(
          int listingId, int optionId, String vendorItemId) =>
      _guard(() => listingDataSource.linkMarketOption(
          listingId, optionId, vendorItemId));

  @override
  Future<Either<Failure, Unit>> unlinkChannel(int masterId, int listingId) =>
      _guard(() async {
        await listingDataSource.unlinkChannel(masterId, listingId);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deleteDraftChannel(
          int masterId, int listingId) =>
      _guard(() async {
        await listingDataSource.deleteDraftChannel(masterId, listingId);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> setCategorySource(int listingId,
          {required bool useMasterCategory}) =>
      _guard(() async {
        await listingDataSource.setCategorySource(listingId,
            useMasterCategory: useMasterCategory);
        return unit;
      });

  @override
  Future<Either<Failure, MasterFromChannelPreview>> masterFromChannelPreview(
          {required int sellerId,
          required String platform,
          required String platformProductId}) =>
      _guard(() => listingDataSource.masterFromChannelPreview(
          sellerId: sellerId,
          platform: platform,
          platformProductId: platformProductId));

  @override
  Future<Either<Failure, List<DetailTemplate>>> listDetailTemplates() =>
      _guard(() => supportDataSource.listDetailTemplates());

  @override
  Future<Either<Failure, MasterPoolImage>> uploadPoolImage(
          int masterId, File file) =>
      _guard(() => supportDataSource.uploadPoolImage(masterId, file));

  @override
  Future<Either<Failure, List<MasterPoolImage>>> listPoolImages(int masterId) =>
      _guard(() => supportDataSource.listPoolImages(masterId));

  @override
  Future<Either<Failure, Unit>> deletePoolImage(int masterId, int imageId) =>
      _guard(() async {
        await supportDataSource.deletePoolImage(masterId, imageId);
        return unit;
      });

  @override
  Future<Either<Failure, List<MasterPoolImage>>> setZoneImages(
          int masterId, String zoneId, List<int> imageIds) =>
      _guard(() => supportDataSource.setZoneImages(masterId, zoneId, imageIds));

  @override
  Future<Either<Failure, Unit>> setSourceImage(int masterId, int? imageId) =>
      _guard(() async {
        await supportDataSource.setSourceImage(masterId, imageId);
        return unit;
      });

  @override
  Future<Either<Failure, List<MasterPoolImage>>> importProductImages(
          int masterId, List<int> productImageIds) =>
      _guard(() =>
          supportDataSource.importProductImages(masterId, productImageIds));

  @override
  Future<Either<Failure, List<ProductGalleryImage>>> listProductImages(
          int productId) =>
      _guard(() => supportDataSource.listProductImages(productId));

  @override
  Future<Either<Failure, List<StandardCategory>>> getStandardCategories() =>
      _guard(() => supportDataSource.getStandardCategories());

  @override
  Future<Either<Failure, StandardCategory>> getStandardCategory(int id) =>
      _guard(() => supportDataSource.getStandardCategory(id));

  @override
  Future<Either<Failure, List<CategoryTreeNode>>> browseCategoryTree(
          {int? parentId}) =>
      _guard(() => supportDataSource.browseCategoryTree(parentId: parentId));

  @override
  Future<Either<Failure, List<CategoryMapping>>> getCategoryMappings(
          int categoryId) =>
      _guard(() => supportDataSource.getCategoryMappings(categoryId));

  @override
  Future<Either<Failure, List<ThumbnailTemplateSummary>>>
      listThumbnailTemplates() =>
          _guard(() => supportDataSource.listThumbnailTemplates());

  @override
  Future<Either<Failure, List<DetailImageGroup>>> listDetailImageGroups() =>
      _guard(() => supportDataSource.listDetailImageGroups());

  @override
  Future<Either<Failure, List<MasterBox>>> getPurchasedBoxes() =>
      _guard(() => supportDataSource.getPurchasedBoxes());

  @override
  Future<Either<Failure, List<OutboundPlace>>> listOutboundPlaces(
          int accountId) =>
      _guard(() => supportDataSource.listOutboundPlaces(accountId));

  @override
  Future<Either<Failure, List<ReturnCenter>>> listReturnCenters(
          int accountId) =>
      _guard(() => supportDataSource.listReturnCenters(accountId));

  @override
  Future<Either<Failure, ShippingSettings>> getShippingConfig(int accountId) =>
      _guard(() => supportDataSource.getShippingConfig(accountId));

  @override
  Future<Either<Failure, ShippingSettings>> upsertShippingConfig(
          int accountId, ShippingSettings settings) =>
      _guard(() => supportDataSource.upsertShippingConfig(accountId, settings));

  /// Exception → [ServerFailure]. The only place in this feature that turns exceptions into Failures.
  /// 403 gets the fixed message; anything else gets the envelope `message` ('' when absent).
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on ServerException catch (e) {
      return Left(_failure(e.message, e.statusCode));
    } on DioException catch (e) {
      final body = e.response?.data;
      final message = body is Map && body['message'] is String
          ? body['message'] as String
          : '';
      return Left(_failure(message, e.response?.statusCode));
    } on Exception {
      return const Left(ServerFailure(''));
    }
  }

  ServerFailure _failure(String message, int? statusCode) => statusCode == 403
      ? const ServerFailure(kMasterForbiddenMessage, statusCode: 403)
      : ServerFailure(message, statusCode: statusCode);
}
