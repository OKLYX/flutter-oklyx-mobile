import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/data/models/create_receipt_params.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/entities/seller_card.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/domain/usecases/get_seller_cards_usecase.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/presentation/widgets/seller_filter_dropdown.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import '../../domain/entities/stock_daily.dart';
import '../../domain/usecases/assign_receipt_usecase.dart';
import '../../domain/usecases/assign_without_receipt_usecase.dart';

/// Receipt assignment sheet of 「일별 입출고 내역」 (FEATURE_2610_19 D118 ·
/// D121 · D87 · D135), shown with `showAppSheet`.
///
/// - Photo (camera or album, required), 「결제 카드」 = visible cards +
///   「카드로 알 수 없음」 (then 「결제 판매자」), 「구매일」 starting at the screen
///   day — the same fields as the receipt check-in sheet.
/// - The given products (every undecided product of the screen day, or the
///   checked ones — FEATURE_2611_01 D14) with their 「남은 미등록」 count: the
///   person types how many this receipt covers (0 = not on it, more than left
///   is refused) and the amount (total or unit, blank = the registered price).
/// - [저장] calls `AssignReceiptUseCase` from the sheet and pops `true`.
/// - [withoutReceipt] = 「영수증 없이 판매자 정하기」 (FEATURE_2611_01 D2 · D4 ·
///   D8): no photo, card or purchase day — 「영수증 나중에」 / 「영수증 없음(발견
///   재고 등)」 and 「판매자」 instead; [저장] calls
///   `AssignWithoutReceiptUseCase`.
/// - [prefillRemaining] = opened from checked rows (D14): each count starts at
///   the remaining unregistered quantity instead of 0.
///
/// ⚠️ Show toasts with this sheet's context (`showAppSheet` owns a messenger).
class ReceiptAssignSheet extends StatefulWidget {
  final String date;
  final List<UnregisteredProduct> products;
  final List<Seller> sellers;
  final bool withoutReceipt;
  final bool prefillRemaining;

  const ReceiptAssignSheet({
    required this.date,
    required this.products,
    required this.sellers,
    this.withoutReceipt = false,
    this.prefillRemaining = false,
    super.key,
  });

  @override
  State<ReceiptAssignSheet> createState() => _ReceiptAssignSheetState();
}

const String _unknownCard = 'UNKNOWN';

class _LineInput {
  final TextEditingController quantity;
  final TextEditingController amount = TextEditingController();
  bool unitMode = false;
  bool reflect = true;

  _LineInput(int initialQuantity)
      : quantity = TextEditingController(text: '$initialQuantity');
}

