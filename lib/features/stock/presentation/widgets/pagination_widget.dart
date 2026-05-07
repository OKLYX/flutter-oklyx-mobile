import 'package:flutter/material.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    int startPage = 0;
    int endPage = (totalPages - 1).clamp(0, 4);

    if (totalPages > 5) {
      if (currentPage < 3) {
        startPage = 0;
        endPage = 4;
      } else if (currentPage > totalPages - 3) {
        startPage = totalPages - 5;
        endPage = totalPages - 1;
      } else {
        startPage = currentPage - 2;
        endPage = currentPage + 2;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (currentPage > 0)
          TextButton(
            onPressed: () => onPageChanged(currentPage - 1),
            child: const Text('이전'),
          ),
        for (int i = startPage; i <= endPage; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: currentPage == i ? null : () => onPageChanged(i),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    currentPage == i ? Colors.blue : Colors.grey[300],
              ),
              child: Text('${i + 1}'),
            ),
          ),
        if (currentPage < totalPages - 1)
          TextButton(
            onPressed: () => onPageChanged(currentPage + 1),
            child: const Text('다음'),
          ),
      ],
    );
  }
}
