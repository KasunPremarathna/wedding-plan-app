import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/chat_models.dart';
import 'auth_provider.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// ─── Chat Rooms: shows both user-side AND vendor-side rooms ──────────────────
final chatRoomsProvider = StreamProvider<List<ChatRoom>>((ref) {
  final userState = ref.watch(authProvider);
  final db = ref.watch(firebaseFirestoreProvider);

  return userState.when(
    data: (user) {
      if (user == null) return const Stream.empty();

      // User-side rooms (bride/groom chatting with vendors)
      final userRooms = db
          .collection('chatRooms')
          .where('userId', isEqualTo: user.id)
          .orderBy('lastMessageTime', descending: true)
          .snapshots();

      // Vendor-side rooms — fetched inside asyncMap below
      // Merge both streams and deduplicate by room id
      return userRooms.asyncMap((userSnap) async {
        final vendorSnap = await db
            .collection('chatRooms')
            .where('vendorId', isEqualTo: user.id)
            .orderBy('lastMessageTime', descending: true)
            .get();

        final seen = <String>{};
        final merged = <ChatRoom>[];

        for (final doc in userSnap.docs) {
          if (seen.add(doc.id)) {
            merged.add(ChatRoom.fromFirestore(doc));
          }
        }
        for (final doc in vendorSnap.docs) {
          if (seen.add(doc.id)) {
            merged.add(ChatRoom.fromFirestore(doc));
          }
        }

        // Sort by lastMessageTime descending
        merged.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        return merged;
      });
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// ─── Chat Messages in a room ─────────────────────────────────────────────────
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, roomId) {
  final db = ref.watch(firebaseFirestoreProvider);

  return db
      .collection('chatRooms')
      .doc(roomId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
});

// ─── Chat Service ─────────────────────────────────────────────────────────────
final chatServiceProvider = Provider((ref) {
  return ChatService(ref.watch(firebaseFirestoreProvider));
});

class ChatService {
  final FirebaseFirestore _db;

  ChatService(this._db);

  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
    required String vendorId,
    required String vendorName,
    required String vendorImage,
  }) async {
    final batch = _db.batch();
    final roomRef = _db.collection('chatRooms').doc(roomId);
    final msgRef = roomRef.collection('messages').doc();

    final messageData = {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    batch.set(msgRef, messageData);

    // Update or create room
    batch.set(roomRef, {
      'userId': senderId,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'vendorImage': vendorImage,
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await batch.commit();

    // ─── Push notification to vendor + Firestore notification entry ───
    _notifyVendor(
      vendorId: vendorId,
      senderName: senderName,
      message: text,
      roomId: roomId,
    );
  }

  Future<void> _notifyVendor({
    required String vendorId,
    required String senderName,
    required String message,
    required String roomId,
  }) async {
    try {
      // Add to vendor_notifications so it shows in vendor dashboard
      await _db.collection('vendor_notifications').add({
        'vendor_id': vendorId,
        'type': 'new_message',
        'title': 'New Message from $senderName',
        'message': message.length > 100 ? '${message.substring(0, 100)}...' : message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'room_id': roomId,
      });

      // Fetch vendor FCM token
      final vendorDoc = await _db
          .collection('vendor_registrations')
          .doc(vendorId)
          .get();
      String? fcmToken = vendorDoc.data()?['fcm_token'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        final userDoc =
            await _db.collection('users').doc(vendorId).get();
        fcmToken = userDoc.data()?['fcm_token'] as String?;
      }

      if (fcmToken != null && fcmToken.isNotEmpty) {
        final dio = Dio();
        await dio.post(
          'https://apiwedding.kasunpremarathna.com/send_notification.php',
          data: {
            'token': fcmToken,
            'title': 'New Message from $senderName',
            'body': message,
            'data': {
              'type': 'chat',
              'room_id': roomId,
              'vendor_id': vendorId,
            },
          },
        );
      }
    } catch (e) {
      // Notification errors are non-critical – ignore silently
    }
  }
}
