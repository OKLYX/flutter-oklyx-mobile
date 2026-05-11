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
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/check_barcode_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/get_products_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/register_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/update_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/delete_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/upload_product_image_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/delete_product_image_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_detail_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_register_bloc.dart';
import 'package:flutter_oklyn_mobile/features/stock/data/datasources/stock_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/stock/data/datasources/stock_remote_datasource_impl.dart';
import 'package:flutter_oklyn_mobile/features/stock/data/repositories/stock_repository_impl.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/repositories/stock_repository.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/usecases/create_stock_usecase.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/usecases/get_stock_usecase.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/usecases/create_batch_stock_usecase.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/usecases/get_stock_logs_usecase.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/bloc/stock_bloc.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/bloc/stock_in_out_bloc/stock_in_out_bloc.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/bloc/stock_search_bloc/stock_search_bloc.dart';
import 'package:flutter_oklyn_mobile/features/user/data/datasources/user_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/user/data/repositories/user_repository_impl.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/repositories/user_repository.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/usecases/check_email_usecase.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/usecases/create_user_usecase.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/usecases/get_users_usecase.dart';
import 'package:flutter_oklyn_mobile/features/user/domain/usecases/update_user_usecase.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_register_bloc.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_manage_bloc.dart';
import 'package:flutter_oklyn_mobile/features/user/presentation/bloc/user_edit_bloc.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  _registerAuthLocalServices();
  _registerNetworkServices();
  _registerAuthServices();
  _registerProductServices();
  _registerStockServices();
  _registerUserServices();
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
  getIt.registerSingleton<RegisterProductUseCase>(
    RegisterProductUseCase(getIt<ProductRepository>()),
  );
  getIt.registerSingleton<CheckBarcodeUseCase>(
    CheckBarcodeUseCase(getIt<ProductRepository>()),
  );
  getIt.registerSingleton<UpdateProductUseCase>(
    UpdateProductUseCase(getIt<ProductRepository>()),
  );
  getIt.registerSingleton<DeleteProductUseCase>(
    DeleteProductUseCase(getIt<ProductRepository>()),
  );
  getIt.registerSingleton<UploadProductImageUseCase>(
    UploadProductImageUseCase(getIt<ProductRepository>()),
  );
  getIt.registerSingleton<DeleteProductImageUseCase>(
    DeleteProductImageUseCase(getIt<ProductRepository>()),
  );

  // ProductBloc as factory to allow fresh state per page
  getIt.registerFactory<ProductBloc>(
    () => ProductBloc(getProductsUseCase: getIt<GetProductsUseCase>()),
  );

  // ProductDetailBloc as factory to allow fresh state per page
  getIt.registerFactory<ProductDetailBloc>(
    () => ProductDetailBloc(
      getProductDetailUseCase: getIt<GetProductDetailUseCase>(),
      updateProductUseCase: getIt<UpdateProductUseCase>(),
      deleteProductUseCase: getIt<DeleteProductUseCase>(),
      uploadProductImageUseCase: getIt<UploadProductImageUseCase>(),
      deleteProductImageUseCase: getIt<DeleteProductImageUseCase>(),
    ),
  );

  // ProductRegisterBloc as factory to allow fresh state per page
  getIt.registerFactory<ProductRegisterBloc>(
    () => ProductRegisterBloc(
      registerProductUseCase: getIt<RegisterProductUseCase>(),
      checkBarcodeUseCase: getIt<CheckBarcodeUseCase>(),
    ),
  );
}

void _registerStockServices() {
  // Datasources
  getIt.registerSingleton<StockRemoteDatasource>(
    StockRemoteDatasourceImpl(getIt<DioClient>()),
  );

  // Repositories
  getIt.registerSingleton<StockRepository>(
    StockRepositoryImpl(getIt<StockRemoteDatasource>()),
  );

  // Use cases
  getIt.registerSingleton<GetStockUseCase>(
    GetStockUseCase(getIt<StockRepository>()),
  );
  getIt.registerSingleton<CreateStockUseCase>(
    CreateStockUseCase(getIt<StockRepository>()),
  );
  getIt.registerSingleton<CreateBatchStockUseCase>(
    CreateBatchStockUseCase(getIt<StockRepository>()),
  );
  getIt.registerSingleton<GetStockLogsUseCase>(
    GetStockLogsUseCase(getIt<StockRepository>()),
  );

  // BLoC — registerFactory to create fresh instance per ProductDetailPage
  getIt.registerFactory<StockBloc>(
    () => StockBloc(
      getStockUseCase: getIt<GetStockUseCase>(),
      createStockUseCase: getIt<CreateStockUseCase>(),
    ),
  );

  // StockInOutBloc as factory to allow fresh state per page
  getIt.registerFactory<StockInOutBloc>(
    () => StockInOutBloc(
      getStockUseCase: getIt<GetStockUseCase>(),
      createBatchStockUseCase: getIt<CreateBatchStockUseCase>(),
    ),
  );

  // StockSearchBloc as factory to allow fresh state per page
  getIt.registerFactory<StockSearchBloc>(
    () => StockSearchBloc(
      getStockLogsUseCase: getIt<GetStockLogsUseCase>(),
    ),
  );
}

void _registerUserServices() {
  // Data Sources
  getIt.registerSingleton<UserRemoteDataSource>(
    UserRemoteDataSourceImpl(getIt<DioClient>()),
  );

  // Repository
  getIt.registerSingleton<UserRepository>(
    UserRepositoryImpl(getIt<UserRemoteDataSource>()),
  );

  // Use Cases
  getIt.registerSingleton<CheckEmailUseCase>(
    CheckEmailUseCase(getIt<UserRepository>()),
  );
  getIt.registerSingleton<CreateUserUseCase>(
    CreateUserUseCase(getIt<UserRepository>()),
  );
  getIt.registerSingleton<GetUsersUseCase>(
    GetUsersUseCase(getIt<UserRepository>()),
  );
  getIt.registerSingleton<UpdateUserUseCase>(
    UpdateUserUseCase(getIt<UserRepository>()),
  );

  // UserRegisterBloc as factory to allow fresh state per page
  getIt.registerFactory<UserRegisterBloc>(
    () => UserRegisterBloc(
      checkEmailUseCase: getIt<CheckEmailUseCase>(),
      createUserUseCase: getIt<CreateUserUseCase>(),
    ),
  );

  // UserManageBloc as factory to allow fresh state per page
  getIt.registerFactory<UserManageBloc>(
    () => UserManageBloc(
      getUsersUseCase: getIt<GetUsersUseCase>(),
    ),
  );

  // UserEditBloc as factory to allow fresh state per page
  getIt.registerFactory<UserEditBloc>(
    () => UserEditBloc(
      checkEmailUseCase: getIt<CheckEmailUseCase>(),
      updateUserUseCase: getIt<UpdateUserUseCase>(),
    ),
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
