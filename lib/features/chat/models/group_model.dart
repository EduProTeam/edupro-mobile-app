import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String? id;
  final String groupName;
  final String description;
  final String category;
  final String imageUrl;
  final String createdBy;
  final List<String> members;
  final DateTime? createdAt;

  GroupModel({
    this.id,
    required this.groupName,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.createdBy,
    required this.members,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupName': groupName,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'members': members,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GroupModel(
      id: doc.id,
      groupName: data['groupName'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdBy: data['createdBy'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
