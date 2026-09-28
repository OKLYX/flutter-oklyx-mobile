import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/usecases/order_usecase.dart';
import '../../domain/usecases/shipping_label_usecase.dart';
import 'shipment_confirm_event.dart';
import 'shipment_confirm_state.dart';

/// 발송처리(운송장 업로드) 다이얼로그 전용 BLoC.
/// 파일 선택 → 업로드(로딩) → 결과/에러를 단일 copyWith 상태로 관리.
class ShipmentConfirmBloc
    extends Bloc<ShipmentConfirmEvent, ShipmentConfirmState> {
  final ShippingLabelUseCase useCase;

  /// 기본 예약 시각(주문관리 설정) 조회용(FEATURE_2609_75 / D12).
  final OrderUseCase orderUseCase;

  /// 저장된 송장 모드의 주문 라인 id(FEATURE_2609_75 / D18). null = 파일 모드.
  final List<int>? storedOrderItemIds;

  ShipmentConfirmBloc({
    required this.useCase,
    required this.orderUseCase,
    this.storedOrderItemIds,
  }) : super(const ShipmentConfirmState()) {
    on<PickFile>(_onPickFile);
    on<UploadShipment>(_onUpload);
    on<ResetShipmentConfirm>(_onReset);
    on<SelectResultBucket>(_onSelectBucket);
    on<LoadDefaultExecuteAt>(_onLoadDefaultExecuteAt);
    on<ChangeExecuteAt>(_onChangeExecuteAt);
    on<ReserveShipment>(_onReserve);
  }

  Future<void> _onPickFile(
      PickFile event, Emitter<ShipmentConfirmState> emit) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    // 취소하거나 bytes 미확보 시 무시.
    final file = picked?.files.single;
    if (file == null || file.bytes == null) return;
    // 파일이 바뀌면 이전 결과/에러를 초기화.
    emit(state.copyWith(
      fileName: file.name,
      fileBytes: file.bytes,
      clearResult: true,
      clearError: true,
      clearBucket: true,
      clearReserveResult: true,
    ));
  }

  Future<void> _onUpload(
      UploadShipment event, Emitter<ShipmentConfirmState> emit) async {
    final bytes = state.fileBytes;
    final name = state.fileName;
    final storedIds = storedOrderItemIds;
    if ((storedIds == null && (bytes == null || name == null)) ||
        state.isUploading ||
        state.isReserving) {
      return;
    }
    emit(state.copyWith(isUploading: true, clearError: true));
    // 저장된 송장 모드는 E16(발주처리 → 송장 등록, D18) — 결과 모양이 같아 아래 처리를 그대로 쓴다.
    final result = storedIds != null
        ? await useCase.shipStoredNow(storedIds)
        : await useCase.confirmShipment(bytes: bytes!, filename: name!);
    result.fold(
      // 저장된 송장 모드(E16)에는 파일이 없다 — 파일 형식 문구 대신 서버 문구(D18).
      (failure) => emit(state.copyWith(
          isUploading: false,
          error: storedIds != null
              ? _storedShipErrorMessage(failure)
              : _errorMessage(failure))),
      // A second upload in the same dialog must not carry the previous
      // selection onto new numbers (PLAN 2609_12 D5).
      (res) => emit(state.copyWith(
        isUploading: false,
        result: res,
        hasSucceeded: state.hasSucceeded || res.succeeded > 0,
        clearBucket: true,
      )),
    );
  }

  void _onReset(
      ResetShipmentConfirm event, Emitter<ShipmentConfirmState> emit) {
    // 전체 초기화 — [다른 파일 업로드] 시 result/file/error 비움.
    // hasSucceeded 만 보존한다(1차 성공 후 2차가 전부 스킵이어도 재조회해야 함).
    // 예약 시각도 보존한다 — 같은 시각으로 다른 파일을 예약하는 흐름(웹 reset 과 같다).
    emit(ShipmentConfirmState(
      hasSucceeded: state.hasSucceeded,
      executeAt: state.executeAt,
    ));
  }

  void _onSelectBucket(
      SelectResultBucket event, Emitter<ShipmentConfirmState> emit) {
    final isSame = state.selectedBucket == event.bucket;
    emit(state.copyWith(
      selectedBucket: isSame ? null : event.bucket,
      clearBucket: isSame,
    ));
  }

  /// 기본 예약 시각 = 설정의 다음 도래 시각(D12). 실패하면 빈 칸 — 사용자가 고른다.
  /// 이미 고른 값이 있으면 덮지 않는다.
  Future<void> _onLoadDefaultExecuteAt(
      LoadDefaultExecuteAt event, Emitter<ShipmentConfirmState> emit) async {
    final result = await orderUseCase.getOrderSetting();
    if (emit.isDone) return;
    result.fold((_) {}, (setting) {
      if (state.executeAt == null && setting.nextExecuteAt.isNotEmpty) {
        emit(state.copyWith(executeAt: setting.nextExecuteAt));
      }
    });
  }

  void _onChangeExecuteAt(
      ChangeExecuteAt event, Emitter<ShipmentConfirmState> emit) {
    emit(state.copyWith(executeAt: event.executeAt));
  }

  /// [예약 발송] = 송장만 저장하고 발송대기중으로 둔다(D20·D27). 사유(지난 시각 등)는 서버 문구 그대로.
  /// 저장된 송장 모드는 E15(D18) — 파일 없이 보관된 송장으로 예약한다.
  Future<void> _onReserve(
      ReserveShipment event, Emitter<ShipmentConfirmState> emit) async {
    final bytes = state.fileBytes;
    final name = state.fileName;
    final executeAt = state.executeAt;
    final storedIds = storedOrderItemIds;
    if ((storedIds == null && (bytes == null || name == null)) ||
        executeAt == null ||
        state.isUploading ||
        state.isReserving) {
      return;
    }
    emit(state.copyWith(isReserving: true, clearError: true));
    final result = storedIds != null
        ? await useCase.reserveStored(storedIds, executeAt)
        : await useCase.reserveShipment(
            bytes: bytes!,
            filename: name!,
            executeAt: executeAt,
          );
    result.fold(
      (failure) => emit(state.copyWith(
          isReserving: false, error: _reserveErrorMessage(failure))),
      (res) => emit(state.copyWith(
        isReserving: false,
        reserveResult: res,
        hasSucceeded: state.hasSucceeded ||
            res.reservedShipments > 0 ||
            res.updatedInvoices > 0,
      )),
    );
  }

  /// 400 = 서버 문구 그대로(「지난 시각은 고를 수 없습니다」 · 파일 형식 등).
  String _reserveErrorMessage(Failure failure) {
    final code = failure is ServerFailure ? failure.statusCode : null;
    if (code == 403) return '권한이 없습니다. 관리자 계정으로 로그인해주세요.';
    if (code == 400) return failure.message;
    return '예약에 실패했습니다. 다시 시도해주세요.';
  }

  /// 저장된 송장 모드(E16)에는 파일이 없다 — 400 은 서버 문구를 그대로 보인다(D18).
  String _storedShipErrorMessage(Failure failure) {
    final code = failure is ServerFailure ? failure.statusCode : null;
    if (code == 403) return '권한이 없습니다. 관리자 계정으로 로그인해주세요.';
    if (code == 400) return failure.message;
    return '발송처리에 실패했습니다. 다시 시도해주세요.';
  }

  // 프론트와 동일: 400 = 파싱/빈 파일, 403 = 권한, 그 외 고정 메시지(본문 미파싱).
  String _errorMessage(Failure failure) {
    final code = failure is ServerFailure ? failure.statusCode : null;
    if (code == 403) return '권한이 없습니다. 관리자 계정으로 로그인해주세요.';
    if (code == 400) return '파일을 처리할 수 없습니다. 택배사 결과 xlsx 형식을 확인해주세요.';
    return '발송처리에 실패했습니다. 다시 시도해주세요.';
  }
}
