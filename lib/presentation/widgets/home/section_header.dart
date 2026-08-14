import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  final VoidCallback? onViewAll;
  final bool showBadge;

  const SectionHeader({
    super.key,
    required this.title,
    required this.isDark,
    this.onViewAll,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          if (showBadge) ...[
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                gradient: AppColors.roseGoldGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.deepNavy,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.roseGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.roseGold.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.roseGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
