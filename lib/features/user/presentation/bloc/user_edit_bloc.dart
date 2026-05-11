import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/features/user/domain/entities/update_user_params.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/usecases/check_email_usecase.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/usecases/update_user_usecase.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_edit_event.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_edit_state.dart';

class UserEditBloc extends Bloc<UserEditEvent, UserEditState> {
  final CheckEmailUseCase checkEmailUseCase;
  final UpdateUserUseCase updateUserUseCase;

  String? originalEmail;

  UserEditBloc({
    required this.checkEmailUseCase,
    required this.updateUserUseCase,
  }) : super(const UserEditInitial()) {
    on<UserEditInitialized>(_onUserEditInitialized);
    on<EmailCheckRequested>(_onEmailCheckRequested);
    on<UserUpdateRequested>(_onUserUpdateRequested);
  }

  Future<void> _onUserEditInitialized(
    UserEditInitialized event,
    Emitter<UserEditState> emit,
  ) async {
    originalEmail = event.user.email;
    emit(UserEditLoaded(event.user));
  }

  Future<void> _onEmailCheckRequested(
    EmailCheckRequested event,
    Emitter<UserEditState> emit,
  ) async {
    // Skip check if email unchanged
    if (event.email == event.originalEmail) {
      emit(EmailAvailable());
      return;
    }

    emit(EmailChecking());
    final result = await checkEmailUseCase.call(event.email);
    result.fold(
      (failure) => emit(EmailDuplicate('이미 사용 중인 이메일입니다')),
      (isAvailable) => emit(
        isAvailable ? EmailAvailable() : EmailDuplicate('이미 사용 중인 이메일입니다'),
      ),
    );
  }

  Future<void> _onUserUpdateRequested(
    UserUpdateRequested event,
    Emitter<UserEditState> emit,
  ) async {
    emit(UserUpdating());
    final params = UpdateUserParams(
      id: event.id,
      name: event.name,
      email: event.email,
      password: event.password,
      role: event.role,
    );
    final result = await updateUserUseCase.call(params);
    result.fold(
      (failure) => emit(UserEditError(failure.message)),
      (user) => emit(UserUpdateSuccess(user)),
    );
  }
}
