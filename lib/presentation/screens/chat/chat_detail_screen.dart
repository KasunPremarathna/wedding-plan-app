import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/app_providers.dart';
import 'package:dio/dio.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String vendorId;
  final String vendorName;
  final String vendorImage;

  const ChatDetailScreen({
    super.key,
    required this.roomId,
    required this.vendorId,
    required this.vendorName,
    required this.vendorImage,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userState = ref.read(authProvider);
    userState.whenData((user) {
      if (user != null) {
        ref.read(chatServiceProvider).sendMessage(
          roomId: widget.roomId,
          senderId: user.id,
          text: _messageController.text.trim(),
          vendorId: widget.vendorId,
          vendorName: widget.vendorName,
          vendorImage: widget.vendorImage,
        );

        try {
          FirebaseFirestore.instance.collection('vendor_notifications').add({
            'vendor_id': widget.vendorId.toString(),
            'type': 'new_message',
            'title': 'New Message 💬',
            'message': '${user.name} sent you a message',
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });
          
          final text = _messageController.text.trim();
          
          // Send background push notification
          FirebaseFirestore.instance
              .collection('vendor_registrations')
              .doc(widget.vendorId)
              .get()
              .then((doc) async {
            if (doc.exists) {
              final token = doc.data()?['fcm_token'];
              if (token != null && token.toString().isNotEmpty) {
                try {
                  final dio = Dio();
                  await dio.post(
                    'https://apiwedding.kasunpremarathna.com/send_notification.php',
                    data: {
                      'token': token,
                      'title': 'New Message from ${user.name}',
                      'body': text,
                      'data': {
                        'type': 'chat',
                        'roomId': widget.roomId,
                      }
                    },
                  );
                } catch (e) {
                  debugPrint('Error sending FCM push: $e');
                }
              }
            }
          });
        } catch (e) {
          debugPrint('Error tracking chat notification: $e');
        }

        _messageController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final userState = ref.watch(authProvider);
    final currentUserId = userState.asData?.value?.id ?? '';
    
    final messagesAsync = ref.watch(chatMessagesProvider(widget.roomId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.gold.withValues(alpha: 0.2),
              backgroundImage: widget.vendorImage.isNotEmpty
                  ? CachedNetworkImageProvider(widget.vendorImage)
                  : null,
              child: widget.vendorImage.isEmpty
                  ? Text(widget.vendorName[0], style: const TextStyle(color: AppColors.gold, fontSize: 16))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.vendorName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.deepNavy,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('Send a message to start the conversation'));
                }
                return ListView.builder(
                  reverse: true, // Show newest at the bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe 
                              ? AppColors.roseGold 
                              : (isDark ? AppColors.darkCard : Colors.white),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: isMe 
                                ? Colors.white 
                                : (isDark ? Colors.white : AppColors.deepNavy),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          
          // Chat Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBg : AppColors.cream,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        style: TextStyle(color: isDark ? Colors.white : AppColors.deepNavy),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: AppColors.roseGold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
