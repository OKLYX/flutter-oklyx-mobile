import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/inquiry.dart';
import '../entities/inquiry_detail.dart';
import '../entities/inquiry_sync_result.dart';
import '../entities/inquiry_type_option.dart';

/// 고객문의 조회·동기화 계약 (FEATURE_2609_36).
///
/// ⚠️ 답변 전송(`POST /api/admin/inquiries/{id}/replies`)은 여기 없다 — 03 범위다.
abstract class InquiryRepository {
  /// 문의 목록 조회
  /// GET /api/inquiries?type=&status=&accountId=&sellerId=&from=&to=&keyword=
  ///
  /// [from]/[to] 는 'YYYY-MM-DD'. **둘 다 주거나 둘 다 생략**한다 — 하나만 주면 서버가
  /// 400 을 낸다. 둘 다 생략하면 서버 기본 창(최근 14일).
  ///
  /// ⚠️ 응답의 `replies`·`relatedOrder`·`relatedListing`·`replyCapability` 는 **항상 null**
  /// 이다(PLAN M1) — 그래서 반환 타입이 [Inquiry] 이고 [InquiryDetail] 이 아니다.
  Future<Either<Failure, List<Inquiry>>> getInquiries({
    InquiryType? type,
    InquiryStatus? status,
    int? accountId,
    int? sellerId,
    String? from,
    String? to,
    String? keyword,
  });

  /// 문의 단건 조회
  /// GET /api/inquiries/{id}
  ///
  /// 🔴 상세 화면은 진입할 때 **반드시** 이 메서드를 부른다(M1) — 스레드·관련 주문·답변
  /// 가능 여부는 단건 조회에서만 채워지므로 목록 항목만으로 상세를 그리면 영원히 빈 화면이다.
  Future<Either<Failure, InquiryDetail>> getInquiry(int id);

  /// 지원 문의 유형 조회
  /// GET /api/inquiries/types
  ///
  /// 유형 탭의 유일한 원천이다(M2). 실패하면 화면은 탭 없이 전체 유형으로 조회한다.
  Future<Either<Failure, List<PlatformInquiryTypes>>> getTypes();

  /// 문의만 다시 가져오기
  /// POST /api/inquiries/sync?accountId=
  ///
  /// 채널 **1개**분이다 — 여러 채널 순회는 화면(BLoC)이 한다(M4).
  Future<Either<Failure, InquirySyncResult>> syncInquiries(int accountId);
}
