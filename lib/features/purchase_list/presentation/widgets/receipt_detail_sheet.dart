import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import '../../data/models/update_receipt_params.dart';
import '../../domain/entities/receipt_detail.dart';
import '../../domain/entities/seller_card.dart';
import '../../domain/usecases/get_receipt_usecase.dart';
import '../../domain/usecases/get_seller_cards_usecase.dart';
import '../../domain/usecases/update_receipt_usecase.dart';
import 'seller_filter_dropdown.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/zoomable_image_viewer.dart';

/// One receipt — photo + lines (FEATURE_2610_18 D93 ① · D94), shown with
/// `showAppSheet` from the [영수증] button of a recent purchase row.
///
/// Loads the receipt itself (`GetReceiptUseCase`). Tapping the photo opens
/// [ZoomableImageViewer]. A non-`http` photo value (local server path) shows
/// 「이 기기에서 볼 수 없는 사진입니다.」 instead of the image.
///
/// [수정] switches the sheet to the header edit (D100 · D102): 「결제 카드」
/// (visible cards + the receipt's own hidden card + 「카드로 알 수 없음」) ·
/// 「결제 판매자」 (only for 「카드로 알 수 없음」) · 「구매일」. One seller →
/// only 「구매일」 (D53). [저장] calls `UpdateReceiptUseCase` **from the
/// sheet**, shows the saved receipt and calls [onEdited].
///
/// Usage:
/// ```dart
/// showAppSheet<void>(
///   context,
///   builder: (_) => ReceiptDetailSheet(
///     receiptId: record.receiptId!,
///     sellers: sellers,
///     onEdited: reload,
///   ),
/// );
/// ```
///
/// ⚠️ Show toasts with this sheet's context (`showAppSheet` owns a messenger).
/// ❌ The photo and the lines are not editable (D100).
class ReceiptDetailSheet extends StatefulWidget {
  final int receiptId;

  /// Payer seller choices of the edit (one seller hides card and payer).
  final List<Seller> sellers;

  /// Called after a header edit is saved — the caller reloads what it shows.
  final VoidCallback onEdited;

  const ReceiptDetailSheet({
    required this.receiptId,
    required this.sellers,
    required this.onEdited,
    super.key,
  });

  @override
  State<ReceiptDetailSheet> createState() => _ReceiptDetailSheetState();
}

/// Card dropdown value of 「카드로 알 수 없음」 (D87).
const String _unknownCard = 'UNKNOWN';

class _ReceiptDetailSheetState extends State<ReceiptDetailSheet> {
  static final NumberFormat _amountFormat = NumberFormat('#,##0.##', 'ko_KR');

  ReceiptDetail? _detail;
  String? _error;

  // Header edit (D100) — filled from the receipt when [수정] is tapped.
  bool _editing = false;
  bool _saving = false;
  List<SellerCard> _cards = const [];
  String? _cardChoice;
  int? _payerSellerId;
  DateTime _purchasedOn = DateTime.now();

