import 'package:dio/dio.dart';
import '../../domain/entities/alert_feed_item.dart';
import '../models/alert_feed_item_model.dart';
import '../models/alert_summary_model.dart';

/// 알림 Dio 데이터소스 — 배지 카운트(FEATURE_2609_49 / D9) + 목록(FEATURE_2609_51).
///
/// ⚠️ 응답 봉투는 `ResponseDTO` 라 항상 `response.data['data']` 를 읽는다.
abstract class AlertRemoteDataSource {
  /// GET /api/alerts/summary — 마켓을 치지 않고 로컬 DB 만 센다(짧은 주기 호출 안전).
  Future<AlertSummaryModel> getSummary();

  /// GET /api/alerts — 처리해야 할 일 한 장(최신순 + 다음 커서).
  ///
  /// 🔴 [cursor] 는 **불투명 문자열**이다 — 직전 응답의 `nextCursor` 를 그대로 돌려보낸다.
  Future<AlertFeedPageModel> getFeed({
    AlertType? type,
    String? cursor,
    int size = 50,
  });
}

class AlertRemoteDataSourceImpl implements AlertRemoteDataSource {
  final Dio dio;

  AlertRemoteDataSourceImpl({required this.dio});

  @override
  Future<AlertSummaryModel> getSummary() async {
    final response = await dio.get('/api/alerts/summary');
    final data = response.data['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Failed to fetch alert summary');
    }
    return AlertSummaryModel.fromJson(data);
  }

  @override
  Future<AlertFeedPageModel> getFeed({
    AlertType? type,
    String? cursor,
    int size = 50,
  }) async {
    // null 파라미터는 키째 뺀다 — 빈 값을 보내면 서버가 400 을 낸다.
    final query = <String, dynamic>{'size': size};
    if (type != null) query['type'] = type.wireValue;
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;

    final response = await dio.get('/api/alerts', queryParameters: query);
    final data = response.data['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Failed to fetch alerts');
    }
    return AlertFeedPageModel.fromJson(data);
  }
}
