import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/localization_helper.dart';
import '../../widgets/common/shimmer_loader.dart';
import '../../widgets/home/filter_bottom_sheet.dart';
import '../../widgets/home/language_toggle.dart';
import '../../widgets/vendor/vendor_card.dart';
import '../../../core/constants/app_constants.dart';

class VendorsScreen extends ConsumerStatefulWidget {
  const VendorsScreen({super.key});

  @override
  ConsumerState<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends ConsumerState<VendorsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final filter = ref.watch(vendorFilterProvider);
    AppLocalizations.load(locale);
    AppLocalizations? t;
    try { t = AppLocalizations.of(locale); } catch (_) {}
    if (t == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Text(t.vendors,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20,
                color: isDark ? Colors.white : AppColors.deepNavy)),
        actions: const [LanguageToggle(), SizedBox(width: 8)],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: _buildSearchBar(context, isDark, t, filter),
        ),
      ),
      body: Column(
        children: [
          if (filter.hasActiveFilters) _buildActiveFilters(isDark, t, filter),
          _buildCategoryTabs(isDark, t, filter),
          Expanded(child: _buildVendorList(isDark, t)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark, AppLocalizations t, VendorFilter filter) {
    return Container(
      height: 62, color: isDark ? AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(color: isDark ? AppColors.darkCard : AppColors.warmGray, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: isDark ? Colors.white : AppColors.deepNavy, fontSize: 14),
              decoration: InputDecoration(
                hintText: t.searchHint,
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400], fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.roseGold, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => ref.read(vendorFilterProvider.notifier).updateSearchQuery(v.isEmpty ? null : v),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => showModalBottomSheet(context: context, isScrollControlled: true,
              backgroundColor: Colors.transparent, builder: (_) => FilterBottomSheet(t: t)),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: filter.hasActiveFilters ? AppColors.roseGold : (isDark ? AppColors.darkCard : AppColors.warmGray),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.tune_rounded, color: filter.hasActiveFilters ? Colors.white : AppColors.roseGold, size: 22),
          ),
        ),
      ]),
    );
  }

  Widget _buildActiveFilters(bool isDark, AppLocalizations t, VendorFilter filter) {
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          if (filter.category != null)
            _chip(t.categoryName(filter.category!), () => ref.read(vendorFilterProvider.notifier).updateCategory(null)),
          if (filter.district != null && filter.district != 'all')
            _chip(t.districtName(filter.district!), () => ref.read(vendorFilterProvider.notifier).updateDistrict('all')),
          GestureDetector(
            onTap: () => ref.read(vendorFilterProvider.notifier).clearAll(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.roseGold, borderRadius: BorderRadius.circular(20)),
                child: Text(t.clearFilters, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.roseGold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.roseGold.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.roseGold)),
          const SizedBox(width: 4),
          GestureDetector(onTap: onRemove, child: const Icon(Icons.close_rounded, size: 14, color: AppColors.roseGold)),
        ]),
      ),
    );
  }

  Widget _buildCategoryTabs(bool isDark, AppLocalizations t, VendorFilter filter) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.allCategories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isAll = i == 0;
          final cat = isAll ? null : AppConstants.allCategories[i - 1];
          final isSelected = filter.category == cat;
          return GestureDetector(
            onTap: () => ref.read(vendorFilterProvider.notifier).updateCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.roseGoldGradient : null,
                color: isSelected ? null : (isDark ? AppColors.darkCard : Colors.white),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAll ? '✨ All' : '${AppConstants.categoryIcons[cat]} ${t.categoryName(cat!)}',
                style: TextStyle(
                  fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.deepNavy),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVendorList(bool isDark, AppLocalizations t) {
    final vendors = ref.watch(vendorsProvider);
    return vendors.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8), itemCount: 6,
        itemBuilder: (_, __) => const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: ShimmerVendorCard()),
      ),
      error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.roseGold),
        const SizedBox(height: 12),
        Text(t.errorOccurred, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: () => ref.read(vendorsProvider.notifier).refresh(), child: Text(t.retry)),
      ])),
      data: (list) {
        if (list.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.search_off_rounded, size: 52, color: Colors.grey),
          const SizedBox(height: 12),
          Text(t.noVendorsFound, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(t.tryDifferentFilters, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8), itemCount: list.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: VendorCard(vendor: list[i], isDark: isDark, isHorizontal: false),
          ),
        );
      },
    );
  }
}
