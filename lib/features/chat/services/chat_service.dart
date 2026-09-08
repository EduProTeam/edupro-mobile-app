import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================================================
  // GET MESSAGES
  // =========================================================

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

  // =========================================================
  // SEND MESSAGE
  // =========================================================

  Future<void> sendMessage(String groupId, String text) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    // Get profile from users collection
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    final userData = userDoc.data();

    final senderName =
        userData?['fullName']?.toString().trim().isNotEmpty == true
        ? userData!['fullName'].toString()
        : user.displayName ?? 'User';

    final senderProfileImageUrl =
        userData?['profileImageUrl']?.toString() ?? '';

    final message = MessageModel(
      senderId: user.uid,
      senderName: senderName,
      senderProfileImageUrl: senderProfileImageUrl,
      text: cleanText,
    );

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .add(message.toMap());
  }
}
