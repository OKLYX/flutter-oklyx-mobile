import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  _registerNetworkServices();
}

void _registerNetworkServices() {
  getIt.registerSingleton<DioClient>(
    DioClient(),
  );
}
