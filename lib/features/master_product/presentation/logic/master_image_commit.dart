import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/detail_content.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_image_pool.dart';

/// Applies the create-mode image buffer to a just-created master — port of
/// web `app/dashboard/master-products/components/masterImageCommit.ts`
/// (@09208a0).
/// **File**: lib/features/master_product/presentation/logic/master_image_commit.dart
///
/// Order: upload pool files **sequentially** (the server uses upload order as
/// pool order) → import product-image references → apply each field.
/// Stops at the first failure and returns that [Failure]; `null` = success.
///
/// ⚠️ No user-facing message here — the text shown on failure differs per
///    screen, so the caller decides.
/// 🔴 This is an extension point, not a dedupe: every create entry calls it
///    so images are always saved by the same rules.
///
/// **Usage**:
/// ```dart
/// final failure = await commitMasterImageBuffer(created.id, _imageBuffer);
/// if (failure != null) { /* 마스터·옵션은 생성되었습니다. 이미지 반영에 실패했습니다. */ }
/// ```
Future<Failure?> commitMasterImageBuffer(
  int masterId,
  MasterImageBuffer buffer,
) async {
  final useCase = getIt<MasterProductUseCase>();
  // Buffer: upload pool files sequentially (index → real id) then apply
  // mappings. Sequential await preserves pool sortOrder.
  final idByIndex = <int>[];
  for (final file in buffer.files) {
    final uploaded = await useCase.uploadPoolImage(masterId, file);
    final failure = uploaded.fold((f) => f, (img) {
      idByIndex.add(img.id);
      return null;
    });
    if (failure != null) {
      return failure;
    }
  }
  // Import product-image references (create pool entries) → map
  // productImageId to pool id.
  final poolIdByProductId = <int, int>{};
  final productIds = {
    for (final ids in buffer.productAssignments.values) ...ids,
  }.toList();
  if (productIds.isNotEmpty) {
    final imported = await useCase.importProductImages(masterId, productIds);
    final failure = imported.fold((f) => f, (refs) {
      for (final r in refs) {
        final pid = r.productImageId;
        if (pid != null) {
          poolIdByProductId[pid] = r.id;
        }
      }
      return null;
    });
    if (failure != null) {
      return failure;
    }
  }
  // Apply each field = uploaded file pool ids + imported product pool ids.
  final fieldKeys = <String>{
    ...buffer.assignments.keys,
    ...buffer.productAssignments.keys,
  };
  for (final fieldKey in fieldKeys) {
    final fileIds = (buffer.assignments[fieldKey] ?? const <int>[])
        .where((i) => i >= 0 && i < idByIndex.length)
        .map((i) => idByIndex[i]);
    final productPoolIds =
        (buffer.productAssignments[fieldKey] ?? const <int>[])
            .map((id) => poolIdByProductId[id])
            .whereType<int>();
    final ids = [...fileIds, ...productPoolIds];
    if (fieldKey == kSourceZone) {
      final result = await useCase.setSourceImage(
        masterId,
        ids.isEmpty ? null : ids.first,
      );
      final failure = result.fold((f) => f, (_) => null);
      if (failure != null) {
        return failure;
      }
    } else {
      final result = await useCase.setZoneImages(masterId, fieldKey, ids);
      final failure = result.fold((f) => f, (_) => null);
      if (failure != null) {
        return failure;
      }
    }
  }
  return null;
}
