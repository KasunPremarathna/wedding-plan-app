import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';

class VendorNotificationsScreen extends ConsumerWidget {
  const VendorNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final user = ref.watch(authProvider).value;
    final vendorId = user?.id;

    if (vendorId == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.deepNavy),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text('Please log in to view notifications.', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        title: Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : AppColors.deepNavy)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.deepNavy),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vendor_notifications')
            .where('vendor_id', isEqualTo: vendorId)
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading notifications', style: TextStyle(color: isDark ? Colors.white : Colors.black)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.roseGold));
          }

          final docs = snapshot.data?.docs ?? [];
          
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 64, color: isDark ? Colors.white24 : Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isRead = data['read'] ?? false;
              final type = data['type'] ?? 'info';
              final timestamp = data['timestamp'] as Timestamp?;
              
              String timeAgo = '';
              if (timestamp != null) {
                final diff = DateTime.now().difference(timestamp.toDate());
                if (diff.inMinutes < 60) {
                  timeAgo = '${diff.inMinutes}m ago';
                } else if (diff.inHours < 24) {
                  timeAgo = '${diff.inHours}h ago';
                } else {
                  timeAgo = DateFormat('MMM d').format(timestamp.toDate());
                }
              }

              IconData icon;
              Color color;
              if (type == 'new_message') {
                icon = Icons.chat_bubble_rounded;
                color = AppColors.whatsappGreen;
              } else if (type == 'profile_view') {
                icon = Icons.remove_red_eye_rounded;
                color = AppColors.gold;
              } else {
                icon = Icons.notifications_rounded;
                color = AppColors.roseGold;
              }

              return InkWell(
                onTap: () {
                  if (!isRead) {
                    docs[index].reference.update({'read': true});
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead 
                          ? Colors.transparent 
                          : AppColors.roseGold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  data['title'] ?? 'Notification',
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                    color: isDark ? Colors.white : AppColors.deepNavy,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  timeAgo,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isRead ? (isDark ? Colors.white38 : Colors.grey) : AppColors.roseGold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data['message'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isRead)
                        Container(
                          margin: const EdgeInsets.only(left: 12, top: 8),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.roseGold,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
