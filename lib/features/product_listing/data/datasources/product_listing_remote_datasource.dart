import 'package:dio/dio.dart';
import '../models/product_listing_model.dart';
import '../../domain/repositories/product_listing_request.dart';

abstract class ProductListingRemoteDataSource {
  /// GET /api/product-listings?platform={platform}&page={page}&size={size}
  /// Returns ProductListingPageModel with content array (paginated list)
  Future<ProductListingPageModel> getByPlatform(
    String platform, {
    required int page,
    required int size,
  });

  /// GET /api/product-listings/{id}
  Future<ProductListingModel> getById(int id);

  /// GET /api/product-listings-options?listingId={listingId}
  /// Returns option list for a given product listing (옵션/마진 정보)
  Future<List<ProductListingOptionModel>> getOptions(int listingId);

  /// POST /api/product-listings (Admin only)
  Future<ProductListingModel> create(CreateProductListingRequest request);

  /// PATCH /api/product-listings/{id} (Admin only)
  Future<ProductListingModel> update(int id, UpdateProductListingRequest request);

  /// DELETE /api/product-listings/{id} (Admin only)
  Future<void> delete(int id);

  /// GET /api/admin/seller - Fetch seller list
  Future<List<dynamic>> getSellers();

  /// GET /api/admin/category - Fetch category list
  Future<List<dynamic>> getCategories();

  /// GET /api/admin/carrier-rate - Fetch carrier rate list
  Future<List<dynamic>> getCarrierRates();

  /// GET /api/admin/package - Fetch package list
  Future<List<dynamic>> getPackages();

  /// GET /api/admin/commission-rate - Fetch commission rate list
  Future<List<dynamic>> getCommissionRates();

  /// GET /api/products - Fetch product list (with pagination)
  Future<dynamic> getProducts({int page = 0, int size = 50});

  /// GET /api/products?search={query} - Search products by name
  Future<dynamic> searchProducts({required String query, int page = 0, int size = 50});
}

class ProductListingRemoteDataSourceImpl implements ProductListingRemoteDataSource {
  final Dio dio;

  ProductListingRemoteDataSourceImpl({required this.dio});

  @override
  Future<ProductListingPageModel> getByPlatform(
    String platform, {
    required int page,
    required int size,
  }) async {
    try {
      final response = await dio.get(
        '/api/product-listings',
        queryParameters: {
          'platform': platform,
          'page': page,
          'size': size,
        },
      );
      // Backend returns ResponseDTO<Page<ProductListingResponse>>
      // response.data = { status: SUCCESS, data: { content: [...], totalPages: X, ... } }
      // Unwrap inner 'data' object to get Page structure.
      // 결과가 없을 때 백엔드가 data: null 을 내려줄 수 있어 빈 페이지로 처리한다.
      final data = response.data['data'];
      if (data is! Map<String, dynamic>) {
        return ProductListingPageModel(
          content: [],
          totalPages: 0,
          totalElements: 0,
        );
      }
      return ProductListingPageModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch product listings');
    }
  }

