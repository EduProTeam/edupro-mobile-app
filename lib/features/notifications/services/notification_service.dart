import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ============================================================
  // CREATE ONE NOTIFICATION
  // ============================================================

  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    required String groupId,
    required String groupName,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'groupId': groupId,
      'groupName': groupName,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // CURRENT USER NOTIFICATIONS
  // ============================================================

  Stream<List<AppNotificationModel>> getNotifications() {
    final uid = currentUserId;

    if (uid == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => AppNotificationModel.fromFirestore(doc))
              .toList();

          // Newest notifications first
          notifications.sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

            return bDate.compareTo(aDate);
          });

          return notifications;
        });
  }

  // ============================================================
  // UNREAD
  // ============================================================

  Stream<List<AppNotificationModel>> getUnreadNotifications() {
    return getNotifications().map((notifications) {
      return notifications
          .where((notification) => !notification.isRead)
          .toList();
    });
  }

  // ============================================================
  // UNREAD COUNT
  // ============================================================

  Stream<int> getUnreadCount() {
    return getUnreadNotifications().map(
      (notifications) => notifications.length,
    );
  }

  // ============================================================
  // MARK AS READ
  // ============================================================

  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }
}
