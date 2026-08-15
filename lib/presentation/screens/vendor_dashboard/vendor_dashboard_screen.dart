import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

final currentVendorProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(authProvider).asData?.value;
  if (user == null) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('vendor_registrations')
      .doc(user.id)
      .snapshots()
      .map((doc) => doc.exists ? doc.data() : null);
});

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final vendorAsync = ref.watch(currentVendorProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        title: Text('Vendor Dashboard',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: isDark ? Colors.white : AppColors.deepNavy)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.deepNavy),
          onPressed: () => context.pop(),
        ),
        actions: [
          vendorAsync.maybeWhen(
            data: (vendor) => vendor == null
                ? const SizedBox.shrink()
                : IconButton(
                    icon: Icon(Icons.share_rounded, color: isDark ? Colors.white : AppColors.deepNavy),
                    tooltip: 'Share Profile',
                    onPressed: () => _shareVendorProfile(vendor),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications_none_rounded, color: isDark ? Colors.white : AppColors.deepNavy),
                Positioned(
                  right: 2, top: 2,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.roseGold, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            onPressed: () => context.push('/vendor-notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: vendorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.roseGold)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (vendor) {
          if (vendor == null) return const Center(child: Text('Vendor data not found.'));
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildWelcomeCard(isDark, vendor),
              const SizedBox(height: 16),
              _buildAvailabilityCard(isDark, vendor, ref),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Manage Business', isDark: isDark),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _DashboardActionCard(icon: Icons.store_mall_directory_rounded, title: 'Profile', subtitle: 'Edit details & cover', color: AppColors.gold, isDark: isDark, onTap: () => context.push('/vendor-edit-profile'))),
                  const SizedBox(width: 16),
                  Expanded(child: _DashboardActionCard(icon: Icons.inventory_2_rounded, title: 'Packages', subtitle: 'Set prices & PDF', color: Colors.blueAccent, isDark: isDark, onTap: () => context.push('/vendor-packages'))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _DashboardActionCard(icon: Icons.photo_library_rounded, title: 'Portfolio', subtitle: 'Upload photos', color: Colors.purpleAccent, isDark: isDark, onTap: () => context.push('/vendor-portfolio'))),
                  const SizedBox(width: 16),
                  Expanded(child: _DashboardActionCard(icon: Icons.chat_bubble_rounded, title: 'Messages', subtitle: 'View chats', color: AppColors.whatsappGreen, isDark: isDark, onTap: () => context.push('/chat'))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _DashboardActionCard(icon: Icons.handshake_rounded, title: 'Partners', subtitle: 'Recommend vendors', color: Colors.teal, isDark: isDark, onTap: () => context.push('/vendor-recommendations'))),
                ],
              ),
              const SizedBox(height: 32),
              _SectionTitle(title: 'Analytics Overview', isDark: isDark),
              const SizedBox(height: 12),
              _buildAnalyticsCard(context, isDark, vendor),
            ],
          );
        }
      ),
    );
  }

  Widget _buildWelcomeCard(bool isDark, Map<String, dynamic> vendor) {
    final name = vendor['name'] ?? 'My Business Name';
    final rating = (vendor['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = vendor['review_count'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.navyGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.roseGold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.roseGold, size: 16),
                    const SizedBox(width: 4),
                    Text('${rating.toStringAsFixed(1)} Rating', style: const TextStyle(color: AppColors.roseGold, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.comment_rounded, color: AppColors.gold, size: 16),
                    const SizedBox(width: 4),
                    Text('$reviewCount Reviews', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _shareVendorProfile(vendor),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '🔗 Share My Vendor Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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

  void _shareVendorProfile(Map<String, dynamic> vendor) {
    final name = vendor['name'] ?? 'My Business';
    final category = (vendor['category'] ?? 'Wedding Vendor').toString().replaceAll('_', ' ').toUpperCase();
    final district = vendor['district'] ?? 'Sri Lanka';
    final rating = (vendor['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = vendor['review_count'] ?? 0;

    final text = '''
💍 Check out $name on Wedding Planner LK! 💍

👑 Category: $category
📍 Location: $district
⭐ Rating: ${rating.toStringAsFixed(1)} ($reviewCount Reviews)

📱 Open the Wedding Planner LK App to view our full packages, photo gallery & contact us directly!
''';

    // ignore: deprecated_member_use
    Share.share(text, subject: 'Check out $name on Wedding Planner LK');
  }

  Widget _buildAvailabilityCard(bool isDark, Map<String, dynamic> vendor, WidgetRef ref) {
    final isAvailable = vendor['is_available'] as bool? ?? true;
    final vendorId = vendor['id'] ?? ref.watch(authProvider).asData?.value?.id ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailable
              ? AppColors.whatsappGreen.withValues(alpha: 0.3)
              : Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAvailable
                  ? AppColors.whatsappGreen.withValues(alpha: 0.15)
                  : Colors.redAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAvailable ? Icons.check_circle_rounded : Icons.do_not_disturb_on_rounded,
              color: isAvailable ? AppColors.whatsappGreen : Colors.redAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvailable ? 'Accepting Bookings' : 'Currently Unavailable',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.deepNavy,
                  ),
                ),
                Text(
                  isAvailable ? 'Visible to couples seeking services' : 'Hidden from active search',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            activeTrackColor: AppColors.whatsappGreen,
            onChanged: (val) async {
              if (vendorId.toString().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('vendor_registrations')
                    .doc(vendorId.toString())
                    .update({'is_available': val});
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(BuildContext context, bool isDark, Map<String, dynamic> vendor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _StatRow(label: 'Profile Views', value: '${vendor['profile_views'] ?? 0}', isDark: isDark),
          Divider(color: isDark ? Colors.white10 : Colors.grey[200], height: 24),
          _StatRow(label: 'Package & PDF Brochure Views', value: '${vendor['package_views'] ?? 0}', isDark: isDark),
          Divider(color: isDark ? Colors.white10 : Colors.grey[200], height: 24),
          _StatRow(label: 'WhatsApp Inquiries', value: '${vendor['inquiries_count'] ?? 0}', isDark: isDark),
          Divider(color: isDark ? Colors.white10 : Colors.grey[200], height: 24),
          _StatRow(label: 'Saved to Favorites', value: '${vendor['favorites_count'] ?? 0}', isDark: isDark),
          Divider(color: isDark ? Colors.white10 : Colors.grey[200], height: 24),
          InkWell(
            onTap: () => context.push('/vendor-analytics'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.roseGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded, color: AppColors.roseGold, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'View Full Reports & Monthly Summary →',
                    style: TextStyle(
                      color: AppColors.roseGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.deepNavy));
  }
}

class _DashboardActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _DashboardActionCard({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.isDark, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title - Coming soon!')));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isDark ? Colors.white : AppColors.deepNavy)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _StatRow({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700], fontSize: 14)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.deepNavy, fontSize: 16)),
      ],
    );
  }
}

