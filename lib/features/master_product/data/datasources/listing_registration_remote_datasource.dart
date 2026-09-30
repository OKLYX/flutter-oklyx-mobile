import 'dart:io';

import 'package:flutter_oklyn_mobile/features/master_product/data/datasources/master_api.dart';
import 'package:flutter_oklyn_mobile/features/master_product/data/models/master_json.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/detail_content.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';

/// Remote calls for the master screens — port of web `ListingRegistrationRepositoryImpl.ts` (FEATURE_2609_80 R3).
/// **File**: lib/features/master_product/data/datasources/listing_registration_remote_datasource.dart
class ListingRegistrationRemoteDataSource {
  final MasterApi api;

  ListingRegistrationRemoteDataSource({required this.api});

  /// L1
  Future<ChannelAddResult> addChannel(int masterId,
      {required int sellerId, required String platform}) async {
    final data = await api.post('/api/admin/master-products/$masterId/listings',
        body: {'sellerId': sellerId, 'platform': platform});
    return channelAddResultFromJson(data as Json);
  }

  /// L2
  Future<BatchChannelAddResult> addChannelsBatch(
      int masterId, List<ChannelTarget> targets) async {
    final data = await api
        .post('/api/admin/master-products/$masterId/listings/batch', body: {
      'targets': targets
          .map((t) => {'sellerId': t.sellerId, 'platform': t.platform})
          .toList()
    });
    return batchChannelAddResultFromJson(data as Json);
  }

  /// L3
  Future<ListingRegisterResult> registerListing(int listingId) async {
    final data =
        await api.post('/api/admin/product-listings/$listingId/register');
    return listingRegisterResultFromJson(data as Json);
  }

  /// L4
  Future<ListingRegisterResult> requestListingUpdate(int listingId) async {
    final data =
        await api.post('/api/admin/product-listings/$listingId/update-request');
    return listingRegisterResultFromJson(data as Json);
  }

  /// L5
  Future<ListingStatusResult> fetchListingStatus(int listingId) async {
    final data =
        await api.post('/api/admin/product-listings/$listingId/fetch-status');
    return listingStatusResultFromJson(data as Json);
  }

  /// L6
  Future<GeneratedProduct> getGenerated(int listingId) async {
    final data =
        await api.get('/api/admin/product-listings/$listingId/generated');
    return generatedProductFromJson(data as Json);
  }

  /// L7
  Future<GeneratedProduct> regenerate(int listingId) async {
    final data =
        await api.post('/api/admin/product-listings/$listingId/regenerate');
    return generatedProductFromJson(data as Json);
  }

  /// L8
  Future<GeneratedProduct> overrideListingThumbnail(
      int listingId, File file) async {
    final data = await api.postFile(
        '/api/admin/product-listings/$listingId/thumbnail', file);
    return generatedProductFromJson(data as Json);
  }

  /// L9
  Future<GeneratedProduct> clearListingThumbnail(int listingId) async {
    final data =
        await api.delete('/api/admin/product-listings/$listingId/thumbnail');
    return generatedProductFromJson(data as Json);
  }

  /// L10
  Future<GeneratedProduct> updateListingFieldValues(
      int listingId, Map<String, String> fieldValues) async {
    final data = await api.patch(
        '/api/admin/product-listings/$listingId/field-values',
        body: {'fieldValues': fieldValues});
    return generatedProductFromJson(data as Json);
  }

  /// L11
  Future<void> updateDisplayName(int listingId, String name) async {
    await api.patch('/api/admin/product-listings/$listingId/name',
        body: {'name': name});
  }

  /// L12
  Future<GeneratedProduct> updateListingTags(
      int listingId, List<String> tags) async {
    final data = await api.patch('/api/admin/product-listings/$listingId/tags',
        body: {'tags': tags});
    return generatedProductFromJson(data as Json);
  }

  /// L13
  Future<GeneratedProduct> updateListingShippingOverride(
      int listingId, Map<String, String> override) async {
    final data = await api.patch(
        '/api/admin/product-listings/$listingId/shipping-override',
        body: {'override': override});
    return generatedProductFromJson(data as Json);
  }

  /// L14
  Future<ShippingSettings> getInheritedShipping(int listingId) async {
    final data = await api
        .get('/api/admin/product-listings/$listingId/shipping-inherited');
    return shippingSettingsFromJson(data as Json);
  }

  /// L15
  Future<PropagateResult> propagate(int masterId) async {
    final data =
        await api.post('/api/admin/master-products/$masterId/propagate');
    return propagateResultFromJson(data as Json);
  }

  /// L16
  Future<ChannelSyncPreview> getChannelSyncPreview(int masterId) async {
    final data = await api
        .get('/api/admin/master-products/$masterId/channel-sync-preview');
    return channelSyncPreviewFromJson(data as Json);
  }

  /// L17
  Future<String> previewDetail(int listingId, {int? templateId}) async {
    final data = await api.get(
        '/api/admin/product-listings/$listingId/detail-preview',
        query: {if (templateId != null) 'templateId': templateId});
    return (data as Json)['html']?.toString() ?? '';
  }

  /// L18
  Future<GeneratedProduct> overrideDetailHtml(
      int listingId, String html) async {
    final data = await api.put(
        '/api/admin/product-listings/$listingId/detail-html',
        body: {'html': html});
    return generatedProductFromJson(data as Json);
  }

  /// L19
  Future<GeneratedProduct> clearDetailHtml(int listingId) async {
    final data =
        await api.delete('/api/admin/product-listings/$listingId/detail-html');
    return generatedProductFromJson(data as Json);
  }

