import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../domain/usecases/shipping_label_usecase.dart';
import 'shipment_confirm_event.dart';
import 'shipment_confirm_state.dart';

/// 발송처리(운송장 업로드) 다이얼로그 전용 BLoC.
/// 파일 선택 → 업로드(로딩) → 결과/에러를 단일 copyWith 상태로 관리.
class ShipmentConfirmBloc
    extends Bloc<ShipmentConfirmEvent, ShipmentConfirmState> {
  final ShippingLabelUseCase useCase;

  ShipmentConfirmBloc({required this.useCase})
      : super(const ShipmentConfirmState()) {
    on<PickFile>(_onPickFile);
    on<UploadShipment>(_onUpload);
    on<ResetShipmentConfirm>(_onReset);
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
    ));
  }

  Future<void> _onUpload(
      UploadShipment event, Emitter<ShipmentConfirmState> emit) async {
    final bytes = state.fileBytes;
    final name = state.fileName;
    if (bytes == null || name == null || state.isUploading) return;
    emit(state.copyWith(isUploading: true, clearError: true));
    final result = await useCase.confirmShipment(bytes: bytes, filename: name);
    result.fold(
      (failure) =>
          emit(state.copyWith(isUploading: false, error: _errorMessage(failure))),
      (res) => emit(state.copyWith(isUploading: false, result: res)),
    );
  }

  void _onReset(
      ResetShipmentConfirm event, Emitter<ShipmentConfirmState> emit) {
    // 전체 초기화 — [다른 파일 업로드] 시 result/file/error 비움.
    emit(const ShipmentConfirmState());
  }

  // 프론트와 동일: 400 = 파싱/빈 파일, 403 = 권한, 그 외 고정 메시지(본문 미파싱).
  String _errorMessage(Failure failure) {
    final code = failure is ServerFailure ? failure.statusCode : null;
    if (code == 403) return '권한이 없습니다. 관리자 계정으로 로그인해주세요.';
    if (code == 400) return '파일을 처리할 수 없습니다. 택배사 결과 xlsx 형식을 확인해주세요.';
    return '발송처리에 실패했습니다. 다시 시도해주세요.';
  }
}
