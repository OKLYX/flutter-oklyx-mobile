import 'package:flutter_oklyn_mobile/features/master_product/data/datasources/master_api.dart';
import 'package:flutter_oklyn_mobile/features/master_product/data/models/master_json.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';

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

  /// FEATURE_2610_12 / D48: the master's own platform categories (「개별 지정」)
  /// — same fields as a category mapping row.
  Future<List<CategoryMapping>> getMasterPlatformCategories(int id) async {
    final data =
        await api.get('/api/admin/master-products/$id/platform-categories');
    return (data as List? ?? const [])
        .map((e) => categoryMappingFromJson(e as Json))
        .toList();
  }

  /// M17
  Future<CategoryMeta> getCategoryMeta(int id, String platform) async {
    final data = await api.get('/api/admin/master-products/$id/category-meta',
        query: {'platform': platform});
    return categoryMetaFromJson(data as Json);
  }

  /// M18 — FEATURE_2610_12 / D45: [platformCategoryCode] (a 「개별 지정」
  /// code) wins on the server; the category id stays for the no-pick case.
  Future<CategoryMetaSchema> getCategorySchema(int categoryId, String platform,
      {String? platformCategoryCode}) async {
    final data =
        await api.get('/api/admin/category-lookup/$platform/meta', query: {
      'categoryId': categoryId,
      if (platformCategoryCode != null)
        'platformCategoryCode': platformCategoryCode,
    });
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

  /// M24 — FEATURE_2610_13 / D97: the 11st view of the notice values on screen (pure conversion, nothing saved).
  Future<ElevenstNotification> previewElevenstNotice(
      String group, Map<String, String> notices) async {
    final data = await api.post('/api/admin/elevenst/notice-preview',
        body: {'group': group, 'notices': notices});
    final j = data as Json;
    return ElevenstNotification(
      typeCode: j['typeCode'] as String,
      typeName: j['typeName'] as String,
      lines: (j['lines'] as List? ?? const [])
          .map((e) => ElevenstNoticeLine(
                code: (e as Json)['code'] as String,
                name: e['name'] as String,
                value: e['value'] as String,
                ownKey: e['ownKey'] as String?,
              ))
          .toList(),
      usedCoupangItems: (j['usedCoupangItems'] as List? ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }

  /// M25 — FEATURE_2610_26 / D56: the Gmarket · Auction view of the notice
  /// values on screen (pure conversion, nothing saved).
  Future<EsmNotification> previewEsmNotice(
      String group, Map<String, String> notices) async {
    final data = await api.post('/api/admin/esm/notice-preview',
        body: {'group': group, 'notices': notices});
    final j = data as Json;
    return EsmNotification(
      groupNo: j['groupNo'] as String,
      groupName: j['groupName'] as String,
      lines: (j['lines'] as List? ?? const [])
          .map((e) => EsmNoticeLine(
                code: (e as Json)['code'] as String,
                name: e['name'] as String,
                value: e['value'] as String,
                ownKey: e['ownKey'] as String?,
              ))
          .toList(),
      usedCoupangItems: (j['usedCoupangItems'] as List? ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }
}
