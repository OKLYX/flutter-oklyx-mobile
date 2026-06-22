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
import 'package:flutter_oklyn_mobile/features/package/data/datasources/package_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/package/data/repositories/package_repository_impl.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/repositories/package_repository.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/usecases/create_package_usecase.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/usecases/get_packages_usecase.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/usecases/update_package_usecase.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/usecases/delete_package_usecase.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_create_bloc.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_detail_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/data/datasources/carrier_rate_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/data/repositories/carrier_rate_repository_impl.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/repositories/carrier_rate_repository.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/usecases/get_carrier_rates_usecase.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/usecases/get_carrier_rate_usecase.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/usecases/create_carrier_rate_usecase.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/usecases/update_carrier_rate_usecase.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/usecases/delete_carrier_rate_usecase.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/presentation/bloc/carrier_rate_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/presentation/bloc/carrier_rate_create_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/presentation/bloc/carrier_rate_detail_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/data/datasources/category_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/category/data/repositories/category_repository_impl.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/repositories/category_repository.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/usecases/create_category_usecase.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/usecases/delete_category_usecase.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/usecases/get_categories_usecase.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/usecases/get_category_usecase.dart';
import 'package:flutter_oklyn_mobile/features/category/domain/usecases/update_category_usecase.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_event_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_detail_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/create_category_bloc.dart';
import 'package:flutter_oklyn_mobile/features/commission_rate/data/datasources/commission_rate_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/commission_rate/data/datasources/impl/commission_rate_remote_datasource_impl.dart';
import 'package:flutter_oklyn_mobile/features/commission_rate/data/repositories/commission_rate_repository_impl.dart';
import 'package:flutter_oklyn_mobile/features/commission_rate/domain/repositories/commission_rate_repository.dart';
import 'package:flutter_oklyn_mobile/features/commission_rate/domain/usecases/get_commission_rates_usecase.dart';
import 'package:flutter_oklyn_mobile/features/commission_rate/domain/usecases/get_commission_rate_usecase.dart';
import 'package:flutter_oklyn_mobile/features/commission_rate/domain/usecases/create_commission_rate_usecase.dart';
import 'package:flutter_oklyn_mobile/features/commission_rate/domain/usecases/update_commission_rate_usecase.dart';
import 'package:flutter_oklyn_mobile/features/commission_rate/domain/usecases/delete_commission_rate_usecase.dart';
import 'package:flutter_oklyn_mobile/features/commission_rate/presentation/bloc/commission_rate_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/commission_rate/presentation/bloc/commission_rate_create_bloc.dart';
import 'package:flutter_oklyn_mobile/features/commission_rate/presentation/bloc/commission_rate_detail_bloc.dart';
import 'package:flutter_oklyn_mobile/features/seller/data/datasources/seller_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/seller/data/repositories/seller_repository_impl.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/repositories/seller_repository.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/create_seller_usecase.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_seller_by_id_usecase.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/update_seller_usecase.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/delete_seller_usecase.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_create_bloc.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_detail_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/data/datasources/product_listing_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/data/repositories/product_listing_repository_impl.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/domain/repositories/product_listing_repository.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/domain/usecases/product_listing_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/presentation/bloc/product_listing_create_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/presentation/bloc/product_listing_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product_listing/presentation/bloc/product_listing_detail_bloc.dart';
import 'package:flutter_oklyn_mobile/features/order/data/datasources/order_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/order/data/repositories/order_repository_impl.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/repositories/order_repository.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/usecases/order_usecase.dart';
import 'package:flutter_oklyn_mobile/features/order/presentation/bloc/order_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/data/datasources/marketplace_account_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/data/repositories/marketplace_account_repository_impl.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/repositories/marketplace_account_repository.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/usecases/get_marketplace_accounts_by_seller_usecase.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/usecases/create_marketplace_account_usecase.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/usecases/update_marketplace_account_usecase.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/usecases/delete_marketplace_account_usecase.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/presentation/bloc/marketplace_account_bloc.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/data/datasources/purchase_list_remote_datasource.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/data/repositories/purchase_list_repository_impl.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/repositories/purchase_list_repository.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/usecases/get_purchase_list_usecase.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/usecases/extract_purchase_list_usecase.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/usecases/record_purchase_usecase.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/usecases/adjust_manual_qty_usecase.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/presentation/bloc/purchase_list_bloc.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  _registerAuthLocalServices();
  _registerNetworkServices();
  _registerAuthServices();
  _registerProductServices();
  _registerStockServices();
  _registerUserServices();
  _registerCategoryServices();
  _registerPackageServices();
  _registerCarrierRateServices();
  _registerSellerServices();
  _registerMarketplaceAccountServices();
  _registerCommissionRateServices();
  _registerProductListingServices();
  _registerOrderServices();
  _registerPurchaseListServices();
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

