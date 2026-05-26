import 'package:flutter_bloc/flutter_bloc.dart';

/// 카테고리 관련 이벤트를 브로드캐스트하는 EventBus 역할의 BLoC
/// ListBloc과 DetailBloc 간의 상태 동기화를 위해 사용
sealed class CategoryEvent {}

final class CategoryDeleted extends CategoryEvent {
  final int categoryId;
  CategoryDeleted(this.categoryId);
}

final class CategoryUpdated extends CategoryEvent {
  final int categoryId;
  CategoryUpdated(this.categoryId);
}

sealed class CategoryEventState {}

final class CategoryEventInitial extends CategoryEventState {}

/// 카테고리 삭제 이벤트 브로드캐스트 상태
final class CategoryDeletedEventBroadcasted extends CategoryEventState {
  final int categoryId;
  CategoryDeletedEventBroadcasted(this.categoryId);
}

/// 카테고리 수정 이벤트 브로드캐스트 상태
final class CategoryUpdatedEventBroadcasted extends CategoryEventState {
  final int categoryId;
  CategoryUpdatedEventBroadcasted(this.categoryId);
}

/// EventBus 역할을 하는BLoC
/// 이벤트를 받으면 해당 상태를 emit하여 stream을 통해 브로드캐스트
class CategoryEventBloc extends Bloc<CategoryEvent, CategoryEventState> {
  CategoryEventBloc() : super(CategoryEventInitial()) {
    on<CategoryDeleted>(_onCategoryDeleted);
    on<CategoryUpdated>(_onCategoryUpdated);
  }

  Future<void> _onCategoryDeleted(
    CategoryDeleted event,
    Emitter<CategoryEventState> emit,
  ) async {
    emit(CategoryDeletedEventBroadcasted(event.categoryId));
  }

  Future<void> _onCategoryUpdated(
    CategoryUpdated event,
    Emitter<CategoryEventState> emit,
  ) async {
    emit(CategoryUpdatedEventBroadcasted(event.categoryId));
  }
}
