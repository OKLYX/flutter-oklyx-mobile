import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product_image.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/product_image_usecase.dart';
import 'product_image_gallery_event.dart';
import 'product_image_gallery_state.dart';

/// Product photo gallery of a saved product (product detail screen).
///
/// Same behaviour as the web `ProductImageGallery` edit mode: every action
/// goes to the server at once, the first photo is the representative one.
/// The register screen does not use this BLoC — it keeps a file buffer and
/// uploads it after the product is created (`ProductRegisterBloc`).
class ProductImageGalleryBloc
    extends Bloc<ProductImageGalleryEvent, ProductImageGalleryState> {
  final ProductImageUseCase productImageUseCase;

  int? _productId;

  ProductImageGalleryBloc({required this.productImageUseCase})
      : super(const ProductImageGalleryState()) {
    on<ProductImagesRequested>(_onRequested);
    on<ProductImagesAdded>(_onAdded);
    on<ProductImageReplaced>(_onReplaced);
    on<ProductImageMoved>(_onMoved);
    on<ProductImageDeleted>(_onDeleted);
  }

  static List<ProductImage> _sorted(List<ProductImage> images) =>
      [...images]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  Future<void> _onRequested(
    ProductImagesRequested event,
    Emitter<ProductImageGalleryState> emit,
  ) async {
    _productId = event.productId;
    emit(state.copyWith(isLoading: true, clearLoadError: true));
    final result = await productImageUseCase.list(event.productId);
    result.fold(
      (_) => emit(state.copyWith(
        isLoading: false,
        loadError: '이미지를 불러오지 못했습니다.',
      )),
      (images) =>
          emit(state.copyWith(isLoading: false, images: _sorted(images))),
    );
  }

  Future<void> _onAdded(
    ProductImagesAdded event,
    Emitter<ProductImageGalleryState> emit,
  ) async {
    final productId = _productId;
    if (productId == null || state.busy || event.files.isEmpty) return;
    emit(state.copyWith(busy: true));
    final result = await productImageUseCase.add(productId, event.files);
    result.fold(
      (_) => emit(state.copyWith(
        busy: false,
        actionError: '이미지 업로드에 실패했습니다.',
      )),
      (images) => emit(state.copyWith(busy: false, images: _sorted(images))),
    );
  }

  Future<void> _onReplaced(
    ProductImageReplaced event,
    Emitter<ProductImageGalleryState> emit,
  ) async {
    final productId = _productId;
    if (productId == null || state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await productImageUseCase.replace(
      productId,
      event.imageId,
      event.file,
    );
    if (result.isLeft()) {
      emit(state.copyWith(busy: false, actionError: '이미지 대체에 실패했습니다.'));
      return;
    }
    await _reload(productId, emit);
  }

  Future<void> _onMoved(
    ProductImageMoved event,
    Emitter<ProductImageGalleryState> emit,
  ) async {
    final productId = _productId;
    final target = event.index + event.direction;
    if (productId == null ||
        state.busy ||
        target < 0 ||
        target >= state.images.length) {
      return;
    }
    final ids = state.images.map((image) => image.id).toList();
    final moved = ids[event.index];
    ids[event.index] = ids[target];
    ids[target] = moved;
    emit(state.copyWith(busy: true));
    final result = await productImageUseCase.reorder(productId, ids);
    result.fold(
      (_) => emit(state.copyWith(busy: false, actionError: '순서 변경에 실패했습니다.')),
      (images) => emit(state.copyWith(busy: false, images: _sorted(images))),
    );
  }

  Future<void> _onDeleted(
    ProductImageDeleted event,
    Emitter<ProductImageGalleryState> emit,
  ) async {
    final productId = _productId;
    if (productId == null || state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await productImageUseCase.remove(productId, event.imageId);
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      // 409 = the photo is placed in a master image pool; the server says where.
      final inUse = failure is ServerFailure && failure.statusCode == 409;
      final serverMessage = failure.message.trim();
      emit(state.copyWith(
        busy: false,
        actionError: inUse
            ? (serverMessage.isNotEmpty
                ? serverMessage
                : '다른 상품 리스팅에서 사용 중입니다. 마스터 풀 배치를 먼저 해제하세요.')
            : '이미지 삭제에 실패했습니다.',
      ));
      return;
    }
    await _reload(productId, emit);
  }

  /// After replace / delete — the server answers without the new list.
  Future<void> _reload(
    int productId,
    Emitter<ProductImageGalleryState> emit,
  ) async {
    final result = await productImageUseCase.list(productId);
    result.fold(
      (_) => emit(state.copyWith(
        busy: false,
        actionError: '이미지를 불러오지 못했습니다.',
      )),
      (images) => emit(state.copyWith(busy: false, images: _sorted(images))),
    );
  }
}