void _registerPackageServices() {
  // Data Source
  getIt.registerSingleton<PackageRemoteDataSource>(
    PackageRemoteDataSourceImpl(dio: getIt<DioClient>().dio),
  );

  // Repository
  getIt.registerSingleton<PackageRepository>(
    PackageRepositoryImpl(remoteDataSource: getIt<PackageRemoteDataSource>()),
  );

  // Use Cases
  getIt.registerSingleton<GetPackagesUseCase>(
    GetPackagesUseCase(repository: getIt<PackageRepository>()),
  );
  getIt.registerSingleton<CreatePackageUseCase>(
    CreatePackageUseCase(repository: getIt<PackageRepository>()),
  );
  getIt.registerSingleton<UpdatePackageUseCase>(
    UpdatePackageUseCase(repository: getIt<PackageRepository>()),
  );
  getIt.registerSingleton<DeletePackageUseCase>(
    DeletePackageUseCase(repository: getIt<PackageRepository>()),
  );

  // BLoC as factory to allow fresh state per page
  getIt.registerFactory<PackageListBloc>(
    () => PackageListBloc(getPackagesUseCase: getIt<GetPackagesUseCase>()),
  );

  // PackageCreateBloc as factory to allow fresh state per dialog
  getIt.registerFactory<PackageCreateBloc>(
    () => PackageCreateBloc(createPackageUseCase: getIt<CreatePackageUseCase>()),
  );

  // PackageDetailBloc as factory to allow fresh state per page
  getIt.registerFactory<PackageDetailBloc>(
    () => PackageDetailBloc(
      getPackagesUseCase: getIt<GetPackagesUseCase>(),
      updatePackageUseCase: getIt<UpdatePackageUseCase>(),
      deletePackageUseCase: getIt<DeletePackageUseCase>(),
    ),
  );
}

void _registerCarrierRateServices() {
  // Data Source
  getIt.registerSingleton<CarrierRateRemoteDataSource>(
    CarrierRateRemoteDataSourceImpl(dio: getIt<DioClient>().dio),
  );

  // Repository
  getIt.registerSingleton<CarrierRateRepository>(
    CarrierRateRepositoryImpl(remoteDataSource: getIt<CarrierRateRemoteDataSource>()),
  );

  // Use Cases
  getIt.registerSingleton<GetCarrierRatesUseCase>(
    GetCarrierRatesUseCase(repository: getIt<CarrierRateRepository>()),
  );
  getIt.registerSingleton<GetCarrierRateUseCase>(
    GetCarrierRateUseCase(repository: getIt<CarrierRateRepository>()),
  );
  getIt.registerSingleton<CreateCarrierRateUseCase>(
    CreateCarrierRateUseCase(repository: getIt<CarrierRateRepository>()),
  );
  getIt.registerSingleton<UpdateCarrierRateUseCase>(
    UpdateCarrierRateUseCase(repository: getIt<CarrierRateRepository>()),
  );
  getIt.registerSingleton<DeleteCarrierRateUseCase>(
    DeleteCarrierRateUseCase(repository: getIt<CarrierRateRepository>()),
  );

  // BLoC as factory to allow fresh state per page
  getIt.registerFactory<CarrierRateListBloc>(
    () => CarrierRateListBloc(getCarrierRatesUseCase: getIt<GetCarrierRatesUseCase>()),
  );

  // CarrierRateCreateBloc as factory to allow fresh state per dialog
  getIt.registerFactory<CarrierRateCreateBloc>(
    () => CarrierRateCreateBloc(createCarrierRateUseCase: getIt<CreateCarrierRateUseCase>()),
  );

  // CarrierRateDetailBloc as factory to allow fresh state per dialog
  getIt.registerFactory<CarrierRateDetailBloc>(
    () => CarrierRateDetailBloc(
      getCarrierRateUseCase: getIt<GetCarrierRateUseCase>(),
      updateCarrierRateUseCase: getIt<UpdateCarrierRateUseCase>(),
      deleteCarrierRateUseCase: getIt<DeleteCarrierRateUseCase>(),
    ),
  );
}

