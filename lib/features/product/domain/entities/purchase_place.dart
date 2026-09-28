import 'package:equatable/equatable.dart';

/// 구매처 = 업체 공용 구매처 목록의 한 줄 (FEATURE_2609_76 / D2).
///
/// 물품은 구매처를 이름이 아니라 id 로 가진다(D3) — 이름은 서버가 늘 현재 이름으로 내려준다.
/// 목록은 웹 「설정 > 구매처 관리」에서만 바꾼다(D14). 모바일은 읽고 체크만 한다.
class PurchasePlace extends Equatable {
  final int id;
  final String name;

  const PurchasePlace({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
