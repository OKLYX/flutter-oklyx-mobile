import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import 'package:flutter_oklyn_mobile/core/network/dio_client.dart';
import 'package:flutter_oklyn_mobile/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_oklyn_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/auth/data/datasources/impl/auth_local_datasource_impl.dart';
import 'package:flutter_oklyn_mobile/features/auth/data/datasources/impl/auth_remote_datasource_impl.dart';
import 'package:flutter_oklyn_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_oklyn_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_oklyn_mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:flutter_oklyn_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_oklyn_mobile/features/auth/domain/usecases/logout_usecase.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  _registerNetworkServices();
  _registerAuthServices();
}

void _registerNetworkServices() {
  getIt.registerSingleton<DioClient>(
    DioClient(),
  );
}

void _registerAuthServices() {
  // Data Sources
  getIt
    ..registerSingleton<AuthRemoteDataSource>(
      AuthRemoteDataSourceImpl(dioClient: getIt<DioClient>()),
    )
    ..registerSingleton<AuthLocalDataSource>(
      AuthLocalDataSourceImpl(
        secureStorage: const FlutterSecureStorage(),
      ),
    )
    // Repository
    ..registerSingleton<AuthRepository>(
      AuthRepositoryImpl(
        remoteDataSource: getIt<AuthRemoteDataSource>(),
        localDataSource: getIt<AuthLocalDataSource>(),
      ),
    )
    // Use Cases
    ..registerSingleton<LoginUseCase>(
      LoginUseCase(getIt<AuthRepository>()),
    )
    ..registerSingleton<LogoutUseCase>(
      LogoutUseCase(getIt<AuthRepository>()),
    )
    ..registerSingleton<GetCurrentUserUseCase>(
      GetCurrentUserUseCase(getIt<AuthRepository>()),
    );
}