  bool get _soleSeller => widget.sellers.length == 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<GetReceiptUseCase>()(widget.receiptId);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() => _error = failure.message),
      (detail) => setState(() => _detail = detail),
    );
  }

  void _startEdit(ReceiptDetail detail) {
    setState(() {
      _editing = true;
      _cardChoice = detail.cardId?.toString() ?? _unknownCard;
      _payerSellerId = detail.payerSellerId;
      _purchasedOn = DateTime.parse(detail.purchasedOn);
    });
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

  Future<void> _save(ReceiptDetail detail) async {
    int? cardId;
    int? payerSellerId;
    if (_soleSeller) {
      // D100 ②: card and payer seller stay as saved.
      cardId = detail.cardId;
      payerSellerId = detail.cardId == null ? detail.payerSellerId : null;
    } else if (_cardChoice == _unknownCard) {
      if (_payerSellerId == null) {
        showInputNoticeToast(context, '결제 판매자를 선택하세요.');
        return;
      }
      payerSellerId = _payerSellerId;
    } else {
      cardId = int.parse(_cardChoice!);
    }
    setState(() => _saving = true);
    final result = await getIt<UpdateReceiptUseCase>()(
      detail.id,
      UpdateReceiptParams(
        purchasedOn: DateFormat('yyyy-MM-dd').format(_purchasedOn),
        cardId: cardId,
        payerSellerId: payerSellerId,
      ),
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _saving = false);
        showErrorToast(context, failure.message);
      },
      (updated) {
        setState(() {
          _saving = false;
          _editing = false;
          _detail = updated;
        });
        showSuccessToast(context, '영수증을 수정했습니다.');
        widget.onEdited();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _editing ? '영수증 수정' : '영수증',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (detail != null && !_editing)
                TextButton(
                  onPressed: () => _startEdit(detail),
                  child: const Text('수정'),
                ),
              IconButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: detail != null && _editing
              ? _editBody(context, detail)
              : _body(context),
        ),
        if (detail != null && _editing)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _saving ? null : () => setState(() => _editing = false),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : () => _save(detail),
                    child:
                        _saving ? const AppBusyLabel('저장') : const Text('저장'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 「결제 카드」 · 「결제 판매자」 (「카드로 알 수 없음」 only) · 「구매일」 (D100).
  Widget _editBody(BuildContext context, ReceiptDetail detail) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    // D100 ⑥: the receipt's own card stays pickable even when it is hidden.
    final ownHidden = detail.cardId != null &&
        !_cards.any((card) => card.id == detail.cardId);
    String? pickedPayerName;
    for (final card in _cards) {
      if (card.id.toString() == _cardChoice) pickedPayerName = card.sellerName;
    }
    if (ownHidden && detail.cardId.toString() == _cardChoice) {
      pickedPayerName = detail.payerSellerName;
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!_soleSeller) ...[
          DropdownButtonFormField<String>(
            value: _cardChoice,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: '결제 카드',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              if (ownHidden)
                DropdownMenuItem<String>(
                  value: detail.cardId.toString(),
                  child: Text(
                    '${detail.payerSellerName} · ${detail.cardAlias} '
                    '(${detail.cardMaskedNumber})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const DropdownMenuItem<String>(
                value: _unknownCard,
                child: Text('카드로 알 수 없음'),
              ),
            ],
            onChanged:
                _saving ? null : (value) => setState(() => _cardChoice = value),
          ),
          if (pickedPayerName != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '결제 판매자: $pickedPayerName',
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
        ],
        OutlinedButton.icon(
          onPressed: _saving ? null : _pickDate,
          icon: const Icon(Icons.calendar_today, size: 16),
          label: Text('구매일 ${DateFormat('yyyy-MM-dd').format(_purchasedOn)}'),
        ),
      ],
    );
  }

  // A sheet keeps its own small loading / error shapes — the shared
  // AppLoading / AppErrorBox are for a page's main content area only.
  Widget _body(BuildContext context) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    final detail = _detail;
    if (detail == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${detail.purchasedOn} · 결제 판매자 ${detail.payerSellerName} · '
          '카드 ${detail.cardAlias ?? '카드 없음'}',
          style: TextStyle(fontSize: 13, color: muted),
        ),
        const SizedBox(height: 12),
        if (detail.photoUrl.startsWith('http'))
          GestureDetector(
            onTap: () => ZoomableImageViewer.show(
              context,
              image: NetworkImage(detail.photoUrl),
            ),
            child: Image.network(
              detail.photoUrl,
              height: 280,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Text('사진을 불러오지 못했습니다.'),
            ),
          )
        else
          const Text('이 기기에서 볼 수 없는 사진입니다.'),
        const SizedBox(height: 12),
        ...detail.lines.map(
          (line) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(line.productName),
            subtitle: Text(_lineText(line)),
          ),
        ),
      ],
    );
  }

  /// 「수량 3 · 9,000원 (@3,000)」 / 「수량 3 · 미기입」 (D68) + 「 · 기준가 미반영」.
  String _lineText(ReceiptLine line) {
    final amount = line.totalAmount == null
        ? '미기입'
        : '${_amountFormat.format(line.totalAmount)}원'
            '${line.unitPrice == null ? '' : ' (@${_amountFormat.format(line.unitPrice)})'}';
    final base = line.reflectToBasePrice ? '' : ' · 기준가 미반영';
    return '수량 ${line.quantity} · $amount$base';
  }
}
