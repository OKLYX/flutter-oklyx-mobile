import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/usecases/get_platform_codes_usecase.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/usecases/create_platform_code_usecase.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/usecases/update_platform_code_usecase.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/usecases/delete_platform_code_usecase.dart';
import 'platform_code_event.dart';
import 'platform_code_state.dart';

/// 펼친 택배사 1건(carrierId)의 플랫폼 코드 목록/추가/수정/삭제 BLoC.
///
/// PlatformCodeSection 위젯이 펼쳐질 때 carrierId 로 factoryParam 생성된다.
/// MarketplaceAccountBloc 패턴 미러 — 생성/수정/삭제 후 목록을 자동 재조회한다.
class PlatformCodeBloc extends Bloc<PlatformCodeEvent, PlatformCodeState> {
  final int carrierId;
  final GetPlatformCodesUseCase getPlatformCodesUseCase;
  final CreatePlatformCodeUseCase createPlatformCodeUseCase;
  final UpdatePlatformCodeUseCase updatePlatformCodeUseCase;
  final DeletePlatformCodeUseCase deletePlatformCodeUseCase;

  PlatformCodeBloc({
    required this.carrierId,
    required this.getPlatformCodesUseCase,
    required this.createPlatformCodeUseCase,
    required this.updatePlatformCodeUseCase,
    required this.deletePlatformCodeUseCase,
  }) : super(PlatformCodeInitial()) {
    on<FetchCodes>(_onFetch);
    on<CreateCode>(_onCreate);
    on<UpdateCode>(_onUpdate);
    on<DeleteCode>(_onDelete);
  }

  Future<void> _onFetch(FetchCodes event, Emitter<PlatformCodeState> emit) async {
    emit(PlatformCodeLoading());
    await _loadAndEmit(emit);
  }

  Future<void> _onCreate(CreateCode event, Emitter<PlatformCodeState> emit) async {
    emit(PlatformCodeActionInProgress());
    final result =
        await createPlatformCodeUseCase(carrierId, event.platform, event.code);
    await result.fold(
      (failure) async => emit(PlatformCodeActionFailure(_mapFailure(failure))),
      (_) async {
        emit(PlatformCodeActionSuccess('플랫폼 코드가 추가되었습니다.'));
        await _loadAndEmit(emit);
      },
    );
  }

  Future<void> _onUpdate(UpdateCode event, Emitter<PlatformCodeState> emit) async {
    emit(PlatformCodeActionInProgress());
    final result = await updatePlatformCodeUseCase(
        carrierId, event.codeId, event.platform, event.code);
    await result.fold(
      (failure) async => emit(PlatformCodeActionFailure(_mapFailure(failure))),
      (_) async {
        emit(PlatformCodeActionSuccess('플랫폼 코드가 수정되었습니다.'));
        await _loadAndEmit(emit);
      },
    );
  }

  Future<void> _onDelete(DeleteCode event, Emitter<PlatformCodeState> emit) async {
    emit(PlatformCodeActionInProgress());
    final result = await deletePlatformCodeUseCase(carrierId, event.codeId);
    await result.fold(
      (failure) async => emit(PlatformCodeActionFailure(_mapFailure(failure))),
      (_) async {
        emit(PlatformCodeActionSuccess('플랫폼 코드가 삭제되었습니다.'));
        await _loadAndEmit(emit);
      },
    );
  }

  Future<void> _loadAndEmit(Emitter<PlatformCodeState> emit) async {
    final result = await getPlatformCodesUseCase(carrierId);
    result.fold(
      (failure) => emit(PlatformCodeError(failure.message)),
      (codes) => emit(PlatformCodeLoaded(codes)),
    );
  }

  String _mapFailure(Failure failure) {
    if (failure is ServerFailure && failure.statusCode == 409) {
      return '이미 등록된 플랫폼입니다';
    }
    return failure.message;
  }
}
