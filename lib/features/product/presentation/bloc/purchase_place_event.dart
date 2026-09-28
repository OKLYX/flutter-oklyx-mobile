import 'package:equatable/equatable.dart';

sealed class PurchasePlaceEvent extends Equatable {
  const PurchasePlaceEvent();

  @override
  List<Object?> get props => [];
}

/// 구매처 목록을 불러온다 — 물품 등록·상세 화면이 열릴 때 한 번.
class PurchasePlacesRequested extends PurchasePlaceEvent {
  const PurchasePlacesRequested();
}
