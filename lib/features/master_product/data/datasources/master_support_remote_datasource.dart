import 'dart:io';

import 'package:flutter_oklyn_mobile/features/master_product/data/datasources/master_api.dart';
import 'package:flutter_oklyn_mobile/features/master_product/data/models/master_json.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/detail_content.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/thumbnail_photo.dart';

/// Remote calls for the master screens — port of web `DetailContentRepositoryImpl.ts · ProductImageRepositoryImpl.ts · CategoryRepositoryImpl.ts · CategoryMappingRepositoryImpl.ts · ThumbnailTemplateRepositoryImpl.ts · DetailImageGroupRepositoryImpl.ts · PackageRepositoryImpl.ts · ShippingRepositoryImpl.ts` (FEATURE_2609_80 R3).
/// **File**: lib/features/master_product/data/datasources/master_support_remote_datasource.dart
class MasterSupportRemoteDataSource {
  final MasterApi api;

  MasterSupportRemoteDataSource({required this.api});

  /// S1
  Future<List<DetailTemplate>> listDetailTemplates() async {
    final data = await api.get('/api/admin/detail-templates');
    return (data as List? ?? const [])
        .map((e) => detailTemplateFromJson(e as Json))
        .toList();
  }

  /// S2
  Future<MasterPoolImage> uploadPoolImage(int masterId, File file) async {
    final data =
        await api.postFile('/api/admin/master-products/$masterId/images', file);
    return masterPoolImageFromJson(data as Json);
  }

  /// S3
  Future<List<MasterPoolImage>> listPoolImages(int masterId) async {
    final data = await api.get('/api/admin/master-products/$masterId/images');
    return (data as List? ?? const [])
        .map((e) => masterPoolImageFromJson(e as Json))
        .toList();
  }

  /// S4
  Future<void> deletePoolImage(int masterId, int imageId) async {
    await api.delete('/api/admin/master-products/$masterId/images/$imageId');
  }

  /// S5
  Future<List<MasterPoolImage>> setZoneImages(
      int masterId, String zoneId, List<int> imageIds) async {
    final data = await api.put(
        '/api/admin/master-products/$masterId/zones/$zoneId/images',
        body: {'imageIds': imageIds});
    return (data as List? ?? const [])
        .map((e) => masterPoolImageFromJson(e as Json))
        .toList();
  }

  /// S6
  Future<void> setSourceImage(int masterId, int? imageId) async {
    await api.put('/api/admin/master-products/$masterId/source-image',
        body: {'imageId': imageId});
  }

  /// S28 — FEATURE_2610_32 D31: every thumbnail photo stage of the master.
  Future<List<ThumbnailPhotoStageView>> listThumbnailPhotoStages(
      int masterId) async {
    final data =
        await api.get('/api/admin/master-products/$masterId/thumbnail-photo');
    return _thumbnailPhotoStages(data);
  }

  /// S29 — FEATURE_2610_32 D23: choose ([imageId]) or clear (null) one
  /// stage's thumbnail photo; returns every stage row.
  Future<List<ThumbnailPhotoStageView>> setThumbnailPhoto(
    int masterId, {
    required String stage,
    required int? sellerId,
    required int? listingId,
    required int? imageId,
  }) async {
    final data = await api.put(
        '/api/admin/master-products/$masterId/thumbnail-photo',
        body: {
          'stage': stage,
          'sellerId': sellerId,
          'listingId': listingId,
          'imageId': imageId,
        });
    return _thumbnailPhotoStages(data);
  }

  List<ThumbnailPhotoStageView> _thumbnailPhotoStages(Object? data) =>
      (data as List? ?? const [])
          .map((e) => thumbnailPhotoStageViewFromJson(e as Json))
          .toList();

  /// S7
  Future<List<MasterPoolImage>> importProductImages(
      int masterId, List<int> productImageIds) async {
    final data = await api.post(
        '/api/admin/master-products/$masterId/images/import',
        body: {'productImageIds': productImageIds});
    return (data as List? ?? const [])
        .map((e) => masterPoolImageFromJson(e as Json))
        .toList();
  }

  /// S8
  Future<List<ProductGalleryImage>> listProductImages(int productId) async {
    final data = await api.get('/api/admin/products/$productId/images');
    return (data as List? ?? const [])
        .map((e) => productGalleryImageFromJson(e as Json))
        .toList();
  }

  /// S9
  Future<List<StandardCategory>> getStandardCategories() async {
    final data = await api.get('/api/admin/category');
    return (data as List? ?? const [])
        .map((e) => standardCategoryFromJson(e as Json))
        .toList();
  }

  /// S10
  Future<StandardCategory> getStandardCategory(int id) async {
    final data = await api.get('/api/admin/category/$id');
    return standardCategoryFromJson(data as Json);
  }

  /// S11
  Future<List<CategoryTreeNode>> browseCategoryTree({int? parentId}) async {
    final data = await api.get('/api/admin/category/tree',
        query: {if (parentId != null) 'parentId': parentId});
    return (data as List? ?? const [])
        .map((e) => categoryTreeNodeFromJson(e as Json))
        .toList();
  }

  /// S12
  Future<List<CategoryMapping>> getCategoryMappings(int categoryId) async {
    final data = await api
        .get('/api/admin/category-mappings/categories/$categoryId/mappings');
    return (data as List? ?? const [])
        .map((e) => categoryMappingFromJson(e as Json))
        .toList();
  }

