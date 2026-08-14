import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chat_models.dart';
import 'auth_provider.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Stream provider for Chat Rooms
final chatRoomsProvider = StreamProvider<List<ChatRoom>>((ref) {
  final userState = ref.watch(authProvider);
  final db = ref.watch(firebaseFirestoreProvider);

  return userState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      
      return db
          .collection('chatRooms')
          .where('userId', isEqualTo: user.id)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList());
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// Stream provider for Chat Messages in a specific room
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, roomId) {
  final db = ref.watch(firebaseFirestoreProvider);

  return db
      .collection('chatRooms')
      .doc(roomId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
});

// Provider to handle sending messages
final chatServiceProvider = Provider((ref) {
  return ChatService(ref.watch(firebaseFirestoreProvider));
});

class ChatService {
  final FirebaseFirestore _db;

  ChatService(this._db);

  Future<void> sendMessage({
    required String roomId,
    required String senderId,
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
  }
}
