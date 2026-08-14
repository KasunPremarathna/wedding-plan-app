import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../providers/app_providers.dart';

class VendorCard extends ConsumerWidget {
  final Vendor vendor;
  final bool isDark;
  final bool isHorizontal;

  const VendorCard({
    super.key,
    required this.vendor,
    required this.isDark,
    required this.isHorizontal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return isHorizontal
        ? _HorizontalVendorCard(vendor: vendor, isDark: isDark, ref: ref)
        : _VerticalVendorCard(vendor: vendor, isDark: isDark, ref: ref);
  }
}

// ─── Horizontal (boosted row) ───────────────────────────────────────────────

class _HorizontalVendorCard extends StatelessWidget {
  final Vendor vendor;
  final bool isDark;
  final WidgetRef ref;

  const _HorizontalVendorCard(
      {required this.vendor, required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isFav = ref.watch(favoritesProvider).contains(vendor.id);
    final priceFormatter = NumberFormat('#,###');

    return GestureDetector(
      onTap: () => context.go('/vendor/${vendor.id}'),
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.roseGold.withValues(alpha: isDark ? 0.15 : 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: vendor.coverImageUrl,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 130,
                      color: AppColors.roseGold.withValues(alpha: 0.15),
                      child: const Icon(Icons.image_rounded,
                          color: AppColors.roseGold, size: 32),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 130,
                      decoration: const BoxDecoration(
                        gradient: AppColors.champagneGradient,
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: AppColors.roseGold, size: 36),
                    ),
                  ),
                ),
                // Boost badge
                if (vendor.isBoosted)
                  const Positioned(
                    top: 10,
                    left: 10,
                    child: _BoostBadge(),
                  ),
                // Fav button
                Positioned(
                  top: 8,
                  right: 8,
                  child: _FavoriteButton(
                    vendorId: vendor.id,
                    isFav: isFav,
                    ref: ref,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 11, color: AppColors.roseGold),
                      const SizedBox(width: 2),
                      Text(
                        vendor.district,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: vendor.rating,
                        itemCount: 5,
                        itemSize: 12,
                        itemBuilder: (_, __) => const Icon(
                          Icons.star_rounded,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vendor.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'From LKR ${priceFormatter.format(vendor.startingPriceLkr)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.roseGold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Vertical (list) ────────────────────────────────────────────────────────

class _VerticalVendorCard extends StatelessWidget {
  final Vendor vendor;
  final bool isDark;
  final WidgetRef ref;

  const _VerticalVendorCard(
      {required this.vendor, required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isFav = ref.watch(favoritesProvider).contains(vendor.id);
    final priceFormatter = NumberFormat('#,###');

    return GestureDetector(
      onTap: () => context.go('/vendor/${vendor.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: vendor.coverImageUrl,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 110,
                      height: 110,
                      color: AppColors.roseGold.withValues(alpha: 0.12),
                      child: const Icon(Icons.image_rounded,
                          color: AppColors.roseGold, size: 28),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(
                        gradient: AppColors.champagneGradient,
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: AppColors.roseGold, size: 32),
                    ),
                  ),
                ),
                if (vendor.isBoosted)
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: _BoostBadge(small: true),
                  ),
              ],
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vendor.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark ? Colors.white : AppColors.deepNavy,
                            ),
                          ),
                        ),
                        _FavoriteButton(
                          vendorId: vendor.id,
                          isFav: isFav,
                          ref: ref,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.roseGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            vendor.category
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.roseGold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.location_on_rounded,
                            size: 11, color: AppColors.roseGold),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            vendor.district,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: vendor.rating,
                          itemCount: 5,
                          itemSize: 13,
                          itemBuilder: (_, __) => const Icon(
                            Icons.star_rounded,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${vendor.rating.toStringAsFixed(1)} (${vendor.reviewCount})',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'From LKR ${priceFormatter.format(vendor.startingPriceLkr)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.roseGold,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: isDark ? Colors.white38 : Colors.grey[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable sub-widgets ────────────────────────────────────────────────────

class _BoostBadge extends StatelessWidget {
  final bool small;
  const _BoostBadge({this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 8, vertical: small ? 3 : 4),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: Colors.white, size: small ? 10 : 12),
          SizedBox(width: small ? 2 : 3),
          Text(
            'TOP',
            style: TextStyle(
              color: Colors.white,
              fontSize: small ? 9 : 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final String vendorId;
  final bool isFav;
  final WidgetRef ref;
  final double size;

  const _FavoriteButton({
    required this.vendorId,
    required this.isFav,
    required this.ref,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ref.read(favoritesProvider.notifier).toggle(vendorId);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(isFav),
          color: isFav ? AppColors.roseGold : Colors.grey[400],
          size: size,
        ),
      ),
    );
  }
}
