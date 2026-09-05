import 'package:dio/dio.dart';
import '../models/claim_model.dart';

abstract class ClaimRemoteDataSource {
  /// GET /api/claims?type={type}&sellerId=&status=&keyword=&from=&to=
  ///
  /// [from]/[to] 는 'YYYY-MM-DD'. 둘 다 생략하면 서버 기본 창(최근 2주).
  /// [type]·[status] 는 **`.wire` 값**('RETURN' / 'PENDING_REVIEW') — enum 의 `name` 을 보내지 말 것.
  Future<List<ClaimModel>> getClaims({
    required String type,
    int? sellerId,
    String? status,
    String? keyword,
    String? from,
    String? to,
  });

  /// GET /api/claims/{id}
  Future<ClaimModel> getClaim(int id);
}

class ClaimRemoteDataSourceImpl implements ClaimRemoteDataSource {
  final Dio dio;

  ClaimRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ClaimModel>> getClaims({
    required String type,
    int? sellerId,
    String? status,
    String? keyword,
    String? from,
    String? to,
  }) async {
    try {
      // null 은 빼고 조립한다 — {'from': null} 을 보내면 Dio 가 '?from=' 을 붙이고
      // 서버는 400 이다(order_remote_datasource 와 동일).
      final params = <String, dynamic>{
        'type': type,
        if (sellerId != null) 'sellerId': sellerId,
        if (status != null) 'status': status,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      };
      final response = await dio.get('/api/claims', queryParameters: params);
      // 백엔드 ResponseDTO 래퍼: response.data = { status, data: [...] }
      // 결과가 없을 때 data: null 로 내려올 수 있어 빈 리스트로 처리한다.
      final data = response.data['data'];
      if (data is! List) return [];
      return data
          .map((e) => ClaimModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch claims');
    }
  }

  @override
  Future<ClaimModel> getClaim(int id) async {
    try {
      final response = await dio.get('/api/claims/$id');
      final data = response.data['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Failed to fetch claim');
      }
      return ClaimModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch claim');
    }
  }
}