void _registerSellerServices() {
  // Data Source
  getIt.registerSingleton<SellerRemoteDataSource>(
    SellerRemoteDataSourceImpl(dio: getIt<DioClient>().dio),
  );

  // Repository
  getIt.registerSingleton<SellerRepository>(
    SellerRepositoryImpl(remoteDataSource: getIt<SellerRemoteDataSource>()),
  );

  // Use Cases
  getIt.registerSingleton<GetSellersUseCase>(
    GetSellersUseCase(repository: getIt<SellerRepository>()),
  );
  getIt.registerSingleton<CreateSellerUseCase>(
    CreateSellerUseCase(repository: getIt<SellerRepository>()),
  );
  getIt.registerSingleton<GetSellerByIdUseCase>(
    GetSellerByIdUseCase(repository: getIt<SellerRepository>()),
  );
  getIt.registerSingleton<UpdateSellerUseCase>(
    UpdateSellerUseCase(repository: getIt<SellerRepository>()),
  );
  getIt.registerSingleton<DeleteSellerUseCase>(
    DeleteSellerUseCase(repository: getIt<SellerRepository>()),
  );

  // BLoC - SellerListBloc as singleton (shared across pages for list refresh)
  getIt.registerSingleton<SellerListBloc>(
    SellerListBloc(getSellersUseCase: getIt<GetSellersUseCase>()),
  );

  // SellerCreateBloc as factory to allow fresh state per page
  getIt.registerFactory<SellerCreateBloc>(
    () => SellerCreateBloc(createSellerUseCase: getIt<CreateSellerUseCase>()),
  );

  // SellerDetailBloc as factory to allow fresh state per page
  getIt.registerFactory<SellerDetailBloc>(
    () => SellerDetailBloc(
      getSellerByIdUseCase: getIt<GetSellerByIdUseCase>(),
      updateSellerUseCase: getIt<UpdateSellerUseCase>(),
      deleteSellerUseCase: getIt<DeleteSellerUseCase>(),
    ),
  );
}

void _registerMarketplaceAccountServices() {
  // Data Source
  getIt.registerSingleton<MarketplaceAccountRemoteDataSource>(
    MarketplaceAccountRemoteDataSourceImpl(dio: getIt<DioClient>().dio),
  );

  // Repository
  getIt.registerSingleton<MarketplaceAccountRepository>(
    MarketplaceAccountRepositoryImpl(
      remoteDataSource: getIt<MarketplaceAccountRemoteDataSource>(),
    ),
  );

  // Use Cases
  getIt.registerSingleton<GetMarketplaceAccountsBySellerUseCase>(
    GetMarketplaceAccountsBySellerUseCase(repository: getIt<MarketplaceAccountRepository>()),
  );
  getIt.registerSingleton<CreateMarketplaceAccountUseCase>(
    CreateMarketplaceAccountUseCase(repository: getIt<MarketplaceAccountRepository>()),
  );
  getIt.registerSingleton<UpdateMarketplaceAccountUseCase>(
    UpdateMarketplaceAccountUseCase(repository: getIt<MarketplaceAccountRepository>()),
  );
  getIt.registerSingleton<DeleteMarketplaceAccountUseCase>(
    DeleteMarketplaceAccountUseCase(repository: getIt<MarketplaceAccountRepository>()),
  );

  // BLoC - factoryParam(sellerId) so each expanded SellerChannelSection gets its own bloc
  getIt.registerFactoryParam<MarketplaceAccountBloc, int, void>(
    (sellerId, _) => MarketplaceAccountBloc(
      sellerId: sellerId,
      getBySellerUseCase: getIt<GetMarketplaceAccountsBySellerUseCase>(),
      createUseCase: getIt<CreateMarketplaceAccountUseCase>(),
      updateUseCase: getIt<UpdateMarketplaceAccountUseCase>(),
      deleteUseCase: getIt<DeleteMarketplaceAccountUseCase>(),
    ),
  );
}

