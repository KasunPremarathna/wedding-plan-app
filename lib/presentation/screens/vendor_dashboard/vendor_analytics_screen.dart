import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';

enum AnalyticsPeriod { thisMonth, thisYear, allTime }

class VendorAnalyticsScreen extends ConsumerStatefulWidget {
  const VendorAnalyticsScreen({super.key});

  @override
  ConsumerState<VendorAnalyticsScreen> createState() =>
      _VendorAnalyticsScreenState();
}

class _VendorAnalyticsScreenState extends ConsumerState<VendorAnalyticsScreen> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.thisMonth;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final user = ref.watch(authProvider).asData?.value;
    final vendorId = user?.id ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        title: Text(
          'Analytics & Reports',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? Colors.white : AppColors.deepNavy,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.deepNavy,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: vendorId.isEmpty
          ? Center(
              child: Text(
                'Please log in.',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
              ),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vendor_registrations')
                  .doc(vendorId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.roseGold),
                  );
                }

                final vendorData =
                    snapshot.data?.data() as Map<String, dynamic>? ?? {};

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('vendor_registrations')
                      .doc(vendorId)
                      .collection('analytics_logs')
                      .snapshots(),
                  builder: (context, logSnapshot) {
                    final logs = logSnapshot.data?.docs ?? [];
                    final filteredStats = _filterLogs(logs, vendorData);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filter Segmented Buttons
                          _buildPeriodFilter(isDark),
                          const SizedBox(height: 24),

                          // Summary Overview Header
                          Text(
                            _getPeriodTitle(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.deepNavy,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Stats Grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.3,
                            children: [
                              _AnalyticsStatCard(
                                icon: Icons.visibility_rounded,
                                title: 'Profile Views',
                                value: '${filteredStats['profile_views']}',
                                color: Colors.blueAccent,
                                isDark: isDark,
                              ),
                              _AnalyticsStatCard(
                                icon: Icons.picture_as_pdf_rounded,
                                title: 'Package Views',
                                value: '${filteredStats['package_views']}',
                                color: Colors.purpleAccent,
                                isDark: isDark,
                              ),
                              _AnalyticsStatCard(
                                icon: Icons.chat_rounded,
                                title: 'Inquiries',
                                value: '${filteredStats['inquiries']}',
                                color: AppColors.whatsappGreen,
                                isDark: isDark,
                              ),
                              _AnalyticsStatCard(
                                icon: Icons.favorite_rounded,
                                title: 'Favorites Saved',
                                value: '${vendorData['favorites_count'] ?? 0}',
                                color: AppColors.roseGold,
                                isDark: isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Monthly Breakdown Report Card
                          _buildBreakdownCard(isDark, filteredStats),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildPeriodFilter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.roseGold.withValues(alpha: 0.2)
              : AppColors.warmGray,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _filterTab(
              'This Month',
              AnalyticsPeriod.thisMonth,
              isDark,
            ),
          ),
          Expanded(
            child: _filterTab(
              'This Year',
              AnalyticsPeriod.thisYear,
              isDark,
            ),
          ),
          Expanded(
            child: _filterTab(
              'All Time',
              AnalyticsPeriod.allTime,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTab(String label, AnalyticsPeriod period, bool isDark) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.roseGoldGradient : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white60 : AppColors.deepNavy),
          ),
        ),
      ),
    );
  }

  String _getPeriodTitle() {
    switch (_selectedPeriod) {
      case AnalyticsPeriod.thisMonth:
        return 'Summary for ${DateFormat('MMMM yyyy').format(DateTime.now())}';
      case AnalyticsPeriod.thisYear:
        return 'Summary for ${DateTime.now().year}';
      case AnalyticsPeriod.allTime:
        return 'All Time Lifetime Performance';
    }
  }

  Map<String, int> _filterLogs(
      List<QueryDocumentSnapshot> logs, Map<String, dynamic> vendorData) {
    int profileViews = 0;
    int packageViews = 0;
    int inquiries = 0;

    final now = DateTime.now();

    for (final doc in logs) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? ts = data['created_at'] as Timestamp?;
      if (ts == null) continue;

      final dt = ts.toDate();
      bool include = false;

      if (_selectedPeriod == AnalyticsPeriod.thisMonth) {
        if (dt.year == now.year && dt.month == now.month) include = true;
      } else if (_selectedPeriod == AnalyticsPeriod.thisYear) {
        if (dt.year == now.year) include = true;
      } else {
        include = true;
      }

      if (include) {
        final type = data['type'] as String?;
        if (type == 'profile_view') profileViews++;
        if (type == 'package_view') packageViews++;
        if (type == 'inquiry') inquiries++;
      }
    }

    // Fallback to lifetime overall numbers if logs array is smaller
    if (_selectedPeriod == AnalyticsPeriod.allTime) {
      profileViews = (vendorData['profile_views'] as int?) ?? profileViews;
      packageViews = (vendorData['package_views'] as int?) ?? packageViews;
      inquiries = (vendorData['inquiries_count'] as int?) ?? inquiries;
    }

    return {
      'profile_views': profileViews,
      'package_views': packageViews,
      'inquiries': inquiries,
    };
  }

  Widget _buildBreakdownCard(bool isDark, Map<String, int> stats) {
    final totalInteractions =
        stats['profile_views']! + stats['package_views']! + stats['inquiries']!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.roseGold.withValues(alpha: 0.2)
              : AppColors.warmGray,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded,
                  color: AppColors.roseGold, size: 22),
              const SizedBox(width: 10),
              Text(
                'Engagement Ratio Report',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.deepNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProgressBarRow(
            label: 'Profile Visits',
            count: stats['profile_views']!,
            total: totalInteractions,
            color: Colors.blueAccent,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _ProgressBarRow(
            label: 'Package Brochure Views',
            count: stats['package_views']!,
            total: totalInteractions,
            color: Colors.purpleAccent,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _ProgressBarRow(
            label: 'Inquiries Initiated',
            count: stats['inquiries']!,
            total: totalInteractions,
            color: AppColors.whatsappGreen,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _AnalyticsStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isDark;

  const _AnalyticsStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressBarRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final bool isDark;

  const _ProgressBarRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total) : 0.0;
    final pctStr = (pct * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppColors.deepNavy,
              ),
            ),
            Text(
              '$count ($pctStr%)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
