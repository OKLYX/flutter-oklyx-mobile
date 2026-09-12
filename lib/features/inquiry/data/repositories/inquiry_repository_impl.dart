import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/entities/inquiry.dart';
import '../../domain/entities/inquiry_detail.dart';
import '../../domain/entities/inquiry_sync_result.dart';
import '../../domain/entities/inquiry_type_option.dart';
import '../../domain/repositories/inquiry_repository.dart';
import '../datasources/inquiry_remote_datasource.dart';

/// 고객문의 Repository 구현 — 예외를 [Failure] 로 바꾸는 유일한 자리.
///
/// 🔴 **`statusCode` 를 반드시 실어 보낸다**(`order_repository_impl` 과 같은 이유) —
/// 03 의 답변 전송이 403(ADMIN 아님)·502(결과 미상)·400(검증 실패)을 이 값으로만 구분한다.
/// 여기서 버리면 03 이 리포지토리를 다시 고쳐야 한다.
class InquiryRepositoryImpl implements InquiryRepository {
  final InquiryRemoteDataSource remoteDataSource;

  InquiryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Inquiry>>> getInquiries({
    InquiryType? type,
    InquiryStatus? status,
    int? accountId,
    int? sellerId,
    String? from,
    String? to,
    String? keyword,
  }) async {
    try {
      // enum → 와이어 값 변환은 여기 한 곳뿐이다(화면·BLoC 은 enum 만 다룬다).
      final inquiries = await remoteDataSource.getInquiries(
        type: type?.wire,
        status: status?.wire,
        accountId: accountId,
        sellerId: sellerId,
        from: from,
        to: to,
        keyword: keyword,
      );
      return Right(inquiries.cast<Inquiry>());
    } on DioException catch (e) {
      return Left(_toFailure(e, '고객문의 조회에 실패했습니다.'));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InquiryDetail>> getInquiry(int id) async {
    try {
      return Right(await remoteDataSource.getInquiry(id));
    } on DioException catch (e) {
      return Left(_toFailure(e, '문의 조회에 실패했습니다.'));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PlatformInquiryTypes>>> getTypes() async {
    try {
      final types = await remoteDataSource.getTypes();
      return Right(types.cast<PlatformInquiryTypes>());
    } on DioException catch (e) {
      return Left(_toFailure(e, '문의 유형 조회에 실패했습니다.'));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InquirySyncResult>> syncInquiries(
    int accountId,
  ) async {
    try {
      return Right(await remoteDataSource.syncInquiries(accountId));
    } on DioException catch (e) {
      return Left(_toFailure(e, '문의 가져오기에 실패했습니다.'));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// [DioException] → [ServerFailure].
  ///
  /// 사유 문구는 **서버 봉투의 `message` 를 먼저** 쓴다 — 채널별 동기화 실패를 그대로
  /// 보여줘야 하는데(앱이 지어내지 않는다) Dio 의 `message` 는 'Http status error [400]'
  /// 같은 내용이라 사용자에게 아무 정보가 없다.
  ServerFailure _toFailure(DioException e, String fallback) {
    final body = e.response?.data;
    final envelope = body is Map ? body : const {};
    final serverMessage = envelope['message'];
    final message = (serverMessage is String && serverMessage.isNotEmpty)
        ? serverMessage
        : (e.message ?? fallback);
    return ServerFailure(message, statusCode: e.response?.statusCode);
  }
}