class _ReceiptAssignSheetState extends State<ReceiptAssignSheet> {
  final ImagePicker _picker = ImagePicker();
  File? _photo;
  List<SellerCard> _cards = const [];
  String? _cardChoice;
  int? _payerSellerId;
  late DateTime _purchasedOn = DateTime.parse(widget.date);
  late final Map<int, _LineInput> _lines = {
    for (final p in widget.products)
      p.productId: _LineInput(widget.prefillRemaining ? p.remainingQty : 0),
  };
  // FEATURE_2611_01 D4: `RECEIPT_LATER` or `NO_RECEIPT`, null = not picked yet.
  String? _receiptMode;
  int? _sellerId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (!widget.withoutReceipt) {
      _loadCards();
    }
  }

  @override
  void dispose() {
    for (final line in _lines.values) {
      line.quantity.dispose();
      line.amount.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCards() async {
    final result = await getIt<GetSellerCardsUseCase>()();
    if (!mounted) {
      return;
    }
    result.fold(
      (failure) => showErrorToast(context, failure.message),
      (cards) => setState(() => _cards = cards),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    // Same downscale as the receipt check-in sheet.
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
    );
    if (picked == null || !mounted) {
      return;
    }
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

  Future<void> _save() async {
    final photo = _photo;
    int? cardId;
    int? payerSellerId;
    if (widget.withoutReceipt) {
      if (_receiptMode == null) {
        showInputNoticeToast(context, '영수증 처리를 고르세요.');
        return;
      }
      if (_sellerId == null) {
        showInputNoticeToast(context, '판매자를 선택하세요.');
        return;
      }
    } else {
      if (photo == null) {
        showInputNoticeToast(context, '영수증 사진을 올리세요.');
        return;
      }
      if (_cardChoice == null) {
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
    }
    final lines = <ReceiptLineParams>[];
    for (final p in widget.products) {
      final input = _lines[p.productId]!;
      final qty = int.tryParse(input.quantity.text.trim());
      if (qty == null || qty < 0) {
        showInputNoticeToast(context, '개수는 0 이상 정수만 입력할 수 있습니다.');
        return;
      }
      if (qty > p.remainingQty) {
        showInputNoticeToast(context,
            '${p.productName}: 남은 영수증 미등록 수량(${p.remainingQty}개)보다 많습니다.');
        return;
      }
      if (qty == 0) {
        continue;
      }
      final amount = double.tryParse(input.amount.text.trim());
      lines.add(ReceiptLineParams(
        productId: p.productId,
        productName: p.productName,
        quantity: qty,
        totalAmount: input.unitMode ? null : amount,
        unitPrice: input.unitMode ? amount : null,
        reflectToBasePrice: input.reflect,
      ));
    }
    if (lines.isEmpty) {
      showInputNoticeToast(
          context,
          widget.withoutReceipt
              ? '판매자를 정할 상품의 개수를 입력하세요.'
              : '이 영수증으로 처리한 상품의 개수를 입력하세요.');
      return;
    }
    setState(() => _saving = true);
    final result = widget.withoutReceipt
        ? await getIt<AssignWithoutReceiptUseCase>()(
            widget.date, _receiptMode!, _sellerId!, lines)
        : await getIt<AssignReceiptUseCase>()(
            widget.date,
            photo!,
            CreateReceiptParams(
              purchasedOn: DateFormat('yyyy-MM-dd').format(_purchasedOn),
              cardId: cardId,
              payerSellerId: payerSellerId,
              lines: lines,
            ),
          );
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
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    SellerCard? pickedCard;
    for (final card in _cards) {
      if (card.id.toString() == _cardChoice) {
        pickedCard = card;
      }
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.withoutReceipt ? '영수증 없이 판매자 정하기' : '영수증 올리기',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
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
              if (widget.withoutReceipt) ...[
                const Text('영수증 처리',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('영수증 나중에'),
                      selected: _receiptMode == 'RECEIPT_LATER',
                      onSelected: _saving
                          ? null
                          : (_) =>
                              setState(() => _receiptMode = 'RECEIPT_LATER'),
                    ),
                    ChoiceChip(
                      label: const Text('영수증 없음(발견 재고 등)'),
                      selected: _receiptMode == 'NO_RECEIPT',
                      onSelected: _saving
                          ? null
                          : (_) => setState(() => _receiptMode = 'NO_RECEIPT'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SellerFilterDropdown(
                  sellers: widget.sellers,
                  selectedSellerId: _sellerId,
                  includeAll: false,
                  enabled: !_saving,
                  onChanged: (value) => setState(() => _sellerId = value),
                ),
              ] else ..._receiptFields(muted, pickedCard),
              const SizedBox(height: 16),
              Text(
                  widget.withoutReceipt
                      ? '판매자를 정할 상품'
                      : '이 영수증으로 처리한 상품',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              for (final p in widget.products) _productInput(p, muted),
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

  /// Photo · 「결제 카드」 · 「결제 판매자」 · 「구매일」 of [영수증 올리기].
  List<Widget> _receiptFields(Color muted, SellerCard? pickedCard) => [
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
        DropdownButtonFormField<String>(
          initialValue: _cardChoice,
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
                  '${card.sellerName} · ${card.alias} '
                  '(${card.maskedNumber})',
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
            onChanged: (value) => setState(() => _payerSellerId = value),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _saving ? null : _pickDate,
          icon: const Icon(Icons.calendar_today, size: 16),
          label: Text(
              '구매일 ${DateFormat('yyyy-MM-dd').format(_purchasedOn)}'),
        ),
      ];

  Widget _productInput(UnregisteredProduct p, Color muted) {
    final input = _lines[p.productId]!;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${p.productName} (남은 미등록 ${p.remainingQty}개)'),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(
                width: 72,
                child: TextField(
                  controller: input.quantity,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '개수'),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<bool>(
                value: input.unitMode,
                items: const [
                  DropdownMenuItem(value: false, child: Text('총액')),
                  DropdownMenuItem(value: true, child: Text('단가')),
                ],
                onChanged: _saving
                    ? null
                    : (value) =>
                        setState(() => input.unitMode = value ?? false),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: input.amount,
                  enabled: !_saving,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '금액 (모르면 비움)'),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: input.reflect,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => input.reflect = value ?? true),
              ),
              Text('상품 기준가에 반영', style: TextStyle(fontSize: 12, color: muted)),
            ],
          ),
        ],
      ),
    );
  }
}
