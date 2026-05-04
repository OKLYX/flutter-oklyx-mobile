import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/check_barcode_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/register_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_register_event.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_register_state.dart';

class ProductRegisterBloc extends Bloc<ProductRegisterEvent, ProductRegisterState> {
  final RegisterProductUseCase registerProductUseCase;
  final CheckBarcodeUseCase checkBarcodeUseCase;

  ProductRegisterBloc({
    required this.registerProductUseCase,
    required this.checkBarcodeUseCase,
  }) : super(ProductRegisterInitial()) {
    on<CheckBarcodeRequested>(_onCheckBarcode);
    on<RegisterProductRequested>(_onRegisterProduct);
  }

  Future<void> _onCheckBarcode(
    CheckBarcodeRequested event,
    Emitter<ProductRegisterState> emit,
  ) async {
    emit(BarcodeCheckLoading());
    final result = await checkBarcodeUseCase(CheckBarcodeParams(event.barcodeId));
    result.fold(
      (failure) => emit(BarcodeCheckError(failure.message)),
      (isAvailable) {
        if (isAvailable) {
          emit(BarcodeAvailable());
        } else {
          emit(BarcodeUnavailable('이미 등록된 바코드입니다'));
        }
      },
    );
  }

  Future<void> _onRegisterProduct(
    RegisterProductRequested event,
    Emitter<ProductRegisterState> emit,
  ) async {
    emit(ProductRegisterLoading());
    final params = RegisterProductParams(
      productName: event.productName,
      barcodeId: event.barcodeId,
      brand: event.brand,
      description: event.description,
      price: event.price,
      store: event.store,
      unit: event.unit,
      volumeHeight: event.volumeHeight,
      volumeLong: event.volumeLong,
      volumeShort: event.volumeShort,
      weight: event.weight,
    );

    final result = await registerProductUseCase(params);
    result.fold(
      (failure) => emit(ProductRegisterError(failure.message)),
      (product) => emit(ProductRegisterSuccess(product)),
    );
  }
}