  @override
  Future<ProductListingModel> getById(int id) async {
    try {
      final response = await dio.get('/api/product-listings/$id');
      // Unwrap ResponseDTO wrapper: response.data['data'] = ProductListingResponse object
      return ProductListingModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('ProductListing not found');
      }
      throw Exception(e.message ?? 'Failed to fetch product listing');
    }
  }

  @override
  Future<List<ProductListingOptionModel>> getOptions(int listingId) async {
    try {
      final response = await dio.get(
        '/api/product-listings-options',
        queryParameters: {'listingId': listingId},
      );
      // Backend returns ResponseDTO<List<ProductListingOptionResponse>>
      // response.data = { success: true, data: [ {...}, ... ] }
      final data = response.data['data'];
      if (data is! List) return [];
      return data
          .map((e) => ProductListingOptionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch product listing options');
    }
  }

  @override
  Future<ProductListingModel> create(CreateProductListingRequest request) async {
    try {
      final response = await dio.post(
        '/api/product-listings',
        data: _listingBody(
          sellerId: request.sellerId,
          platform: request.platform,
          platformProductId: request.platformProductId,
          name: request.name,
          categoryId: request.categoryId,
          carrierId: request.carrierId,
          packageId: request.packageId,
          options: request.options,
        ),
      );
      return _parseListing(response, 'Failed to create product listing');
    } on DioException catch (e) {
      throw Exception(_dioErrorMessage(e, 'Failed to create product listing'));
    }
  }

  @override
  Future<ProductListingModel> update(
    int id,
    UpdateProductListingRequest request,
  ) async {
    try {
      final response = await dio.patch(
        '/api/product-listings/$id',
        data: _listingBody(
          sellerId: request.sellerId,
          platform: request.platform,
          platformProductId: request.platformProductId,
          name: request.name,
          categoryId: request.categoryId,
          carrierId: request.carrierId,
          packageId: request.packageId,
          options: request.options,
        ),
      );
      return _parseListing(response, 'Failed to update product listing');
    } on DioException catch (e) {
      throw Exception(_dioErrorMessage(e, 'Failed to update product listing'));
    }
  }

  // 백엔드 CreateProductListingRequest 계약에 맞춘 요청 body.
  // ⚠️ 택배비는 백엔드에서 `deliveryId`로 받는다 (carrierId 아님 - 프론트와 동일).
  // ⚠️ options(및 중첩 products)를 반드시 직렬화해야 한다 (누락 시 "Options cannot be empty").
  // ID들은 String이므로 숫자(Long)로 변환해 전송한다.
  Map<String, dynamic> _listingBody({
    required String? sellerId,
    required String platform,
    required String platformProductId,
    required String name,
    required String? categoryId,
    required String? carrierId,
    required String? packageId,
    required List<CreateProductListingOptionRequest>? options,
  }) {
    return {
      'sellerId': _toInt(sellerId),
      'platform': platform,
      'platformProductId': platformProductId,
      'name': name,
      'categoryId': _toInt(categoryId),
      'deliveryId': _toInt(carrierId),
      'packageId': _toInt(packageId),
      'options': options
          ?.map((o) => {
                'optionName': o.optionName,
                'sellingPrice': o.sellingPrice,
                if (o.platformOptionId != null)
                  'platformOptionId': o.platformOptionId,
                'products': o.products
                    ?.map((p) => {
                          'productId': p.productId,
                          'quantity': p.quantity,
                        })
                    .toList(),
              })
          .toList(),
    };
  }

  int? _toInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  // 응답을 파싱하되, 일부 환경에서 비-2xx 응답이 예외를 던지지 않고
  // data: null로 내려오는 경우(서버 검증 실패)를 안전하게 처리한다.
  ProductListingModel _parseListing(Response response, String fallback) {
    final body = response.data;
    final data = body is Map ? body['data'] : null;
    if (data == null) {
      final message = body is Map ? body['message'] : null;
      throw Exception(message?.toString() ?? fallback);
    }
    return ProductListingModel.fromJson(data as Map<String, dynamic>);
  }

  String _dioErrorMessage(DioException e, String fallback) {
    final body = e.response?.data;
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    return e.message ?? fallback;
  }

  @override
  Future<void> delete(int id) async {
    try {
      await dio.delete('/api/product-listings/$id');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to delete product listing');
    }
  }

  @override
  Future<List<dynamic>> getSellers() async {
    try {
      final response = await dio.get('/api/admin/seller');
      final data = response.data['data'];
      if (data == null) return [];
      if (data is! List) return [];
      return data;
    } on DioException {
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await dio.get('/api/admin/category');
      final data = response.data['data'];
      if (data == null) return [];
      if (data is! List) return [];
      return data;
    } on DioException {
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<dynamic>> getCarrierRates() async {
    try {
      final response = await dio.get('/api/admin/carrier-rate');
      final data = response.data['data'];
      if (data == null) return [];
      if (data is! List) return [];
      return data;
    } on DioException {
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<dynamic>> getPackages() async {
    try {
      final response = await dio.get('/api/admin/package');
      final data = response.data['data'];
      if (data == null) return [];
      if (data is! List) return [];
      return data;
    } on DioException {
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<dynamic>> getCommissionRates() async {
    try {
      final response = await dio.get('/api/admin/commission-rate');
      final data = response.data['data'];
      if (data == null) return [];
      if (data is! List) return [];
      return data;
    } on DioException {
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<dynamic> getProducts({int page = 0, int size = 50}) async {
    try {
      final response = await dio.get(
        '/api/products',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );
      final data = response.data['data'];
      if (data is Map && data['content'] is List) {
        return data;
      }
      return data;
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch products');
    }
  }

  @override
  Future<dynamic> searchProducts({required String query, int page = 0, int size = 50}) async {
    try {
      final response = await dio.get(
        '/api/products',
        queryParameters: {
          'search': query,
          'page': page,
          'size': size,
        },
      );
      final data = response.data['data'];
      if (data is Map && data['content'] is List) {
        return data;
      }
      return data;
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to search products');
    }
  }
}
