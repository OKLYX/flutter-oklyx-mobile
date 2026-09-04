import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../data/models/shipment_confirm_result.dart';

/// 결과 요약 칩에서 상세 표를 열 수 있는 버킷 = 서버가 "목록"을 주는 3개뿐이다(PLAN 2609_12 D2).
/// 요청 건수·매칭·성공은 응답이 숫자만 주므로 정적 칩으로 그린다 — 누를 수 있게 보이면
/// 빈 표를 보여주거나 없는 목록을 지어내야 한다.
/// Lives in the state file, not the dialog — the event carries this type too.
enum ResultBucket { unmatched, skipped, failed }

/// 발송처리 다이얼로그의 단일 상태 (프론트 모달 내부 state 대응).
class ShipmentConfirmState extends Equatable {
  final String? fileName;
  final Uint8List? fileBytes;
  final bool isUploading;
  final ShipmentConfirmResult? result;
  final String? error;

  /// Sticky across a reset: true once any upload succeeded, so
  /// the caller refetches the order list even if a later upload is all-skipped.
  final bool hasSucceeded;

  /// Which result chip is expanded, or null for none (PLAN 2609_12 D4 — tapping
  /// the same chip clears it). Must stay in [props] or the toggle looks dead.
  final ResultBucket? selectedBucket;

  const ShipmentConfirmState({
    this.fileName,
    this.fileBytes,
    this.isUploading = false,
    this.result,
    this.error,
    this.hasSucceeded = false,
    this.selectedBucket,
  });

  ShipmentConfirmState copyWith({
    String? fileName,
    Uint8List? fileBytes,
    bool? isUploading,
    ShipmentConfirmResult? result,
    String? error,
    bool? hasSucceeded,
    ResultBucket? selectedBucket,
    bool clearFile = false,
    bool clearResult = false,
    bool clearError = false,
    bool clearBucket = false,
  }) {
    return ShipmentConfirmState(
      fileName: clearFile ? null : (fileName ?? this.fileName),
      fileBytes: clearFile ? null : (fileBytes ?? this.fileBytes),
      isUploading: isUploading ?? this.isUploading,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      hasSucceeded: hasSucceeded ?? this.hasSucceeded,
      selectedBucket:
          clearBucket ? null : (selectedBucket ?? this.selectedBucket),
    );
  }

  @override
  List<Object?> get props => [
        fileName,
        fileBytes,
        isUploading,
        result,
        error,
        hasSucceeded,
        // ⚠️ Without this the chip toggle emits an "equal" state and the
        // panel never repaints.
        selectedBucket,
      ];
}
