import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/update_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/delete_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/upload_product_image_usecase.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/delete_product_image_usecase.dart';
import 'product_detail_event.dart';
import 'product_detail_state.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  final GetProductDetailUseCase getProductDetailUseCase;
  final UpdateProductUseCase updateProductUseCase;
  final DeleteProductUseCase deleteProductUseCase;
  final UploadProductImageUseCase uploadProductImageUseCase;
  final DeleteProductImageUseCase deleteProductImageUseCase;

  ProductDetailBloc({
    required this.getProductDetailUseCase,
    required this.updateProductUseCase,
    required this.deleteProductUseCase,
    required this.uploadProductImageUseCase,
    required this.deleteProductImageUseCase,
  }) : super(const ProductDetailInitial()) {
    on<LoadProductDetail>(_onLoadProductDetail);
    on<RetryLoadProductDetail>(_onLoadProductDetail);
    on<EditModeToggled>(_onEditModeToggled);
    on<UpdateProductRequested>(_onUpdateProduct);
    on<DeleteProductRequested>(_onDeleteProduct);
    on<UploadImageRequested>(_onUploadImage);
    on<DeleteImageRequested>(_onDeleteImage);
  }

  Future<void> _onLoadProductDetail(
    ProductDetailEvent event,
    Emitter<ProductDetailState> emit,
  ) async {
    final productId = event is LoadProductDetail
        ? event.productId
        : (event as RetryLoadProductDetail).productId;

    emit(const ProductDetailLoading());

    final result = await getProductDetailUseCase(
      GetProductDetailParams(productId),
    );

    result.fold(
      (failure) => emit(ProductDetailError(message: failure.message)),
      (product) => emit(ProductDetailLoaded(product: product)),
    );
  }

  Future<void> _onEditModeToggled(
    EditModeToggled event,
    Emitter<ProductDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProductDetailLoaded) {
      emit(ProductDetailEditing(product: currentState.product));
    } else if (currentState is ProductDetailEditing) {
      emit(ProductDetailLoaded(product: currentState.product));
    }
  }

  Future<void> _onUpdateProduct(
    UpdateProductRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProductDetailEditing && currentState is! ProductDetailLoaded) {
      return;
    }

    final product = currentState is ProductDetailEditing
        ? currentState.product
        : (currentState as ProductDetailLoaded).product;

    emit(const ProductDetailUpdating());

    final params = UpdateProductParams(
      productId: product.id,
      productName: event.productName,
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

    final result = await updateProductUseCase(params);
    result.fold(
      (failure) => emit(ProductDetailEditing(
        product: product,
        errorMessage: failure.message,
      )),
      (updatedProduct) => emit(ProductDetailLoaded(product: updatedProduct)),
    );
  }

  Future<void> _onDeleteProduct(
    DeleteProductRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProductDetailLoaded && currentState is! ProductDetailEditing) {
      return;
    }

    final product = currentState is ProductDetailEditing
        ? currentState.product
        : (currentState as ProductDetailLoaded).product;

    emit(const ProductDetailDeleting());

    final result = await deleteProductUseCase(DeleteProductParams(product.id));

    result.fold(
      (failure) => emit(ProductDetailDeleteError(message: failure.message)),
      (_) => emit(const ProductDetailDeleteSuccess()),
    );
  }

  Future<void> _onUploadImage(
    UploadImageRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProductDetailLoaded && currentState is! ProductDetailEditing) {
      return;
    }

    final product = currentState is ProductDetailEditing
        ? currentState.product
        : (currentState as ProductDetailLoaded).product;

    emit(const ProductDetailImageUploading());

    final params = UploadProductImageParams(
      productId: product.id,
      imageFile: event.imageFile,
    );

    final result = await uploadProductImageUseCase(params);

    if (result.isLeft()) {
      final failure = result.fold((f) => f, (r) => null)!;
      emit(ProductDetailImageError(
        message: failure.message,
        product: product,
      ));
      emit(ProductDetailLoaded(product: product));
    } else {
      final reloadResult = await getProductDetailUseCase(
        GetProductDetailParams(product.id),
      );

      reloadResult.fold(
        (failure) => emit(ProductDetailLoaded(product: product)),
        (refreshedProduct) => emit(ProductDetailLoaded(product: refreshedProduct)),
      );
    }
  }

  Future<void> _onDeleteImage(
    DeleteImageRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProductDetailLoaded && currentState is! ProductDetailEditing) {
      return;
    }

    final product = currentState is ProductDetailEditing
        ? currentState.product
        : (currentState as ProductDetailLoaded).product;

    emit(const ProductDetailImageDeleting());

    final params = DeleteProductImageParams(productId: product.id);

    final result = await deleteProductImageUseCase(params);

    if (result.isLeft()) {
      final failure = result.fold((f) => f, (r) => null)!;
      emit(ProductDetailImageError(
        message: failure.message,
        product: product,
      ));
      emit(ProductDetailLoaded(product: product));
    } else {
      final reloadResult = await getProductDetailUseCase(
        GetProductDetailParams(product.id),
      );

      reloadResult.fold(
        (failure) => emit(ProductDetailLoaded(product: product)),
        (refreshedProduct) => emit(ProductDetailLoaded(product: refreshedProduct)),
      );
    }
  }
}
