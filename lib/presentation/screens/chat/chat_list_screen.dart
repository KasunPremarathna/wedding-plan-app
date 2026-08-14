import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/app_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        title: Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? Colors.white : AppColors.deepNavy,
          ),
        ),
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return _buildLoginPrompt(context, ref, isDark);
          }
          return _buildChatList(context, ref, isDark);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context, WidgetRef ref, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 80,
              color: AppColors.roseGold.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Chat with Vendors',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sign in to send messages and receive quotes directly from wedding vendors.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roseGold,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                ref.read(authProvider.notifier).signInWithGoogle();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, WidgetRef ref, bool isDark) {
    final chatRoomsAsync = ref.watch(chatRoomsProvider);

    return chatRoomsAsync.when(
      data: (rooms) {
        if (rooms.isEmpty) {
          return Center(
            child: Text(
              'No messages yet.\nContact a vendor to start chatting!',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                backgroundImage: room.vendorImage.isNotEmpty
                    ? CachedNetworkImageProvider(room.vendorImage)
                    : null,
                child: room.vendorImage.isEmpty
                    ? Text(room.vendorName[0], style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold))
                    : null,
              ),
              title: Text(
                room.vendorName,
                style: TextStyle(
                  fontWeight: room.unreadCount > 0 ? FontWeight.w800 : FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.deepNavy,
                ),
              ),
              subtitle: Text(
                room.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: room.unreadCount > 0 
                      ? (isDark ? Colors.white : AppColors.deepNavy)
                      : (isDark ? Colors.white54 : Colors.grey),
                  fontWeight: room.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat.jm().format(room.lastMessageTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                  if (room.unreadCount > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.roseGold,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        room.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
              onTap: () {
                context.push('/chat/${room.id}', extra: {
                  'vendorId': room.vendorId,
                  'vendorName': room.vendorName,
                  'vendorImage': room.vendorImage,
                });
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
