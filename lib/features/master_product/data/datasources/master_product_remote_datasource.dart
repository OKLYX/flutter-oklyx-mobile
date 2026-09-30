import 'package:flutter_oklyn_mobile/features/master_product/data/datasources/master_api.dart';
import 'package:flutter_oklyn_mobile/features/master_product/data/models/master_json.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';

/// Remote calls for the master screens — port of web `MasterProductRepositoryImpl.ts` (FEATURE_2609_80 R3).
/// **File**: lib/features/master_product/data/datasources/master_product_remote_datasource.dart
class MasterProductRemoteDataSource {
  final MasterApi api;

  MasterProductRemoteDataSource({required this.api});

  /// M1
  Future<MasterProductPage> listMasters(
      {required int page,
      required int size,
      required String sort,
      String? search}) async {
    final data = await api.get('/api/admin/master-products', query: {
      'page': page,
      'size': size,
      'sort': sort,
      if (search != null) 'search': search
    });
    return masterProductPageFromJson(data as Json);
  }

  /// M2
  Future<MasterProduct> getMaster(int id) async {
    final data = await api.get('/api/admin/master-products/$id');
    return masterProductFromJson(data as Json);
  }

  /// M3
  Future<List<MasterByComponents>> findByComponents(
      List<int> productIds) async {
    if (productIds.isEmpty) {
      return [];
    }
    final data = await api.get('/api/admin/master-products/by-components',
        query: {'productIds': productIds.join(',')});
    return (data as List? ?? const [])
        .map((e) => masterByComponentsFromJson(e as Json))
        .toList();
  }

  /// M4
  Future<List<MasterByAnyComponent>> findByAnyComponent(
      List<int> productIds) async {
    if (productIds.isEmpty) {
      return [];
    }
    final data = await api.get('/api/admin/master-products/by-any-component',
        query: {'productIds': productIds.join(',')});
    return (data as List? ?? const [])
        .map((e) => masterByAnyComponentFromJson(e as Json))
        .toList();
  }

  /// M5
  Future<MasterProduct> createMaster(MasterProductRequest request) async {
    final data = await api.post('/api/admin/master-products',
        body: masterProductRequestToJson(request));
    return masterProductFromJson(data as Json);
  }

  /// M6
  Future<MasterProduct> updateMaster(
      int id, MasterProductUpdateRequest request) async {
    final data = await api.patch('/api/admin/master-products/$id',
        body: masterProductUpdateRequestToJson(request));
    return masterProductFromJson(data as Json);
  }

  /// M7
  Future<MasterProduct> updateComposition(
      int id, MasterCompositionRequest request) async {
    final data = await api.put('/api/admin/master-products/$id/composition',
        body: masterCompositionRequestToJson(request));
    return masterProductFromJson(data as Json);
  }

  /// M8
  Future<void> deleteMaster(int id) async {
    await api.delete('/api/admin/master-products/$id');
  }

  /// M9
  Future<MasterOption> addOption(int id, MasterOptionRequest request) async {
    final data = await api.post('/api/admin/master-products/$id/options',
        body: masterOptionRequestToJson(request));
    return masterOptionFromJson(data as Json);
  }

  /// M10
  Future<MasterOption> updateOption(
      int id, int optionId, MasterOptionRequest request) async {
    final data = await api.patch(
        '/api/admin/master-products/$id/options/$optionId',
        body: masterOptionRequestToJson(request));
    return masterOptionFromJson(data as Json);
  }

  /// M11
  Future<void> deleteOption(int id, int optionId) async {
    await api.delete('/api/admin/master-products/$id/options/$optionId');
  }

  /// M12
  Future<ListingMatrix> getMatrix(int id) async {
    final data = await api.get('/api/admin/master-products/$id/matrix');
    return listingMatrixFromJson(data as Json);
  }

  /// M13
  Future<MasterChannelOptions> getChannelOptions(int id) async {
    final data =
        await api.get('/api/admin/master-products/$id/channel-options');
    return masterChannelOptionsFromJson(data as Json);
  }

  /// M14
  Future<MasterCategory?> getMasterCategory(int id) async {
    final data = await api.get('/api/admin/master-products/$id/category');
    return masterCategoryFromJson(data);
  }

  /// M15
  Future<MasterCategory?> setMasterCategory(int id, int categoryId) async {
    final data = await api.put('/api/admin/master-products/$id/category',
        body: {'categoryId': categoryId});
    return masterCategoryFromJson(data);
  }

  /// M16
  Future<void> clearMasterCategory(int id) async {
    await api.delete('/api/admin/master-products/$id/category');
  }

  /// M17
  Future<CategoryMeta> getCategoryMeta(int id, String platform) async {
    final data = await api.get('/api/admin/master-products/$id/category-meta',
        query: {'platform': platform});
    return categoryMetaFromJson(data as Json);
  }

  /// M18
  Future<CategoryMetaSchema> getCategorySchema(
      int categoryId, String platform) async {
    final data = await api.get('/api/admin/category-lookup/$platform/meta',
        query: {'categoryId': categoryId});
    return categoryMetaSchemaFromJson(data as Json);
  }

  /// M19
  Future<void> setCategoryAttributes(
      int id, CategoryAttributesRequest request) async {
    await api.patch('/api/admin/master-products/$id/category-attributes',
        body: categoryAttributesRequestToJson(request));
  }

  /// M20
  Future<MasterProduct> updateMasterTags(int id, List<String> tags) async {
    final data = await api
        .patch('/api/admin/master-products/$id/tags', body: {'tags': tags});
    return masterProductFromJson(data as Json);
  }

  /// M21
  Future<void> updateRegistrationNameSuffix(int id,
      {required bool? enabled, required String? suffix}) async {
    await api.put('/api/admin/master-products/$id/registration-name-suffix',
        body: {'enabled': enabled, 'suffix': suffix});
  }

  /// M22
  Future<MasterProduct> updateMasterShippingOverride(
      int id, Map<String, String> override) async {
    final data = await api.patch(
        '/api/admin/master-products/$id/shipping-override',
        body: {'override': override});
    return masterProductFromJson(data as Json);
  }

  /// M23
  Future<ShippingForceApplyResult> applyShippingOverrideToChannels(
      int id, List<int> listingIds) async {
    final data = await api.post(
        '/api/admin/master-products/$id/shipping-override/apply-to-channels',
        body: {'listingIds': listingIds});
    return shippingForceApplyFromJson(data as Json);
  }
}
