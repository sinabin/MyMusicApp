import 'package:flutter/material.dart';

/// Library 탭 상단의 빠른 접근 카드 위젯.
///
/// Favorites·Recent·All Songs 3가지 variant로 사용.
/// [LibraryScreen]의 Quick Access 섹션에서 표시.
class LibraryQuickCard extends StatelessWidget {
  /// 카드 아이콘.
  final IconData icon;

  /// 카드 레이블.
  final String label;

  /// 항목 수.
  final int count;

  /// 카드 강조 색상.
  final Color color;

  /// 탭 콜백.
  final VoidCallback onTap;

  const LibraryQuickCard({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  icon,
                  size: 32,
                  color: color.withValues(alpha: 0.2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
