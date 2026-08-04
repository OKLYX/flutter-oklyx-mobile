import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../data/models/shipment_confirm_result.dart';

/// 발송처리 다이얼로그의 단일 상태 (프론트 모달 내부 state 대응).
class ShipmentConfirmState extends Equatable {
  final String? fileName;
  final Uint8List? fileBytes;
  final bool isUploading;
  final ShipmentConfirmResult? result;
  final String? error;

  const ShipmentConfirmState({
    this.fileName,
    this.fileBytes,
    this.isUploading = false,
    this.result,
    this.error,
  });

  ShipmentConfirmState copyWith({
    String? fileName,
    Uint8List? fileBytes,
    bool? isUploading,
    ShipmentConfirmResult? result,
    String? error,
    bool clearFile = false,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ShipmentConfirmState(
      fileName: clearFile ? null : (fileName ?? this.fileName),
      fileBytes: clearFile ? null : (fileBytes ?? this.fileBytes),
      isUploading: isUploading ?? this.isUploading,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [fileName, fileBytes, isUploading, result, error];
}
