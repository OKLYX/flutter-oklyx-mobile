import 'package:dio/dio.dart';
import '../models/alert_summary_model.dart';

/// 알림 배지 카운트 Dio 데이터소스 (FEATURE_2609_49 / D9).
///
/// ⚠️ 응답 봉투는 `ResponseDTO` 라 항상 `response.data['data']` 를 읽는다.
abstract class AlertRemoteDataSource {
  /// GET /api/alerts/summary — 마켓을 치지 않고 로컬 DB 만 센다(짧은 주기 호출 안전).
  Future<AlertSummaryModel> getSummary();
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
}
