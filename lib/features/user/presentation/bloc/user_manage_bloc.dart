import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/features/user/domain/entities/get_users_params.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/usecases/get_users_usecase.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_manage_event.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_manage_state.dart';

class UserManageBloc extends Bloc<UserManageEvent, UserManageState> {
  final GetUsersUseCase getUsersUseCase;

  String? lastSearchName;
  String? lastSearchEmail;

  UserManageBloc({required this.getUsersUseCase})
      : super(const UserManageInitial()) {
    on<LoadUsersRequested>(_onLoadUsersRequested);
    on<UserSearchRequested>(_onUserSearchRequested);
    on<UserPageChanged>(_onUserPageChanged);
  }

  Future<void> _fetchUsers(
    String? name,
    String? email,
    int page,
    Emitter<UserManageState> emit,
  ) async {
    emit(const UserManageLoading());
    final params = GetUsersParams(
      name: name,
      email: email,
      page: page,
      size: 20,
    );
    final result = await getUsersUseCase.call(params);
    result.fold(
      (failure) => emit(UserManageError(failure.message)),
      (response) => emit(
        UserManageLoaded(
          users: response.content,
          currentPage: response.number,
          totalPages: response.totalPages,
          totalElements: response.totalElements,
        ),
      ),
    );
  }

  Future<void> _onLoadUsersRequested(
    LoadUsersRequested event,
    Emitter<UserManageState> emit,
  ) async {
    lastSearchName = event.name;
    lastSearchEmail = event.email;
    await _fetchUsers(event.name, event.email, event.page, emit);
  }

  Future<void> _onUserSearchRequested(
    UserSearchRequested event,
    Emitter<UserManageState> emit,
  ) async {
    lastSearchName = event.name;
    lastSearchEmail = event.email;
    await _fetchUsers(event.name, event.email, 0, emit);
  }

  Future<void> _onUserPageChanged(
    UserPageChanged event,
    Emitter<UserManageState> emit,
  ) async {
    await _fetchUsers(lastSearchName, lastSearchEmail, event.page, emit);
  }
}
