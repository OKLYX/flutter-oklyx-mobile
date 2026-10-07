import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/check_barcode_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/register_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/scan_barcode_from_image_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_register_event.dart';
import 'package:flutter_oklyn_mobile/features/product/presentation/bloc/product_register_state.dart';

class ProductRegisterBloc extends Bloc<ProductRegisterEvent, ProductRegisterState> {
  final RegisterProductUseCase registerProductUseCase;
  final CheckBarcodeUseCase checkBarcodeUseCase;
  final ScanBarcodeFromImageUseCase scanBarcodeFromImageUseCase;

  ProductRegisterBloc({
    required this.registerProductUseCase,
    required this.checkBarcodeUseCase,
    required this.scanBarcodeFromImageUseCase,
  }) : super(ProductRegisterInitial()) {
    on<CheckBarcodeRequested>(_onCheckBarcode);
    on<ScanBarcodeFromImageRequested>(_onScanBarcodeFromImage);
    on<RegisterProductRequested>(_onRegisterProduct);
  }

  Future<void> _onScanBarcodeFromImage(
    ScanBarcodeFromImageRequested event,
    Emitter<ProductRegisterState> emit,
  ) async {
    emit(BarcodeScanLoading());
    final result = await scanBarcodeFromImageUseCase(
      ScanBarcodeFromImageParams(event.image),
    );
    result.fold(
      (failure) {
        // Only a server-provided message is shown; anything else uses the
        // fixed fallback so raw exception text never reaches the user.
        final serverMessage =
            failure is ServerFailure ? failure.message.trim() : '';
        emit(BarcodeScanError(
          serverMessage.isNotEmpty ? serverMessage : '이미지를 확인하지 못했습니다.',
        ));
      },
      (scan) {
        final barcode = scan.barcode?.trim() ?? '';
        if (barcode.isEmpty) {
          emit(BarcodeScanNotFound());
        } else {
          emit(BarcodeScanSuccess(barcode));
        }
      },
    );
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
      purchasePlaceIds: event.purchasePlaceIds,
      netContentUnit: event.netContentUnit,
      packageHeight: event.packageHeight,
      packageLength: event.packageLength,
      packageWidth: event.packageWidth,
      netContent: event.netContent,
      countQuantity: event.countQuantity,
      countUnit: event.countUnit,
    );

    final result = await registerProductUseCase(params);
    result.fold(
      (failure) => emit(ProductRegisterError(failure.message)),
      (product) => emit(ProductRegisterSuccess(product)),
    );
  }
}
