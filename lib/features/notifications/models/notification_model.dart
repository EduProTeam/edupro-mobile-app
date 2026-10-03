import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final String groupId;
  final String groupName;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.groupId,
    required this.groupName,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return AppNotificationModel(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      groupId: data['groupId']?.toString() ?? '',
      groupName: data['groupName']?.toString() ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
