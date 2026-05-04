import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import 'package:flutter_oklyn_mobile/core/network/dio_client.dart';
import 'package:flutter_oklyn_mobile/core/network/interceptors/error_interceptor.dart';
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
import 'package:flutter_oklyn_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_oklyn_mobile/features/product/data/datasources/impl/product_remote_datasource_impl.dart';
import 'package:flutter_oklyn_mobile/features/product/data/datasources/product_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/product/data/repositories/product_repository_impl.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/repositories/product_repository.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/get_products_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_detail_bloc.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  _registerAuthLocalServices();
  _registerNetworkServices();
  _registerAuthServices();
  _registerProductServices();
  _registerErrorHandling();
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
      authRepository: getIt<AuthRepository>(),
    ),
  );
}

void _registerProductServices() {
  // Data Sources
  getIt.registerSingleton<ProductRemoteDataSource>(
    ProductRemoteDataSourceImpl(dioClient: getIt<DioClient>()),
  );

  // Repository
  getIt.registerSingleton<ProductRepository>(
    ProductRepositoryImpl(remoteDataSource: getIt<ProductRemoteDataSource>()),
  );

  // Use Cases
  getIt.registerSingleton<GetProductsUseCase>(
    GetProductsUseCase(getIt<ProductRepository>()),
  );
  getIt.registerSingleton<GetProductDetailUseCase>(
    GetProductDetailUseCase(getIt<ProductRepository>()),
  );

  // ProductBloc as factory to allow fresh state per page
  getIt.registerFactory<ProductBloc>(
    () => ProductBloc(getProductsUseCase: getIt<GetProductsUseCase>()),
  );

  // ProductDetailBloc as factory to allow fresh state per page
  getIt.registerFactory<ProductDetailBloc>(
    () => ProductDetailBloc(getProductDetailUseCase: getIt<GetProductDetailUseCase>()),
  );
}

void _registerErrorHandling() {
  getIt.registerSingleton<ErrorInterceptor>(
    ErrorInterceptor(
      dio: getIt<DioClient>().dio,
      authRepository: getIt<AuthRepository>(),
      onLogoutRequired: () =>
          getIt<AuthBloc>().add(const LogoutRequested()),
    ),
  );

  getIt<DioClient>().dio.interceptors.add(getIt<ErrorInterceptor>());
}