void _registerCommissionRateServices() {
  // Data Source
  getIt.registerSingleton<CommissionRateRemoteDataSource>(
    CommissionRateRemoteDataSourceImpl(getIt<DioClient>().dio),
  );

  // Repository
  getIt.registerSingleton<CommissionRateRepository>(
    CommissionRateRepositoryImpl(
      getIt<CommissionRateRemoteDataSource>(),
      getIt<CategoryRemoteDataSource>(),
    ),
  );

  // Use Cases
  getIt.registerSingleton<GetCommissionRatesUseCase>(
    GetCommissionRatesUseCase(getIt<CommissionRateRepository>()),
  );
  getIt.registerSingleton<GetCommissionRateUseCase>(
    GetCommissionRateUseCase(getIt<CommissionRateRepository>()),
  );
  getIt.registerSingleton<CreateCommissionRateUseCase>(
    CreateCommissionRateUseCase(getIt<CommissionRateRepository>()),
  );
  getIt.registerSingleton<UpdateCommissionRateUseCase>(
    UpdateCommissionRateUseCase(getIt<CommissionRateRepository>()),
  );
  getIt.registerSingleton<DeleteCommissionRateUseCase>(
    DeleteCommissionRateUseCase(getIt<CommissionRateRepository>()),
  );

  // BLoC as factory to allow fresh state per page
  getIt.registerFactory<CommissionRateListBloc>(
    () => CommissionRateListBloc(getIt<GetCommissionRatesUseCase>()),
  );

  // CommissionRateCreateBloc as factory to allow fresh state per dialog
  getIt.registerFactory<CommissionRateCreateBloc>(
    () => CommissionRateCreateBloc(
      getIt<CreateCommissionRateUseCase>(),
      getIt<GetCategoriesUseCase>(),
    ),
  );

  // CommissionRateDetailBloc as factory to allow fresh state per page
  getIt.registerFactory<CommissionRateDetailBloc>(
    () => CommissionRateDetailBloc(
      getIt<GetCommissionRateUseCase>(),
      getIt<UpdateCommissionRateUseCase>(),
      getIt<DeleteCommissionRateUseCase>(),
      getIt<GetCategoriesUseCase>(),
    ),
  );
}

void _registerCategoryServices() {
  // Category Data Layer
  getIt.registerSingleton<CategoryRemoteDataSource>(
    CategoryRemoteDataSourceImpl(dio: getIt<DioClient>().dio),
  );

  // Category Domain Layer
  getIt.registerSingleton<CategoryRepository>(
    CategoryRepositoryImpl(remoteDataSource: getIt<CategoryRemoteDataSource>()),
  );

  // Category Use Cases
  getIt.registerSingleton<GetCategoriesUseCase>(
    GetCategoriesUseCase(repository: getIt<CategoryRepository>()),
  );

  getIt.registerSingleton<GetCategoryUseCase>(
    GetCategoryUseCase(repository: getIt<CategoryRepository>()),
  );

  getIt.registerSingleton<DeleteCategoryUseCase>(
    DeleteCategoryUseCase(repository: getIt<CategoryRepository>()),
  );

  getIt.registerSingleton<CreateCategoryUseCase>(
    CreateCategoryUseCase(repository: getIt<CategoryRepository>()),
  );

  getIt.registerSingleton<UpdateCategoryUseCase>(
    UpdateCategoryUseCase(repository: getIt<CategoryRepository>()),
  );

  // Category Event BLoC - Singleton으로 등록 (모든 category BLoC이 공유)
  getIt.registerSingleton<CategoryEventBloc>(
    CategoryEventBloc(),
  );

  // Category Presentation Layer - CategoryEventBloc 주입
  getIt.registerFactory<CategoryListBloc>(
    () => CategoryListBloc(
      getCategoriesUseCase: getIt<GetCategoriesUseCase>(),
      categoryEventBloc: getIt<CategoryEventBloc>(),
    ),
  );

  getIt.registerFactory<CategoryDetailBloc>(
    () => CategoryDetailBloc(
      getCategoryUseCase: getIt<GetCategoryUseCase>(),
      updateCategoryUseCase: getIt<UpdateCategoryUseCase>(),
      deleteCategoryUseCase: getIt<DeleteCategoryUseCase>(),
      categoryEventBloc: getIt<CategoryEventBloc>(),
    ),
  );

  getIt.registerFactory<CreateCategoryBloc>(
    () => CreateCategoryBloc(createCategoryUseCase: getIt<CreateCategoryUseCase>()),
  );
}

