import 'dart:io';

import 'package:flutter_oklyn_mobile/features/master_product/data/datasources/master_api.dart';
import 'package:flutter_oklyn_mobile/features/master_product/data/models/master_json.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/detail_content.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';

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
}
