import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/purchase_place_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/purchase_place_state.dart';

/// 물품의 구매처 체크 목록 (FEATURE_2609_76 / D1 · D5) — 웹 `PurchasePlaceCheckboxes` 와 같은 동작.
///
/// **용도**: 물품 등록·수정에서 구매처를 **여러 개** 고른다.
/// **파일**: lib/features/product/presentation/widgets/purchase_place_checkboxes.dart
/// **쓰는 곳**: `ProductRegisterPage` · `ProductDetailPage`(수정 모드) — 물품 구매처 입력은 이 위젯 하나다.
///
/// **사용 예제**:
/// ```dart
/// PurchasePlaceCheckboxes(
///   bloc: _purchasePlaceBloc,
///   selectedIds: _selectedPlaceIds,
///   onChanged: (ids) => setState(() => _selectedPlaceIds = ids),
/// )
/// ```
///
/// ⚠️ 이름표는 「구매처」 하나다(D8). 「판매처」「상점」 금지.
/// ❌ 자유 입력 칸으로 되돌리지 말 것 — 목록 밖 값을 만드는 통로였다(D5).
/// ❌ 여기서 구매처를 추가하지 않는다 — 추가는 웹 설정 화면에서만(D14).
class PurchasePlaceCheckboxes extends StatelessWidget {
  final PurchasePlaceBloc bloc;
  final List<int> selectedIds;
  final ValueChanged<List<int>> onChanged;

  const PurchasePlaceCheckboxes({
    super.key,
    required this.bloc,
    required this.selectedIds,
    required this.onChanged,
  });

  void _toggle(int id) {
    onChanged(
      selectedIds.contains(id)
          ? selectedIds.where((selected) => selected != id).toList()
          : [...selectedIds, id],
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('구매처', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          BlocBuilder<PurchasePlaceBloc, PurchasePlaceState>(
            bloc: bloc,
            builder: (context, state) {
              if (state is PurchasePlaceError) {
                return Text(
                  state.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                );
              }
              if (state is! PurchasePlaceLoaded) {
                return const Text('구매처를 불러오는 중…');
              }
              if (state.places.isEmpty) {
                return const Text('등록된 구매처가 없습니다. 웹 설정 > 구매처 관리에서 추가하세요.');
              }
              return Column(
                children: state.places
                    .map(
                      (place) => CheckboxListTile(
                        value: selectedIds.contains(place.id),
                        onChanged: (_) => _toggle(place.id),
                        title: Text(place.name),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      );
}
