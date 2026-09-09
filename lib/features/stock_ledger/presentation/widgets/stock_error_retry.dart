import 'package:flutter/material.dart';

/// 재고 화면 3종의 최초 로드 실패 표시 + 재시도.
///
/// 세 페이지가 같은 문구·같은 동작을 쓰도록 한 곳에 둔다.
class StockErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const StockErrorRetry({
    required this.message,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
