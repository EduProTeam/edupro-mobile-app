import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Stream Categories
  Stream<List<String>> getCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc['name'].toString()).toList();
    });
  }

  // Stream Groups
  Stream<List<GroupModel>> getGroups() {
    return _firestore
        .collection('groups')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GroupModel.fromFirestore(doc))
              .toList();
        });
  }

  Stream<List<GroupModel>> getFilteredGroups({
    String searchQuery = '',
    String category = 'All',
    bool onlyMyGroups = false,
  }) {
    return getGroups().map((groups) {
      var filteredGroups = List<GroupModel>.from(groups);

      final uid = currentUserId;

      // My Groups only
      // if (onlyMyGroups && uid != null) {
      //   filteredGroups = filteredGroups.where((group) {
      //     return group.members.contains(uid) || group.createdBy == uid;
      //   }).toList();
      // }

      // Category filter
      if (category != 'All') {
        filteredGroups = filteredGroups.where((group) {
          return group.category.toLowerCase() == category.toLowerCase();
        }).toList();
      }

      // Search filter
      final query = searchQuery.trim().toLowerCase();

      if (query.isNotEmpty) {
        filteredGroups = filteredGroups.where((group) {
          final name = group.groupName.toLowerCase();
          final description = group.description.toLowerCase();
          final groupCategory = group.category.toLowerCase();

          return name.contains(query) ||
              description.contains(query) ||
              groupCategory.contains(query);
        }).toList();
      }

      return filteredGroups;
    });
  }

  // Create Group
  Future<void> createGroup({
    required String groupName,
    required String description,
    required String category,
    required String imageUrl,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    final group = GroupModel(
      groupName: groupName,
      description: description,
      category: category,
      imageUrl: imageUrl,
      createdBy: uid,
      members: [uid],
    );

    await _firestore.collection('groups').add(group.toMap());
  }

  // Join Group
  Future<void> joinGroup(String groupId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([uid]),
    });
  }

  // Exit Group
  Future<void> exitGroup(String groupId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([uid]),
    });
  }

  // Update Group Details (Creator Only)
  Future<void> updateGroup(String groupId, String name, String desc) async {
    await _firestore.collection('groups').doc(groupId).update({
      'groupName': name,
      'description': desc,
    });
  }

  bool isCurrentUserMember(GroupModel group) {
    final uid = currentUserId;

    if (uid == null) {
      return false;
    }

    return group.members.contains(uid);
  }

  bool isCurrentUserAdmin(GroupModel group) {
    final uid = currentUserId;

    if (uid == null) {
      return false;
    }

    return group.createdBy == uid;
  }

  // Delete Group (Creator Only)
  Future<void> deleteGroup(String groupId) async {
    await _firestore.collection('groups').doc(groupId).delete();
  }
}
