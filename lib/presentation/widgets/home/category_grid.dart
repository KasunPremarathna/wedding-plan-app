import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/localization_helper.dart';

class CategoryGrid extends StatelessWidget {
  final bool isDark;
  final AppLocalizations t;
  final void Function(String category) onCategoryTap;

  const CategoryGrid({
    super.key,
    required this.isDark,
    required this.t,
    required this.onCategoryTap,
  });

  static const List<_CategoryItem> _items = [
    _CategoryItem('hotels_venues', '🏨', Color(0xFF1A1F3C)),
    _CategoryItem('photography', '📸', Color(0xFFB76E79)),
    _CategoryItem('dj_bands', '🎵', Color(0xFF4A1942)),
    _CategoryItem('bridal_salons', '💄', Color(0xFF800020)),
    _CategoryItem('decorators', '🌸', Color(0xFFD4AF37)),
    _CategoryItem('poru_ashtaka', '🪘', Color(0xFF6B4226)),
    _CategoryItem('catering', '🍽️', Color(0xFF2E7D32)),
    _CategoryItem('transport', '🚗', Color(0xFF1565C0)),
    _CategoryItem('wedding_cards', '💌', Color(0xFF6A1B9A)),
    _CategoryItem('cakes', '🎂', Color(0xFFE91E8C)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
          return _CategoryChip(
            item: item,
            isDark: isDark,
            label: t.categoryName(item.key),
            onTap: () => onCategoryTap(item.key),
            index: index,
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final _CategoryItem item;
  final bool isDark;
  final String label;
  final VoidCallback onTap;
  final int index;

  const _CategoryChip({
    required this.item,
    required this.isDark,
    required this.label,
    required this.onTap,
    required this.index,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.darkCard
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: widget.item.color.withValues(alpha:
                          widget.isDark ? 0.3 : 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: widget.item.color.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.item.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? Colors.white70
                      : AppColors.deepNavy,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (widget.index * 60).ms).scale(
          begin: const Offset(0.8, 0.8),
          curve: Curves.elasticOut,
          delay: (widget.index * 60).ms,
        );
  }
}

class _CategoryItem {
  final String key;
  final String emoji;
  final Color color;
  const _CategoryItem(this.key, this.emoji, this.color);
}
