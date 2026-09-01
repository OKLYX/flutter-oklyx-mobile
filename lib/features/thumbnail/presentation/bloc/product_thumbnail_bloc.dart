import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import '../../domain/entities/product_thumbnail.dart';
import '../../domain/entities/template_field.dart';
import '../../domain/usecases/delete_thumbnail_usecase.dart';
import '../../domain/usecases/generate_thumbnail_usecase.dart';
import '../../domain/usecases/get_default_template_fields_usecase.dart';
import '../../domain/usecases/get_product_thumbnails_usecase.dart';
import '../../domain/usecases/override_thumbnail_usecase.dart';
import 'product_thumbnail_event.dart';
import 'product_thumbnail_state.dart';

/// Drives the per-seller thumbnail page (consume-only: list / generate / override
/// / delete). Template editing is web-only and intentionally absent here.
///
/// Load fetches thumbnails + sellers + default template fields in parallel; the
/// seller list reuses the cross-feature [GetSellersUseCase] (purchase_list pattern).
/// After an action, only the thumbnail list is reloaded — fields/fieldValues/
/// sellers are preserved.
class ProductThumbnailBloc
    extends Bloc<ProductThumbnailEvent, ProductThumbnailState> {
  final GetProductThumbnailsUseCase getProductThumbnailsUseCase;
  final GenerateThumbnailUseCase generateThumbnailUseCase;
  final OverrideThumbnailUseCase overrideThumbnailUseCase;
  final DeleteThumbnailUseCase deleteThumbnailUseCase;
  final GetDefaultTemplateFieldsUseCase getDefaultTemplateFieldsUseCase;
  final GetSellersUseCase getSellersUseCase;

  ProductThumbnailBloc({
    required this.getProductThumbnailsUseCase,
    required this.generateThumbnailUseCase,
    required this.overrideThumbnailUseCase,
    required this.deleteThumbnailUseCase,
    required this.getDefaultTemplateFieldsUseCase,
    required this.getSellersUseCase,
  }) : super(const ProductThumbnailInitial()) {
    on<LoadThumbnails>(_onLoad);
    on<UpdateFieldValue>(_onUpdateFieldValue);
    on<GenerateThumbnail>(_onGenerate);
    on<OverrideThumbnail>(_onOverride);
    on<DeleteThumbnail>(_onDelete);
  }

  Future<void> _onLoad(
    LoadThumbnails event,
    Emitter<ProductThumbnailState> emit,
  ) async {
    emit(const ProductThumbnailLoading());

    // Kick off all three concurrently, then await (Future.wait-style).
    final thumbFuture = getProductThumbnailsUseCase(event.productId);
    final sellersFuture = getSellersUseCase();
    final fieldsFuture = getDefaultTemplateFieldsUseCase();

    final thumbEither = await thumbFuture;
    final sellersEither = await sellersFuture;
    final fieldsEither = await fieldsFuture;

    // Thumbnails / sellers are required; a fields failure is non-fatal.
    List<ProductThumbnail>? thumbnails;
    String? loadError;
    thumbEither.fold((f) => loadError = f.message, (r) => thumbnails = r);

    List<Seller>? sellers;
    sellersEither.fold((f) => loadError ??= f.message, (r) => sellers = r);

    if (loadError != null || thumbnails == null || sellers == null) {
      emit(ProductThumbnailError(loadError ?? '썸네일 정보를 불러오지 못했습니다'));
      return;
    }

    final fields = fieldsEither.getOrElse((_) => const <TemplateField>[]);

    // Seed initial field values: reserved keys auto-fill from the product,
    // custom fields use their template default.
    final fieldValues = <String, String>{};
    for (final field in fields) {
      if (field.key == TemplateField.reservedBrandName) {
        fieldValues[field.key] = event.productBrand ?? '';
      } else if (field.key == TemplateField.reservedProductName) {
        fieldValues[field.key] = event.productName ?? '';
      } else {
        fieldValues[field.key] = field.defaultValue;
      }
    }

    emit(ProductThumbnailLoaded(
      productId: event.productId,
      thumbnails: thumbnails!,
      sellers: sellers!,
      fields: fields,
      fieldValues: fieldValues,
    ));
  }

  void _onUpdateFieldValue(
    UpdateFieldValue event,
    Emitter<ProductThumbnailState> emit,
  ) {
    final state = this.state;
    if (state is! ProductThumbnailLoaded) return;
    final updated = Map<String, String>.from(state.fieldValues)
      ..[event.key] = event.value;
    emit(state.copyWith(fieldValues: updated));
  }

  Future<void> _onGenerate(
    GenerateThumbnail event,
    Emitter<ProductThumbnailState> emit,
  ) async {
    final state = this.state;
    if (state is! ProductThumbnailLoaded) return;

    emit(state.copyWith(
      actionSellerId: event.sellerId,
      clearActionError: true,
    ));

    // Send only non-blank values; the backend applies defaults for the rest.
    final values = <String, String>{
      for (final entry in state.fieldValues.entries)
        if (entry.value.trim().isNotEmpty) entry.key: entry.value,
    };

    final result = await generateThumbnailUseCase(
      productId: state.productId,
      sellerId: event.sellerId,
      fieldValues: values,
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        clearActionSellerId: true,
        actionError: failure.message,
      )),
      (_) async => _reloadThumbnails(state, emit),
    );
  }

  Future<void> _onOverride(
    OverrideThumbnail event,
    Emitter<ProductThumbnailState> emit,
  ) async {
    final state = this.state;
    if (state is! ProductThumbnailLoaded) return;

    emit(state.copyWith(
      actionSellerId: event.sellerId,
      clearActionError: true,
    ));

    final result = await overrideThumbnailUseCase(
      productId: state.productId,
      sellerId: event.sellerId,
      file: event.file,
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        clearActionSellerId: true,
        actionError: failure.message,
      )),
      (_) async => _reloadThumbnails(state, emit),
    );
  }

  Future<void> _onDelete(
    DeleteThumbnail event,
    Emitter<ProductThumbnailState> emit,
  ) async {
    final state = this.state;
    if (state is! ProductThumbnailLoaded) return;

    emit(state.copyWith(
      actionSellerId: event.sellerId,
      clearActionError: true,
    ));

    final result = await deleteThumbnailUseCase(
      productId: state.productId,
      sellerId: event.sellerId,
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        clearActionSellerId: true,
        actionError: failure.message,
      )),
      (_) async => _reloadThumbnails(state, emit),
    );
  }

  /// After a successful action, reload only the thumbnail list; keep
  /// fields/fieldValues/sellers from the prior state.
  Future<void> _reloadThumbnails(
    ProductThumbnailLoaded state,
    Emitter<ProductThumbnailState> emit,
  ) async {
    final reloaded = await getProductThumbnailsUseCase(state.productId);
    reloaded.fold(
      (failure) => emit(state.copyWith(
        clearActionSellerId: true,
        actionError: failure.message,
      )),
      (thumbnails) => emit(state.copyWith(
        thumbnails: thumbnails,
        clearActionSellerId: true,
      )),
    );
  }
}
