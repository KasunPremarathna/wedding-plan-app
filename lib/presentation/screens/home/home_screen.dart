import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/localization_helper.dart';
import '../../widgets/home/sponsored_banner_carousel.dart';
import '../../widgets/home/category_grid.dart';
import '../../widgets/home/section_header.dart';
import '../../widgets/vendor/vendor_card.dart';
import '../../widgets/common/shimmer_loader.dart';
import '../../widgets/home/filter_bottom_sheet.dart';
import '../../widgets/home/language_toggle.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _headerAnimController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 60;
      if (scrolled != _isScrolled) {
        setState(() => _isScrolled = scrolled);
        if (scrolled) {
          _headerAnimController.forward();
        } else {
          _headerAnimController.reverse();
        }
      }
    });

    // Load translations
    final locale = ref.read(localeProvider);
    AppLocalizations.load(locale);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final filter = ref.watch(vendorFilterProvider);

    // Reload translations when locale changes
    AppLocalizations.load(locale);
    AppLocalizations? t;
    try {
      t = AppLocalizations.of(locale);
    } catch (_) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBg : AppColors.cream,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(isDark, t!, filter),
        ],
        body: _buildBody(isDark, t, filter),
      ),
    );
  }

  Widget _buildSliverAppBar(
      bool isDark, AppLocalizations t, VendorFilter filter) {
    return SliverAppBar(
      expandedHeight: 210,
      floating: false,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _buildExpandedHeader(isDark, t),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _buildSearchBar(isDark, t, filter),
      ),
      actions: const [
        LanguageToggle(),
        SizedBox(width: 8),
      ],
      title: AnimatedOpacity(
        opacity: _isScrolled ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          t.appName,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.deepNavy,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedHeader(bool isDark, AppLocalizations t) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.darkNavyGradient
            : AppColors.champagneGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.appName,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.deepNavy,
                          letterSpacing: 0.3,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideX(begin: -0.2),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: AppColors.gold,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            t.tagline,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white60
                                  : AppColors.roseGold,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                  const Spacer(),
                  // Decorative rose icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.roseGoldGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.roseGold.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 28,
                    ),
                  ).animate().scale(delay: 300.ms, curve: Curves.elasticOut),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(
      bool isDark, AppLocalizations t, VendorFilter filter) {
    return Container(
      height: 64,
      color: isDark ? AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.warmGray,
                borderRadius: BorderRadius.circular(14),
                border: filter.hasActiveFilters
                    ? Border.all(color: AppColors.roseGold, width: 1.5)
                    : null,
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.deepNavy,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: t.searchHint,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey[400],
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white38 : Colors.grey[400],
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(vendorFilterProvider.notifier)
                                .updateSearchQuery(null);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                ),
                onChanged: (value) {
                  ref
                      .read(vendorFilterProvider.notifier)
                      .updateSearchQuery(value.isEmpty ? null : value);
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showFilterSheet(context, t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: filter.hasActiveFilters
                    ? AppColors.roseGoldGradient
                    : null,
                color:
                    filter.hasActiveFilters ? null : AppColors.roseGold,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.roseGold.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.tune_rounded,
                      color: Colors.white, size: 22),
                  if (filter.hasActiveFilters)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      bool isDark, AppLocalizations t, VendorFilter filter) {
    return RefreshIndicator(
      color: AppColors.roseGold,
      edgeOffset: 120,
      onRefresh: () async {
        ref.invalidate(sponsoredBannersProvider);
        ref.invalidate(featuredVendorsProvider);
        await ref.read(vendorsProvider.notifier).refresh();
      },
      child: CustomScrollView(
        slivers: [
          // ─── Sponsored Banners ──────────────────────────────
          SliverToBoxAdapter(
            child: SponsoredBannerCarousel(isDark: isDark, t: t),
          ),

          // ─── Category Grid ──────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: t.popularCategories,
                  isDark: isDark,
                ),
                CategoryGrid(
                  isDark: isDark,
                  t: t,
                  onCategoryTap: (cat) {
                    ref
                        .read(vendorFilterProvider.notifier)
                        .updateCategory(cat);
                    context.go('/vendors');
                  },
                ),
              ],
            ),
          ),

          // ─── Featured / Boosted Vendors ─────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: t.boostedVendors,
                  isDark: isDark,
                  onViewAll: () => context.go('/vendors'),
                  showBadge: true,
                ),
                _BoostedVendorsRow(isDark: isDark, t: t),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ─── District Quick Filter ───────────────────────────
          SliverToBoxAdapter(
            child: _DistrictFilterRow(isDark: isDark, t: t),
          ),

          // ─── Section: All Vendors ────────────────────────────
          SliverToBoxAdapter(
            child: SectionHeader(
              title: filter.category != null
                  ? t.categoryName(filter.category!)
                  : t.allVendors,
              isDark: isDark,
              showBadge: false,
            ),
          ),

          // ─── Vendor Grid ─────────────────────────────────────
          _VendorsGrid(isDark: isDark, t: t),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, AppLocalizations t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(t: t),
    );
  }
}

// ============================================================
// BOOSTED VENDORS HORIZONTAL ROW
// ============================================================
class _BoostedVendorsRow extends ConsumerWidget {
  final bool isDark;
  final AppLocalizations t;

  const _BoostedVendorsRow({required this.isDark, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredVendorsProvider);

    return featured.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: ShimmerLoader(height: 180, width: double.infinity)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (vendors) => SizedBox(
        height: 225,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: vendors.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            return VendorCard(
              vendor: vendors[index],
              isDark: isDark,
              isHorizontal: true,
            ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.2);
          },
        ),
      ),
    );
  }
}

// ============================================================
// DISTRICT FILTER ROW
// ============================================================
class _DistrictFilterRow extends ConsumerWidget {
  final bool isDark;
  final AppLocalizations t;

  const _DistrictFilterRow({required this.isDark, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(vendorFilterProvider);
    final selectedDistrict = filter.district ?? 'all';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: t.district, isDark: isDark),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: AppConstants.allDistricts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final district = AppConstants.allDistricts[index];
              final isSelected = selectedDistrict == district;
              return GestureDetector(
                onTap: () {
                  ref
                      .read(vendorFilterProvider.notifier)
                      .updateDistrict(district);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.roseGoldGradient : null,
                    color: isSelected
                        ? null
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(22),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: isDark
                                ? AppColors.roseGold.withValues(alpha: 0.2)
                                : AppColors.warmGray,
                          ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.roseGold.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    t.districtName(district),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : AppColors.deepNavy),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ============================================================
// VENDORS GRID (Sliver)
// ============================================================
class _VendorsGrid extends ConsumerWidget {
  final bool isDark;
  final AppLocalizations t;

  const _VendorsGrid({required this.isDark, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendors = ref.watch(vendorsProvider);

    return vendors.when(
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ShimmerLoader(
              height: 110,
              width: double.infinity,
              borderRadius: 16,
            ),
          ),
          childCount: 5,
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 48, color: AppColors.roseGold),
                const SizedBox(height: 12),
                Text(t.errorOccurred,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(vendorsProvider.notifier).refresh(),
                  child: Text(t.retry),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (vendors) {
        if (vendors.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    const Icon(Icons.search_off_rounded,
                        size: 52, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(t.noVendorsFound,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(t.tryDifferentFilters,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= vendors.length) return null;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: VendorCard(
                  vendor: vendors[index],
                  isDark: isDark,
                  isHorizontal: false,
                ).animate().fadeIn(delay: (index * 60).ms),
              );
            },
            childCount: vendors.length,
          ),
        );
      },
    );
  }
}

