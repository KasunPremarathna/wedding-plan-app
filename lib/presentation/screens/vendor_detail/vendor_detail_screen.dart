import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/localization_helper.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  final String vendorId;
  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _trackedView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  void _trackVendorView() {
    if (_trackedView) return;
    _trackedView = true;
    try {
      final userState = ref.read(authProvider);
      final user = userState.asData?.value;
      final viewerName = user?.name ?? 'A guest user';
      FirebaseFirestore.instance.collection('vendor_notifications').add({
        'vendor_id': widget.vendorId.toString(),
        'type': 'profile_view',
        'title': 'New Profile View 👀',
        'message': '$viewerName viewed your profile.',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      debugPrint('Error tracking view: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final vendorAsync = ref.watch(vendorDetailProvider(widget.vendorId));
    AppLocalizations? t;
    try { t = AppLocalizations.of(locale); } catch (_) {}
    t ??= AppLocalizations.of('en');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
      body: vendorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.roseGold)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (vendor) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _trackVendorView());
          return _buildDetail(vendor, isDark, t!);
        },
      ),
    );
  }

  Widget _buildDetail(Vendor vendor, bool isDark, AppLocalizations t) {
    final isFav = ref.watch(favoritesProvider).contains(vendor.id);
    final fmt = NumberFormat('#,###');

    return CustomScrollView(
      slivers: [
        // Hero image appbar
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          leading: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () => ref.read(favoritesProvider.notifier).toggle(vendor.id),
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? AppColors.roseGold : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: CachedNetworkImage(
              imageUrl: vendor.coverImageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                decoration: const BoxDecoration(gradient: AppColors.navyGradient),
                child: const Icon(Icons.storefront_rounded, color: Colors.white54, size: 64),
              ),
            ),
          ),
        ),

        // Vendor info
        SliverToBoxAdapter(
          child: Container(
            color: isDark ? AppColors.darkBg : AppColors.cream,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + badge
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vendor.name,
                                style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.deepNavy,
                                )),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: AppColors.roseGold),
                              const SizedBox(width: 4),
                              Text(vendor.district,
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey[600])),
                            ]),
                          ],
                        ),
                      ),
                      if (vendor.isBoosted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(20)),
                          child: const Text('⚡ TOP', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
                ),

                // Rating row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      RatingBarIndicator(
                        rating: vendor.rating,
                        itemCount: 5,
                        itemSize: 18,
                        itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: AppColors.gold),
                      ),
                      const SizedBox(width: 8),
                      Text(vendor.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.gold)),
                      Text('  (${vendor.reviewCount} reviews)',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey)),
                      const Spacer(),
                      Text('From LKR ${fmt.format(vendor.startingPriceLkr)}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.roseGold)),
                    ],
                  ),
                ),

                // Quick action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Row(
                    children: [
                      Expanded(child: _ActionButton(
                        icon: Icons.phone_rounded, label: t.callVendor,
                        color: AppColors.deepNavy,
                        onTap: () => _launchCall(vendor.phone),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _ActionButton(
                        icon: Icons.chat_rounded, label: t.whatsappInquiry,
                        color: AppColors.whatsappGreen,
                        onTap: () => _launchWhatsApp(vendor.whatsapp),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _ActionButton(
                        icon: Icons.chat_bubble_rounded, label: 'In-App Chat',
                        color: AppColors.roseGold,
                        onTap: () {
                          context.push('/chat/${vendor.id}', extra: {
                            'vendorId': vendor.id,
                            'vendorName': vendor.name,
                            'vendorImage': vendor.coverImageUrl,
                          });
                        },
                      )),
                    ],
                  ),
                ),

                // Tabs
                Container(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.roseGold,
                    indicatorWeight: 3,
                    labelColor: AppColors.roseGold,
                    unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    tabs: [
                      Tab(text: t.packages),
                      Tab(text: t.gallery),
                      Tab(text: t.reviews),
                      Tab(text: t.contact),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tab content
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PackagesTab(vendor: vendor, isDark: isDark, t: t),
              _GalleryTab(vendor: vendor, isDark: isDark),
              _ReviewsTab(vendor: vendor, isDark: isDark, t: t),
              _ContactTab(vendor: vendor, isDark: isDark, t: t),
            ],
          ),
        ),
      ],
    );
  }

  void _launchCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _launchWhatsApp(String number) async {
    final uri = Uri.parse('https://wa.me/$number');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

}

