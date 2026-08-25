import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream Messages in Realtime
  Stream<List<MessageModel>> getMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList();
        });
  }

  // Send Message
  Future<void> sendMessage(String groupId, String text) async {
    final user = _auth.currentUser;
    if (user == null || text.trim().isEmpty) return;

    String senderName = user.displayName ?? 'User ${user.uid.substring(0, 4)}';

    final message = MessageModel(
      senderId: user.uid,
      senderName: senderName,
      text: text.trim(),
    );

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .add(message.toMap());
  }
}
