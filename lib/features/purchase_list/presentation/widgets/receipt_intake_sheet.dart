import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import '../../data/models/create_receipt_params.dart';
import '../../domain/entities/seller_card.dart';
import '../../domain/usecases/create_receipt_usecase.dart';
import '../../domain/usecases/get_seller_cards_usecase.dart';
import 'receipt_line_dialog.dart';
import 'seller_filter_dropdown.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';

/// Receipt check-in popup (FEATURE_2610_18 D46 · D74 · D76 · D87 · D89 ·
/// D96 · D97), shown with `showAppSheet` from [영수증 입고] on the purchase
/// list.
///
/// - Photo (camera or album) is required (D76). Nothing is read from it (D74).
/// - 「결제 카드」 = visible cards + 「카드로 알 수 없음」; the card owner pays,
///   「카드로 알 수 없음」 asks for 「결제 판매자」 (D87). One seller → both
///   hidden and that seller pays (D53).
/// - 「구매일」 starts at today. Product lines come from [ReceiptLineDialog]
///   (any product, quantity 1 or more, amount blank = not entered).
/// - [저장] calls `CreateReceiptUseCase` **from the sheet** and pops `true` on
///   success; the page then shows the toast and sends `ReceiptSaved`.
///
/// ⚠️ Show toasts with this sheet's context (`showAppSheet` owns a messenger).
/// ❌ No negative quantity and no seller per line (D97 · D89).
class ReceiptIntakeSheet extends StatefulWidget {
  final List<Seller> sellers;

  const ReceiptIntakeSheet({required this.sellers, super.key});

  @override
  State<ReceiptIntakeSheet> createState() => _ReceiptIntakeSheetState();
}

/// Card dropdown value of 「카드로 알 수 없음」 (D87).
const String _unknownCard = 'UNKNOWN';

class _ReceiptIntakeSheetState extends State<ReceiptIntakeSheet> {
  final ImagePicker _picker = ImagePicker();
  File? _photo;
  List<SellerCard> _cards = const [];
  String? _cardChoice;
  int? _payerSellerId;
  DateTime _purchasedOn = DateTime.now();
  final List<ReceiptLineParams> _lines = [];
  bool _saving = false;

  bool get _soleSeller => widget.sellers.length == 1;

  @override
  void initState() {
    super.initState();
    if (!_soleSeller) _loadCards();
  }

  Future<void> _loadCards() async {
    final result = await getIt<GetSellerCardsUseCase>()();
    if (!mounted) return;
    result.fold(
      (failure) => showErrorToast(context, failure.message),
      (cards) => setState(() => _cards = cards),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    // Same downscale as the barcode photo (product_register_page.dart).
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;
    setState(() => _photo = File(picked.path));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchasedOn,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _purchasedOn = picked);
    }
  }

  Future<void> _addLine() async {
    final line = await showDialog<ReceiptLineParams>(
      context: context,
      builder: (_) => ReceiptLineDialog(toastContext: context),
    );
    if (line != null && mounted) {
      setState(() => _lines.add(line));
    }
  }

  Future<void> _save() async {
    final photo = _photo;
    if (photo == null) {
      showInputNoticeToast(context, '영수증 사진을 올리세요.');
      return;
    }
    int? cardId;
    int? payerSellerId;
    if (_soleSeller) {
      payerSellerId = widget.sellers.first.id;
    } else if (_cardChoice == null) {
      showInputNoticeToast(context, '결제 카드를 고르세요.');
      return;
    } else if (_cardChoice == _unknownCard) {
      if (_payerSellerId == null) {
        showInputNoticeToast(context, '결제 판매자를 선택하세요.');
        return;
      }
      payerSellerId = _payerSellerId;
    } else {
      cardId = int.parse(_cardChoice!);
    }
    if (_lines.isEmpty) {
      showInputNoticeToast(context, '상품 줄을 하나 이상 넣으세요.');
      return;
    }
    setState(() => _saving = true);
    final result = await getIt<CreateReceiptUseCase>()(
      photo,
      CreateReceiptParams(
        purchasedOn: DateFormat('yyyy-MM-dd').format(_purchasedOn),
        cardId: cardId,
        payerSellerId: payerSellerId,
        lines: List.of(_lines),
      ),
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _saving = false);
        showErrorToast(context, failure.message);
      },
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    SellerCard? pickedCard;
    for (final card in _cards) {
      if (card.id.toString() == _cardChoice) pickedCard = card;
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '영수증 입고',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('영수증 사진',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _saving ? null : () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera, size: 18),
                      label: const Text('촬영'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, size: 18),
                      label: const Text('앨범'),
                    ),
                  ),
                ],
              ),
              if (_photo != null) ...[
                const SizedBox(height: 8),
                Image.file(_photo!, height: 200, fit: BoxFit.contain),
              ],
              const SizedBox(height: 16),
              if (!_soleSeller) ...[
                DropdownButtonFormField<String>(
                  value: _cardChoice,
                  isExpanded: true,
                  hint: const Text('선택'),
                  decoration: const InputDecoration(
                    labelText: '결제 카드',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    ..._cards.map(
                      (card) => DropdownMenuItem<String>(
                        value: card.id.toString(),
                        child: Text(
                          '${card.sellerName} · ${card.alias} (${card.maskedNumber})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const DropdownMenuItem<String>(
                      value: _unknownCard,
                      child: Text('카드로 알 수 없음'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _cardChoice = value),
                ),
                if (pickedCard != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '결제 판매자: ${pickedCard.sellerName}',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ),
                if (_cardChoice == _unknownCard) ...[
                  const SizedBox(height: 12),
                  SellerFilterDropdown(
                    sellers: widget.sellers,
                    selectedSellerId: _payerSellerId,
                    includeAll: false,
                    labelText: '결제 판매자',
                    enabled: !_saving,
                    onChanged: (value) =>
                        setState(() => _payerSellerId = value),
                  ),
                ],
                const SizedBox(height: 16),
              ],
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickDate,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                    '구매일 ${DateFormat('yyyy-MM-dd').format(_purchasedOn)}'),
              ),
              const SizedBox(height: 16),
              const Text('상품', style: TextStyle(fontWeight: FontWeight.w500)),
              for (var index = 0; index < _lines.length; index++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_lines[index].productName,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(_lineSummary(_lines[index])),
                  trailing: IconButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() => _lines.removeAt(index)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _saving ? null : _addLine,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('상품 줄 추가'),
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
              child: _saving ? const AppBusyLabel('저장') : const Text('저장'),
            ),
          ),
        ),
      ],
    );
  }

  /// 「수량 3 · 9,000원」 / 「수량 3 · 미기입」 (D68) + 「 · 기준가 미반영」.
  String _lineSummary(ReceiptLineParams line) {
    final format = NumberFormat('#,##0.##', 'ko_KR');
    final amount = line.totalAmount != null
        ? '${format.format(line.totalAmount)}원'
        : line.unitPrice != null
            ? '@${format.format(line.unitPrice)}원'
            : '미기입';
    final base = line.reflectToBasePrice ? '' : ' · 기준가 미반영';
    return '수량 ${line.quantity} · $amount$base';
  }
}