// ─── Action button ───────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ─── Packages Tab ────────────────────────────────────────────────────────────

class _PackagesTab extends StatelessWidget {
  final Vendor vendor;
  final bool isDark;
  final AppLocalizations t;

  const _PackagesTab({required this.vendor, required this.isDark, required this.t});

  static const _tierColors = {
    'basic': Color(0xFF64B5F6),
    'standard': Color(0xFF81C784),
    'gold': Color(0xFFD4AF37),
    'premium': Color(0xFFB76E79),
  };

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    if (vendor.packages.isEmpty) {
      return Center(child: Text('No packages listed', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vendor.packages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final pkg = vendor.packages[i];
        final color = _tierColors[pkg.tier] ?? AppColors.roseGold;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: pkg.isPopular ? Border.all(color: AppColors.gold, width: 2) : null,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    Container(width: 4, height: 22, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(pkg.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isDark ? Colors.white : AppColors.deepNavy)),
                        Text(pkg.tier.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 1)),
                      ]),
                    ),
                    if (pkg.isPopular) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(12)),
                      child: const Text('POPULAR', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ),
                    const SizedBox(width: 8),
                    Text('LKR ${fmt.format(pkg.priceLkr)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: pkg.features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 16, color: color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(f, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.deepNavy))),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (i * 80).ms);
      },
    );
  }
}

// ─── Gallery Tab ─────────────────────────────────────────────────────────────

class _GalleryTab extends StatelessWidget {
  final Vendor vendor;
  final bool isDark;

  const _GalleryTab({required this.vendor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final images = vendor.galleryImages;
    if (images.isEmpty) {
      return Center(child: Text('No gallery images', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6,
      ),
      itemCount: images.length,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: images[i],
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: AppColors.warmGray),
          errorWidget: (_, __, ___) => Container(
            color: AppColors.roseGold.withValues(alpha: 0.1),
            child: const Icon(Icons.image_rounded, color: AppColors.roseGold),
          ),
        ),
      ).animate().fadeIn(delay: (i * 50).ms),
    );
  }
}

// ─── Reviews Tab ─────────────────────────────────────────────────────────────

final vendorReviewsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, vendorId) {
  return FirebaseFirestore.instance
      .collection('vendor_registrations')
      .doc(vendorId)
      .collection('reviews')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

class _ReviewsTab extends ConsumerWidget {
  final Vendor vendor;
  final bool isDark;
  final AppLocalizations t;

  const _ReviewsTab({required this.vendor, required this.isDark, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreReviewsAsync = ref.watch(vendorReviewsProvider(vendor.id.toString()));

    return firestoreReviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.roseGold)),
      error: (e, _) => const Center(child: Text('Error loading reviews')),
      data: (firestoreReviews) {
        final List<Map<String, dynamic>> allReviews = [];
        
        for (var fr in firestoreReviews) {
          allReviews.add(fr);
        }
        
        for (var r in vendor.reviews) {
          allReviews.add({
            'userName': r.userName,
            'rating': r.rating,
            'comment': r.comment,
            'date': r.date,
          });
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => _WriteReviewSheet(vendorId: vendor.id.toString(), isDark: isDark),
                  );
                },
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Write a Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.roseGold,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (allReviews.isEmpty)
              Expanded(child: Center(child: Text('No reviews yet', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey))))
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: allReviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final r = allReviews[i];
                    final rating = (r['rating'] as num).toDouble();
                    final userName = r['userName'] as String? ?? 'User';
                    final date = r['date'] as String? ?? '';
                    final comment = r['comment'] as String? ?? '';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.roseGold.withValues(alpha: 0.2),
                            child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppColors.roseGold, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(userName, style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.deepNavy)),
                            Text(date, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey)),
                          ])),
                          RatingBarIndicator(rating: rating, itemCount: 5, itemSize: 13,
                              itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: AppColors.gold)),
                        ]),
                        const SizedBox(height: 10),
                        Text(comment, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey[700], height: 1.5)),
                      ]),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WriteReviewSheet extends ConsumerStatefulWidget {
  final String vendorId;
  final bool isDark;
  
  const _WriteReviewSheet({required this.vendorId, required this.isDark});

  @override
  ConsumerState<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<_WriteReviewSheet> {
  double _rating = 5.0;
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write a comment')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final userState = ref.read(authProvider);
      final user = userState.asData?.value;
      
      final userName = user?.name ?? 'Guest User';
      
      final vendorRef = FirebaseFirestore.instance.collection('vendor_registrations').doc(widget.vendorId);
      final reviewsRef = vendorRef.collection('reviews');
      
      await reviewsRef.add({
        'userId': user?.id ?? 'guest',
        'userName': userName,
        'rating': _rating,
        'comment': _commentCtrl.text.trim(),
        'date': DateFormat('MMM d, yyyy').format(DateTime.now()),
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      final snapshot = await reviewsRef.get();
      if (snapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in snapshot.docs) {
          totalRating += (doc.data()['rating'] as num).toDouble();
        }
        final avgRating = totalRating / snapshot.docs.length;
        await vendorRef.update({
          'rating': avgRating,
          'review_count': snapshot.docs.length,
        });
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Write a Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: widget.isDark ? Colors.white : AppColors.deepNavy)),
          const SizedBox(height: 20),
          RatingBar.builder(
            initialRating: 5,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: AppColors.gold),
            onRatingUpdate: (rating) => _rating = rating,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _commentCtrl,
            maxLines: 4,
            style: TextStyle(color: widget.isDark ? Colors.white : AppColors.deepNavy),
            decoration: InputDecoration(
              hintText: 'Share your experience with this vendor...',
              hintStyle: TextStyle(color: widget.isDark ? Colors.white38 : Colors.grey),
              filled: true,
              fillColor: widget.isDark ? AppColors.darkCard : AppColors.warmGray,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roseGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contact Tab ─────────────────────────────────────────────────────────────

class _ContactTab extends StatelessWidget {
  final Vendor vendor;
  final bool isDark;
  final AppLocalizations t;

  const _ContactTab({required this.vendor, required this.isDark, required this.t});

  @override
  Widget build(BuildContext context) {
    final items = [
      if (vendor.phone.isNotEmpty) _ContactItem(icon: Icons.phone_rounded, label: 'Phone', value: vendor.phone, color: AppColors.deepNavy, url: 'tel:${vendor.phone}'),
      if (vendor.whatsapp.isNotEmpty) _ContactItem(icon: Icons.chat_rounded, label: 'WhatsApp', value: vendor.whatsapp, color: AppColors.whatsappGreen, url: 'https://wa.me/${vendor.whatsapp}'),
      if (vendor.email.isNotEmpty) _ContactItem(icon: Icons.email_rounded, label: 'Email', value: vendor.email, color: AppColors.roseGold, url: 'mailto:${vendor.email}'),
      if (vendor.website.isNotEmpty) _ContactItem(icon: Icons.language_rounded, label: 'Website', value: vendor.website, color: AppColors.deepNavy, url: vendor.website),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (vendor.description.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(vendor.description, style: TextStyle(fontSize: 14, height: 1.6, color: isDark ? Colors.white70 : Colors.grey[700])),
          ),
          const SizedBox(height: 16),
        ],
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () async { final uri = Uri.parse(item.url); if (await canLaunchUrl(uri)) launchUrl(uri); },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: item.color.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: item.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey)),
                  Text(item.value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.deepNavy)),
                ])),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: item.color),
              ]),
            ),
          ),
        )),
      ],
    );
  }
}

class _ContactItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String url;
  const _ContactItem({required this.icon, required this.label, required this.value, required this.color, required this.url});
}