  /// S13
  Future<List<ThumbnailTemplateSummary>> listThumbnailTemplates() async {
    final data = await api.get('/api/admin/thumbnail-templates');
    return (data as List? ?? const [])
        .map((e) => thumbnailTemplateSummaryFromJson(e as Json))
        .toList();
  }

  /// S14
  Future<List<DetailImageGroup>> listDetailImageGroups() async {
    final data = await api.get('/api/admin/detail-image-groups');
    return (data as List? ?? const [])
        .map((e) => detailImageGroupFromJson(e as Json))
        .toList();
  }

  /// S15
  Future<List<MasterBox>> getPurchasedBoxes() async {
    final data =
        await api.get('/api/admin/package', query: {'boxKind': 'PURCHASED'});
    return (data as List? ?? const [])
        .map((e) => masterBoxFromJson(e as Json))
        .toList();
  }

  /// S16
  Future<List<OutboundPlace>> listOutboundPlaces(int accountId) async {
    final data = await api.get(
        '/api/admin/marketplace-account/$accountId/shipping-places/outbound');
    return (data as List? ?? const [])
        .map((e) => outboundPlaceFromJson(e as Json))
        .toList();
  }

  /// S17
  Future<List<ReturnCenter>> listReturnCenters(int accountId) async {
    final data = await api.get(
        '/api/admin/marketplace-account/$accountId/shipping-places/return');
    return (data as List? ?? const [])
        .map((e) => returnCenterFromJson(e as Json))
        .toList();
  }

  /// S18
  Future<ShippingSettings> getShippingConfig(int accountId) async {
    final data = await api
        .get('/api/admin/marketplace-account/$accountId/shipping-config');
    return data is Json
        ? shippingSettingsFromJson(data)
        : const ShippingSettings();
  }

  /// S19
  Future<ShippingSettings> upsertShippingConfig(
      int accountId, ShippingSettings settings) async {
    final data = await api.put(
        '/api/admin/marketplace-account/$accountId/shipping-config',
        body: shippingConfigRequestToJson(settings));
    return shippingSettingsFromJson(data as Json);
  }

  /// S20 — FEATURE_2610_13 / D84: the 11st channel default (`elevenst.*` keys; nothing stored = empty map).
  Future<Map<String, String>> getElevenstShippingConfig(int accountId) async {
    final data = await api.get(
        '/api/admin/marketplace-account/$accountId/elevenst-shipping-config');
    final settings = data is Json ? data['settings'] : null;
    return settings is Map
        ? settings.map((k, v) => MapEntry(k as String, v.toString()))
        : <String, String>{};
  }

  /// S21 — replaces the whole 11st settings map; returns the D120 failed count.
  Future<int> upsertElevenstShippingConfig(
      int accountId, Map<String, String> settings) async {
    final data = await api.put(
        '/api/admin/marketplace-account/$accountId/elevenst-shipping-config',
        body: {'settings': settings});
    return recalcFailedCountFromJson(data as Json);
  }

  /// S23 — FEATURE_2610_26 / D36: the ESM channel layer (`esm.*` keys;
  /// nothing stored = empty map).
  Future<Map<String, String>> getEsmShippingConfig(int accountId) async {
    final data = await api.get(
        '/api/admin/marketplace-account/$accountId/esm-shipping-config');
    final settings = data is Json ? data['settings'] : null;
    return settings is Map
        ? settings.map((k, v) => MapEntry(k as String, v.toString()))
        : <String, String>{};
  }

  /// S24 — replaces the whole ESM settings map; returns the D65 failed count.
  Future<int> upsertEsmShippingConfig(
      int accountId, Map<String, String> settings) async {
    final data = await api.put(
        '/api/admin/marketplace-account/$accountId/esm-shipping-config',
        body: {'settings': settings});
    return recalcFailedCountFromJson(data as Json);
  }

  /// S25 — FEATURE_2610_26 / D37: the bundle-fee policies of one ESM
  /// shipping place.
  Future<List<EsmChoice>> listEsmBundlePolicies(
      int accountId, String placeNo) async {
    final data = await api.get(
        '/api/admin/marketplace-account/$accountId/esm-shipping/bundle-policies',
        query: {'placeNo': placeNo});
    return _esmChoices(data);
  }

  /// S26 — FEATURE_2610_26 / D37 · D68: the ESM dispatch policies.
  Future<List<EsmChoice>> listEsmDispatchPolicies(int accountId) async {
    final data = await api.get(
        '/api/admin/marketplace-account/$accountId/esm-shipping/dispatch-policies');
    return _esmChoices(data);
  }

  /// S27 — FEATURE_2610_26 / D37: the ESM couriers.
  Future<List<EsmChoice>> listEsmDeliveryCompanies(int accountId) async {
    final data = await api.get(
        '/api/admin/marketplace-account/$accountId/esm-shipping/delivery-companies');
    return _esmChoices(data);
  }

  List<EsmChoice> _esmChoices(Object? data) => (data as List? ?? const [])
      .map((e) => EsmChoice(
            code: (e as Json)['code'] as String,
            name: e['name'] as String,
          ))
      .toList();

  /// S22 — FEATURE_2610_13 / D98: every sales channel of the tenant (platform + on/off only).
  Future<List<AccountPlatform>> listAccountPlatforms() async {
    final data = await api.get('/api/admin/marketplace-account');
    return (data as List? ?? const [])
        .map((e) => AccountPlatform(
              platform: (e as Json)['platform'] as String,
              isActive: e['isActive'] as bool? ?? true,
            ))
        .toList();
  }
}
