import 'package:cloud_firestore/cloud_firestore.dart';

class PostComment {
  const PostComment({
    required this.id,
    required this.userName,
    required this.text,
    this.profileImageUrl,
    this.createdAt,
  });

  factory PostComment.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    return PostComment(
      id: document.id,
      userName: data['userName'] is String ? data['userName'] : 'EduPro user',
      text: data['text'] is String ? data['text'] : '',
      profileImageUrl: data['profileImageUrl'] is String
          ? data['profileImageUrl']
          : null,
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] : null,
    );
  }

  final String id;
  final String userName;
  final String text;
  final String? profileImageUrl;
  final Timestamp? createdAt;
}
