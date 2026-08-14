import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/localization_helper.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  final AppLocalizations t;
  const FilterBottomSheet({super.key, required this.t});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late String? _selectedCategory;
  late String? _selectedDistrict;
  late RangeValues _priceRange;
  late double _minRating;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(vendorFilterProvider);
    _selectedCategory = filter.category;
    _selectedDistrict = filter.district ?? 'all';
    _priceRange = RangeValues(
      (filter.minPrice ?? AppConstants.minPriceLKR).toDouble(),
      (filter.maxPrice ?? AppConstants.maxPriceLKR).toDouble(),
    );
    _minRating = filter.minRating ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              _buildHandle(),
              _buildHeader(isDark),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(widget.t.category, isDark),
                      _buildCategoryChips(isDark),
                      const SizedBox(height: 20),
                      _buildSectionTitle(widget.t.district, isDark),
                      _buildDistrictChips(isDark),
                      const SizedBox(height: 20),
                      _buildSectionTitle(widget.t.priceRange, isDark),
                      _buildPriceRangeSlider(isDark),
                      const SizedBox(height: 20),
                      _buildSectionTitle(widget.t.rating, isDark),
                      _buildRatingFilter(isDark),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          Text(
            widget.t.filters,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.deepNavy,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _selectedDistrict = 'all';
                _priceRange = const RangeValues(
                  AppConstants.minPriceLKR,
                  AppConstants.maxPriceLKR,
                );
                _minRating = 0.0;
              });
            },
            child: Text(
              widget.t.clearFilters,
              style: const TextStyle(
                color: AppColors.roseGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white70 : AppColors.deepNavy,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.allCategories.map((cat) {
        final isSelected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedCategory = isSelected ? null : cat;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.roseGoldGradient : null,
              color: isSelected
                  ? null
                  : (isDark ? AppColors.darkCard : AppColors.warmGray),
              borderRadius: BorderRadius.circular(22),
              border: isSelected
                  ? null
                  : Border.all(
                      color: isDark
                          ? Colors.white12
                          : AppColors.warmGray),
            ),
            child: Text(
              widget.t.categoryName(cat),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.deepNavy),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDistrictChips(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.allDistricts.map((d) {
        final isSelected = (_selectedDistrict ?? 'all') == d;
        return GestureDetector(
          onTap: () => setState(() => _selectedDistrict = d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.navyGradient : null,
              color: isSelected
                  ? null
                  : (isDark ? AppColors.darkCard : AppColors.warmGray),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              widget.t.districtName(d),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.deepNavy),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceRangeSlider(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _PriceLabel(
                label: 'Min', value: 'LKR ${_priceRange.start.toInt()}', isDark: isDark),
            _PriceLabel(
                label: 'Max', value: _priceRange.end >= AppConstants.maxPriceLKR ? 'Any' : 'LKR ${_priceRange.end.toInt()}', isDark: isDark),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.roseGold,
            inactiveTrackColor: AppColors.roseGold.withValues(alpha: 0.2),
            thumbColor: AppColors.roseGold,
            overlayColor: AppColors.roseGold.withValues(alpha: 0.15),
            valueIndicatorColor: AppColors.roseGold,
            rangeThumbShape:
                const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: RangeSlider(
            values: _priceRange,
            min: AppConstants.minPriceLKR,
            max: AppConstants.maxPriceLKR,
            divisions: 50,
            onChanged: (v) => setState(() => _priceRange = v),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingFilter(bool isDark) {
    return Row(
      children: List.generate(5, (i) {
        final star = (i + 1).toDouble();
        return GestureDetector(
          onTap: () => setState(
              () => _minRating = _minRating == star ? 0.0 : star),
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              Icons.star_rounded,
              size: 34,
              color: _minRating >= star
                  ? AppColors.gold
                  : (isDark ? Colors.white24 : Colors.grey[300]),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : AppColors.warmGray,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roseGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _applyFilters,
              child: Text(
                widget.t.applyFilters,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    final notifier = ref.read(vendorFilterProvider.notifier);
    notifier.updateCategory(
        _selectedCategory?.isEmpty ?? true ? null : _selectedCategory);
    notifier.updateDistrict(_selectedDistrict);
    notifier.updatePriceRange(
      _priceRange.start > AppConstants.minPriceLKR
          ? _priceRange.start.toInt()
          : null,
      _priceRange.end < AppConstants.maxPriceLKR
          ? _priceRange.end.toInt()
          : null,
    );
    notifier.updateMinRating(_minRating > 0 ? _minRating : null);
    Navigator.of(context).pop();
  }
}

class _PriceLabel extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _PriceLabel(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.grey)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.deepNavy)),
      ],
    );
  }
}
