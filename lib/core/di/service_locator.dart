import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import 'package:flutter_oklyn_mobile/core/network/dio_client.dart';
import 'package:flutter_oklyn_mobile/core/network/interceptors/request_interceptor.dart';
import 'package:flutter_oklyn_mobile/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_oklyn_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/auth/data/datasources/impl/auth_local_datasource_impl.dart';
import 'package:flutter_oklyn_mobile/features/auth/data/datasources/impl/auth_remote_datasource_impl.dart';
import 'package:flutter_oklyn_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_oklyn_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_oklyn_mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:flutter_oklyn_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_oklyn_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_oklyn_mobile/features/auth/presentation/bloc/auth_bloc.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  _registerAuthLocalServices();
  _registerNetworkServices();
  _registerAuthServices();
}

void _registerAuthLocalServices() {
  getIt.registerSingleton<AuthLocalDataSource>(
    AuthLocalDataSourceImpl(
      secureStorage: const FlutterSecureStorage(),
    ),
  );
}

void _registerNetworkServices() {
  getIt.registerSingleton<RequestInterceptor>(
    RequestInterceptor(authLocalDataSource: getIt<AuthLocalDataSource>()),
  );

  getIt.registerSingleton<DioClient>(
    DioClient(),
  );

  getIt<DioClient>().dio.interceptors.insert(
    0,
    getIt<RequestInterceptor>(),
  );
}

void _registerAuthServices() {
  // Data Sources
  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(dioClient: getIt<DioClient>()),
  );

  // Repository
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      localDataSource: getIt<AuthLocalDataSource>(),
    ),
  );

  // Use Cases
  getIt.registerSingleton<LoginUseCase>(
    LoginUseCase(getIt<AuthRepository>()),
  );
  getIt.registerSingleton<LogoutUseCase>(
    LogoutUseCase(getIt<AuthRepository>()),
  );
  getIt.registerSingleton<GetCurrentUserUseCase>(
    GetCurrentUserUseCase(getIt<AuthRepository>()),
  );

  // AuthBloc
  getIt.registerSingleton<AuthBloc>(
    AuthBloc(
      loginUseCase: getIt<LoginUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
    ),
  );
}