void _registerProductListingServices() {
  // Data Source
  getIt.registerSingleton<ProductListingRemoteDataSource>(
    ProductListingRemoteDataSourceImpl(dio: getIt<DioClient>().dio),
  );

  // Repository
  getIt.registerSingleton<ProductListingRepository>(
    ProductListingRepositoryImpl(remoteDataSource: getIt<ProductListingRemoteDataSource>()),
  );

  // Use Case
  getIt.registerSingleton<ProductListingUseCase>(
    ProductListingUseCase(repository: getIt<ProductListingRepository>()),
  );

  // BLoC as factory to allow fresh state per page
  getIt.registerFactory<ProductListingCreateBloc>(
    () => ProductListingCreateBloc(
      productListingUseCase: getIt<ProductListingUseCase>(),
    ),
  );

  getIt.registerFactory<ProductListingListBloc>(
    () => ProductListingListBloc(
      productListingUseCase: getIt<ProductListingUseCase>(),
    ),
  );

  getIt.registerFactory<ProductListingDetailBloc>(
    () => ProductListingDetailBloc(
      productListingUseCase: getIt<ProductListingUseCase>(),
    ),
  );
}

void _registerOrderServices() {
  // Data Source
  getIt.registerSingleton<OrderRemoteDataSource>(
    OrderRemoteDataSourceImpl(dio: getIt<DioClient>().dio),
  );

  // Repository
  getIt.registerSingleton<OrderRepository>(
    OrderRepositoryImpl(remoteDataSource: getIt<OrderRemoteDataSource>()),
  );

  // Use Case
  getIt.registerSingleton<OrderUseCase>(
    OrderUseCase(repository: getIt<OrderRepository>()),
  );

  // BLoC as factory to allow fresh state per page.
  // 판매자 드롭다운은 기존 seller 기능의 GetSellersUseCase 를 재사용한다.
  getIt.registerFactory<OrderListBloc>(
    () => OrderListBloc(
      orderUseCase: getIt<OrderUseCase>(),
      getSellersUseCase: getIt<GetSellersUseCase>(),
    ),
  );
}

void _registerPurchaseListServices() {
  // Data Source
  getIt.registerSingleton<PurchaseListRemoteDataSource>(
    PurchaseListRemoteDataSourceImpl(dio: getIt<DioClient>().dio),
  );

  // Repository
  getIt.registerSingleton<PurchaseListRepository>(
    PurchaseListRepositoryImpl(
      remoteDataSource: getIt<PurchaseListRemoteDataSource>(),
    ),
  );

  // Use Cases
  getIt.registerSingleton<GetPurchaseListUseCase>(
    GetPurchaseListUseCase(repository: getIt<PurchaseListRepository>()),
  );
  getIt.registerSingleton<ExtractPurchaseListUseCase>(
    ExtractPurchaseListUseCase(repository: getIt<PurchaseListRepository>()),
  );
  getIt.registerSingleton<RecordPurchaseUseCase>(
    RecordPurchaseUseCase(repository: getIt<PurchaseListRepository>()),
  );
  getIt.registerSingleton<AdjustManualQtyUseCase>(
    AdjustManualQtyUseCase(repository: getIt<PurchaseListRepository>()),
  );

  // BLoC as factory to allow fresh state per page.
  // 판매자 드롭다운은 기존 seller 기능의 GetSellersUseCase 를 재사용한다.
  getIt.registerFactory<PurchaseListBloc>(
    () => PurchaseListBloc(
      getPurchaseListUseCase: getIt<GetPurchaseListUseCase>(),
      extractPurchaseListUseCase: getIt<ExtractPurchaseListUseCase>(),
      recordPurchaseUseCase: getIt<RecordPurchaseUseCase>(),
      adjustManualQtyUseCase: getIt<AdjustManualQtyUseCase>(),
      getSellersUseCase: getIt<GetSellersUseCase>(),
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
