import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/presentation/widgets/seller_filter_dropdown.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import '../../domain/usecases/change_seller_usecase.dart';

/// 「판매자 바꾸기」 sheet of 「일별 입출고 내역」 (FEATURE_2611_01 D7 · D14 ·
/// D15), shown with `showAppSheet`.
///
/// - Opened with the checked targets: incoming rows with a decided seller and
///   no receipt ([movementIds]) and 「영수증 없음」 shares ([shareRecordIds]);
///   [labels] lists them as the screen shows them.
/// - One field: 「판매자」 (required — never back to 「미정」). [저장] calls
///   `ChangeSellerUseCase` from the sheet and pops `true`.
///
/// ⚠️ Show toasts with this sheet's context (`showAppSheet` owns a messenger).
class SellerChangeSheet extends StatefulWidget {
  final List<int> movementIds;
  final List<int> shareRecordIds;
  final List<String> labels;
  final List<Seller> sellers;

  const SellerChangeSheet({
    required this.movementIds,
    required this.shareRecordIds,
    required this.labels,
    required this.sellers,
    super.key,
  });

  @override
  State<SellerChangeSheet> createState() => _SellerChangeSheetState();
}

class _SellerChangeSheetState extends State<SellerChangeSheet> {
  int? _sellerId;
  bool _saving = false;

  Future<void> _save() async {
    final sellerId = _sellerId;
    if (sellerId == null) {
      showInputNoticeToast(context, '판매자를 선택하세요.');
      return;
    }
    setState(() => _saving = true);
    final result = await getIt<ChangeSellerUseCase>()(
        sellerId, widget.movementIds, widget.shareRecordIds);
    if (!mounted) {
      return;
    }
    result.fold(
      (failure) {
        setState(() => _saving = false);
        showErrorToast(context, failure.message);
      },
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '판매자 바꾸기',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final label in widget.labels)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(label),
                  ),
                const SizedBox(height: 12),
                SellerFilterDropdown(
                  sellers: widget.sellers,
                  selectedSellerId: _sellerId,
                  includeAll: false,
                  enabled: !_saving,
                  onChanged: (value) => setState(() => _sellerId = value),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child:
                    _saving ? const AppBusyLabel('저장') : const Text('저장'),
              ),
            ),
          ),
        ],
      );
}
