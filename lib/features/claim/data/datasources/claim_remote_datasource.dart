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
  ///
  /// 액션 실행 뒤 상세를 다시 그리는 유일한 경로다(D8) — 낙관적 갱신을 하지 않으므로
  /// `availableActions` 는 서버가 다시 판정한 값이어야 한다.
  Future<ClaimModel> getClaim(int id);

  /// POST /api/admin/claims/{claimId}/actions
  ///
  /// ⚠️ 조회는 `/api/claims`(인증만), 액션은 `/api/admin/claims`(ADMIN) 이다 — 경로가 다르다.
  ///
  /// 🔴 다른 메서드와 달리 [DioException] 을 **그대로 던진다.** 상태 코드(409≠400)와 502 의
  /// 쿠팡 원문이 화면 분기의 근거인데, `Exception(e.message)` 로 감싸면 둘 다 사라진다.
  Future<ClaimActionResultModel> executeAction(int claimId, Map<String, dynamic> body);
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

  @override
  Future<ClaimActionResultModel> executeAction(
    int claimId,
    Map<String, dynamic> body,
  ) async {
    // 쿠팡 왕복이지만 타임아웃·재시도는 기존 Dio 설정 그대로 둔다 — 되돌릴 수 없는 쓰기에
    // 액션 전용 retry 를 붙이면 중복 전송이 된다.
    final response = await dio.post('/api/admin/claims/$claimId/actions', data: body);
    final data = response.data['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Failed to execute claim action');
    }
    return ClaimActionResultModel.fromJson(data);
  }
}
