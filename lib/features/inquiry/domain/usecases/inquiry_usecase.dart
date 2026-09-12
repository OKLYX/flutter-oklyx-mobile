import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/inquiry.dart';
import '../entities/inquiry_detail.dart';
import '../entities/inquiry_sync_result.dart';
import '../entities/inquiry_type_option.dart';
import '../repositories/inquiry_repository.dart';

/// 고객문의 UseCase ([ClaimUseCase] 와 동일하게 Repository 에 위임).
class InquiryUseCase {
  final InquiryRepository repository;

  InquiryUseCase({required this.repository});

  /// [from]/[to] 는 'YYYY-MM-DD'. 둘 다 주거나 둘 다 생략(서버 기본 창 = 최근 14일).
  Future<Either<Failure, List<Inquiry>>> getInquiries({
    InquiryType? type,
    InquiryStatus? status,
    int? accountId,
    int? sellerId,
    String? from,
    String? to,
    String? keyword,
  }) =>
      repository.getInquiries(
        type: type,
        status: status,
        accountId: accountId,
        sellerId: sellerId,
        from: from,
        to: to,
        keyword: keyword,
      );

  /// 상세 진입·새로고침의 유일한 경로(PLAN M1).
  Future<Either<Failure, InquiryDetail>> getInquiry(int id) =>
      repository.getInquiry(id);

  /// 유형 탭 후보. 평탄화까지 여기서 끝낸다 — 화면이 플랫폼 목록을 다루지 않는다.
  Future<Either<Failure, List<InquiryTypeOption>>> getTypeOptions() async {
    final result = await repository.getTypes();
    return result.map(flattenInquiryTypes);
  }

  /// 채널 1개의 문의만 가져온다. 순회는 호출자(BLoC)가 한다(M4).
  Future<Either<Failure, InquirySyncResult>> syncInquiries(int accountId) =>
      repository.syncInquiries(accountId);

  /// 답변 전송(ADMIN 전용). 🔴 되돌릴 수 없다(D17) — 자동 재시도를 넣지 말 것.
  Future<Either<Failure, InquiryDetail>> replyToInquiry(
    int id,
    String content,
  ) =>
      repository.replyToInquiry(id, content);
}
