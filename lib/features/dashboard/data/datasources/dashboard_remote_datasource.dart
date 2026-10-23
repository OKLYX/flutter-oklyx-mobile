import 'package:dio/dio.dart';
import 'package:flutter_oklyn_mobile/core/error/exceptions.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/data/models/dashboard_json.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/domain/entities/dashboard.dart';

/// `/api/dashboard/layout` calls (FEATURE_2610_29 / D6 · D11). USER · GUEST ·
/// ADMIN may call them.
///
/// `DioClient` passes a status below 500 through — [_ensureOk] turns a
/// non-2xx status into a [ServerException] with the envelope `message`.
class DashboardRemoteDataSource {
  final Dio dio;

  DashboardRemoteDataSource({required this.dio});

  /// GET /api/dashboard/layout.
  Future<DashboardLayout> getLayout() async {
    final response = _ensureOk(await dio.get<dynamic>('/api/dashboard/layout'));
    return dashboardLayoutFromJson(_object(response));
  }

  /// PUT /api/dashboard/layout/mobile — replaces the card list (D11).
  Future<DashboardLayout> saveMobileLayout(
      List<DashboardMobileCard> cards) async {
    final response = _ensureOk(await dio.put<dynamic>(
      '/api/dashboard/layout/mobile',
      data: <String, dynamic>{
        'cards': cards.map(dashboardMobileCardToJson).toList(),
      },
    ));
    return dashboardLayoutFromJson(_object(response));
  }

  static Json _object(Response<dynamic> response) {
    final body = response.data;
    final data = body is Map ? body['data'] : null;
    if (data is Json) {
      return data;
    }
    throw ServerException('응답 형식이 올바르지 않습니다.', statusCode: response.statusCode);
  }

  static Response<dynamic> _ensureOk(Response<dynamic> response) {
    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      return response;
    }
    final body = response.data;
    final message = body is Map && body['message'] is String
        ? body['message'] as String
        : '';
    throw ServerException(message, statusCode: code);
  }
}
