import 'package:dio/dio.dart';
import '../models/inquiry_detail_model.dart';
import '../models/inquiry_model.dart';
import '../models/inquiry_sync_result_model.dart';
import '../models/inquiry_type_option_model.dart';

/// 고객문의 Dio 데이터소스 (FEATURE_2609_36).
///
/// ⚠️ 응답 봉투는 `ResponseDTO` 라 항상 `response.data['data']` 를 읽는다.
/// ⚠️ null 파라미터를 쿼리에 넣지 말 것 — `{'from': null}` 은 `?from=` 이 되고 서버는 400 이다.
///
/// 🔴 [DioException] 을 **잡지 않는다**(클레임 조회 경로와 다른 점이다) — 상태 코드와 서버가
/// 준 사유 문구를 [InquiryRepository] 가 `ServerFailure(message, statusCode:)` 로 옮겨야 한다.
/// 여기서 `Exception(e.message)` 로 감싸면 403(ADMIN 아님)·400(검증 실패)을 구분할 근거가
/// 사라지고, 03 의 답변 전송이 리포지토리를 다시 고쳐야 한다.
abstract class InquiryRemoteDataSource {
  /// GET /api/inquiries?type=&status=&accountId=&sellerId=&from=&to=&keyword=
  ///
  /// [type]·[status] 는 **`.wire` 값**('PRODUCT_QNA' / 'UNANSWERED') — enum 의 `name` 을
  /// 보내지 말 것. [from]/[to] 는 'YYYY-MM-DD' 이고 **둘 다 보내거나 둘 다 생략**한다
  /// (하나만 보내면 400). 생략 = 서버 기본 창(최근 14일).
  Future<List<InquiryModel>> getInquiries({
    String? type,
    String? status,
    int? accountId,
    int? sellerId,
    String? from,
    String? to,
    String? keyword,
  });

  /// GET /api/inquiries/{id} — 스레드·관련 주문·답변 가능 여부까지 채워진 단건.
  Future<InquiryDetailModel> getInquiry(int id);

  /// GET /api/inquiries/types → 플랫폼별 지원 유형(PLAN M2).
  Future<List<PlatformInquiryTypesModel>> getTypes();

  /// POST /api/inquiries/sync?accountId= — 채널 1개의 문의만 가져온다.
  Future<InquirySyncResultModel> syncInquiries(int accountId);

  /// POST /api/admin/inquiries/{id}/replies  body {"content": ...}
  ///
  /// 🔴 되돌릴 수 없다(2609_23 D17) — 쿠팡에 답변 수정·삭제 API 가 없다.
  /// 응답은 **갱신된 문의 1건**(스레드·재판정된 `replyCapability` 포함)이라 전송 후 재조회가 필요 없다.
  ///
  /// ⚠️ ADMIN 전용이라 일반 사용자는 403 이다 — 오류가 아니라 **권한 신호**다(PLAN M5).
  /// ⚠️ 바디는 `content` **하나뿐**이다. `parentReplyId` 를 보내지 말 것 — 서버가 전송 직전에
  /// 자기 값을 다시 고른다(`InquiryReplyRequest` javadoc).
  Future<InquiryDetailModel> replyToInquiry(int id, String content);
}

class InquiryRemoteDataSourceImpl implements InquiryRemoteDataSource {
  final Dio dio;

  InquiryRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<InquiryModel>> getInquiries({
    String? type,
    String? status,
    int? accountId,
    int? sellerId,
    String? from,
    String? to,
    String? keyword,
  }) async {
    final params = <String, dynamic>{
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (accountId != null) 'accountId': accountId,
      if (sellerId != null) 'sellerId': sellerId,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
    };
    final response = await dio.get('/api/inquiries', queryParameters: params);
    // 결과가 없을 때 data: null 로 내려올 수 있어 빈 리스트로 처리한다.
    final data = response.data['data'];
    if (data is! List) return [];
    return data
        .map((e) => InquiryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<InquiryDetailModel> getInquiry(int id) async {
    final response = await dio.get('/api/inquiries/$id');
    final data = response.data['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Failed to fetch inquiry');
    }
    return InquiryDetailModel.fromJson(data);
  }

  @override
  Future<List<PlatformInquiryTypesModel>> getTypes() async {
    final response = await dio.get('/api/inquiries/types');
    final data = response.data['data'];
    if (data is! List) return [];
    return data
        .map((e) =>
            PlatformInquiryTypesModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<InquirySyncResultModel> syncInquiries(int accountId) async {
    // 바디가 없는 POST — 계정은 쿼리 파라미터다(서버 계약 그대로).
    final response = await dio.post(
      '/api/inquiries/sync',
      queryParameters: <String, dynamic>{'accountId': accountId},
    );
    final data = response.data['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Failed to sync inquiries');
    }
    return InquirySyncResultModel.fromJson(data);
  }

  @override
  Future<InquiryDetailModel> replyToInquiry(int id, String content) async {
    final response = await dio.post(
      '/api/admin/inquiries/$id/replies',
      data: <String, dynamic>{'content': content},
    );
    final data = response.data['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Failed to send inquiry reply');
    }
    // 응답 스키마는 단건 조회와 같다 — 같은 모델로 파싱한다.
    return InquiryDetailModel.fromJson(data);
  }
}
