import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/usecases/check_email_usecase.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/usecases/create_user_usecase.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_register_event.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_register_state.dart';

class UserRegisterBloc extends Bloc<UserRegisterEvent, UserRegisterState> {
  final CheckEmailUseCase checkEmailUseCase;
  final CreateUserUseCase createUserUseCase;

  UserRegisterBloc({
    required this.checkEmailUseCase,
    required this.createUserUseCase,
  }) : super(const UserRegisterInitial()) {
    on<EmailCheckRequested>(_onEmailCheckRequested);
    on<RegisterUserRequested>(_onRegisterUserRequested);
    on<UserRegisterInitialEvent>(_onUserRegisterInitial);
  }

  Future<void> _onEmailCheckRequested(
    EmailCheckRequested event,
    Emitter<UserRegisterState> emit,
  ) async {
    emit(const EmailChecking());
    final result = await checkEmailUseCase.call(event.email);
    result.fold(
      (failure) => emit(UserRegisterError(failure.message)),
      (exists) => exists
          ? emit(const EmailDuplicate('이미 사용 중인 이메일입니다'))
          : emit(const EmailAvailable()),
    );
  }

  Future<void> _onRegisterUserRequested(
    RegisterUserRequested event,
    Emitter<UserRegisterState> emit,
  ) async {
    emit(const UserRegistering());
    final params = CreateUserParams(
      email: event.email,
      password: event.password,
      name: event.name,
    );
    final result = await createUserUseCase.call(params);
    result.fold(
      (failure) {
        if (failure is DuplicateEmailFailure) {
          emit(UserRegisterError('이미 사용 중인 이메일입니다'));
        } else {
          emit(UserRegisterError(failure.message));
        }
      },
      (user) => emit(UserRegisterSuccess(user)),
    );
  }

  Future<void> _onUserRegisterInitial(
    UserRegisterInitialEvent event,
    Emitter<UserRegisterState> emit,
  ) async {
    emit(const UserRegisterInitial());
  }
}