  /// L20
  Future<DetailTemplate> getResolvedDetailTemplate(int listingId) async {
    final data =
        await api.get('/api/admin/product-listings/$listingId/detail-template');
    return detailTemplateFromJson(data as Json);
  }

  /// L21
  Future<GeneratedProduct> updateDetailTemplate(
      int listingId, int? templateId) async {
    final data = await api.patch(
        '/api/admin/product-listings/$listingId/detail-template',
        body: {'templateId': templateId});
    return generatedProductFromJson(data as Json);
  }

  /// L22
  Future<ListingOptions> getListingOptions(int listingId) async {
    final data =
        await api.get('/api/admin/product-listings/$listingId/options');
    return listingOptionsFromJson(data as Json);
  }

  /// L23
  Future<ListingOptions> setActiveOptions(
      int listingId, List<int> activeOptionIds) async {
    final data = await api.put(
        '/api/admin/product-listings/$listingId/options/active',
        body: {'activeOptionIds': activeOptionIds});
    return listingOptionsFromJson(data as Json);
  }

  /// L24
  Future<ListingOptions> setOptionStocks(
      int listingId, List<OptionStockChange> stocks) async {
    final data = await api
        .put('/api/admin/product-listings/$listingId/options/stock', body: {
      'stocks': stocks
          .map(
              (s) => {'optionId': s.optionId, 'stockQuantity': s.stockQuantity})
          .toList()
    });
    return listingOptionsFromJson(data as Json);
  }

  /// L25
  Future<ChannelPriceUpdateResult> setOptionPrices(
      int listingId, List<OptionPriceChange> prices) async {
    final data = await api
        .put('/api/admin/product-listings/$listingId/options/price', body: {
      'prices': prices
          .map((p) => {'optionId': p.optionId, 'sellingPrice': p.sellingPrice})
          .toList()
    });
    return channelPriceUpdateResultFromJson(data as Json);
  }

  /// L26
  Future<ListingOptions> setOptionNames(
      int listingId, List<OptionNameChange> names) async {
    final data = await api
        .put('/api/admin/product-listings/$listingId/options/name', body: {
      'names': names
          .map((n) => {'optionId': n.optionId, 'optionName': n.optionName})
          .toList()
    });
    return listingOptionsFromJson(data as Json);
  }

  /// L27
  Future<ApplyOptionNamesResult> applyMasterOptionNames(int masterId) async {
    final data = await api
        .post('/api/admin/master-products/$masterId/options/apply-names');
    return applyOptionNamesResultFromJson(data as Json);
  }

  /// L28
  Future<ChannelApplyOptionNamesResult> applyMasterOptionNamesToListing(
      int listingId) async {
    final data = await api.post(
        '/api/admin/product-listings/$listingId/options/apply-master-names');
    return channelApplyOptionNamesResultFromJson(data as Json);
  }

  /// L29
  Future<ImportPreview> importPreview(int masterId,
      {required int sellerId,
      required String platform,
      required String platformProductId}) async {
    final data = await api.post(
        '/api/admin/master-products/$masterId/listings/import/preview',
        body: {
          'sellerId': sellerId,
          'platform': platform,
          'platformProductId': platformProductId
        });
    return importPreviewFromJson(data as Json);
  }

  /// L30
  Future<ChannelAddResult> importListing(int masterId,
      {required int sellerId,
      required String platform,
      required String platformProductId,
      required List<ImportOptionSpec> options}) async {
    final data = await api
        .post('/api/admin/master-products/$masterId/listings/import', body: {
      'sellerId': sellerId,
      'platform': platform,
      'platformProductId': platformProductId,
      'options': options.map(importOptionSpecToJson).toList()
    });
    return channelAddResultFromJson(data as Json);
  }

  /// L31
  Future<List<DetachedListing>> findDetachedListings(int masterId,
      {required int sellerId,
      required String platform,
      String? keyword}) async {
    final data = await api
        .get('/api/admin/master-products/$masterId/listings/detached', query: {
      'sellerId': sellerId,
      'platform': platform,
      if (keyword != null) 'keyword': keyword
    });
    return (data as List? ?? const [])
        .map((e) => detachedListingFromJson(e as Json))
        .toList();
  }

  /// L32
  Future<List<MarketOption>> getMarketOptions(int listingId) async {
    final data =
        await api.get('/api/admin/product-listings/$listingId/market-options');
    return (data as List? ?? const [])
        .map((e) => marketOptionFromJson(e as Json))
        .toList();
  }

  /// L33
  Future<ListingStatusOption> linkMarketOption(
      int listingId, int optionId, String vendorItemId) async {
    final data = await api.put(
        '/api/admin/product-listings/$listingId/options/$optionId/market-link',
        body: {'vendorItemId': vendorItemId});
    return listingStatusOptionFromJson(data as Json);
  }

  /// L34
  Future<void> unlinkChannel(int masterId, int listingId) async {
    await api.delete(
        '/api/admin/master-products/$masterId/listings/$listingId/link');
  }

  /// L35
  Future<void> deleteDraftChannel(int masterId, int listingId) async {
    await api
        .delete('/api/admin/master-products/$masterId/listings/$listingId');
  }

  /// L36
  Future<void> setCategorySource(int listingId,
      {required bool useMasterCategory}) async {
    await api.patch('/api/admin/product-listings/$listingId/category-source',
        body: {'useMasterCategory': useMasterCategory});
  }

  /// L37
  Future<MasterFromChannelPreview> masterFromChannelPreview(
      {required int sellerId,
      required String platform,
      required String platformProductId}) async {
    final data = await api
        .post('/api/admin/master-products/from-channel/preview', body: {
      'sellerId': sellerId,
      'platform': platform,
      'platformProductId': platformProductId
    });
    return masterFromChannelPreviewFromJson(data as Json);
  }
}
