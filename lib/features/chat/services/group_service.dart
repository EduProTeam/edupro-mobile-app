import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group_model.dart';
import '../models/group_member_model.dart';
import '../../notifications/services/notification_service.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final NotificationService _notificationService = NotificationService();

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? get currentUserId => _auth.currentUser?.uid;

  // ============================================================
  // GET USER NAME
  // ============================================================

  Future<String> _getUserName(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    final data = doc.data();

    final fullName = data?['fullName']?.toString().trim() ?? '';

    if (fullName.isNotEmpty) {
      return fullName;
    }

    final email = data?['email']?.toString().trim() ?? '';

    if (email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'A member';
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Stream<List<String>> getCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc['name'].toString()).toList();
    });
  }

  // ============================================================
  // ALL GROUPS
  // ============================================================

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

  // ============================================================
  // SINGLE GROUP - REALTIME
  // ============================================================

  Stream<GroupModel?> watchGroup(String groupId) {
    return _firestore.collection('groups').doc(groupId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }

      return GroupModel.fromFirestore(doc);
    });
  }

  // ============================================================
  // FILTERED GROUPS
  // ============================================================

  Stream<List<GroupModel>> getFilteredGroups({
    String searchQuery = '',
    String category = 'All',
    bool onlyMyGroups = false,
  }) {
    return getGroups().map((groups) {
      var filteredGroups = List<GroupModel>.from(groups);

      final uid = currentUserId;

      // My Groups
      if (onlyMyGroups && uid != null) {
        filteredGroups = filteredGroups.where((group) {
          return group.members.contains(uid) || group.createdBy == uid;
        }).toList();
      }

      // Category
      if (category != 'All') {
        filteredGroups = filteredGroups.where((group) {
          return group.category.toLowerCase() == category.toLowerCase();
        }).toList();
      }

      // Search
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

  // ============================================================
  // CREATE GROUP
  // Creator becomes Admin + Member
  // ============================================================

  Future<void> createGroup({
    required String groupName,
    required String description,
    required String category,
    required String imageUrl,
  }) async {
    final uid = currentUserId;

    if (uid == null) {
      throw Exception('User not logged in');
    }

    final group = GroupModel(
      groupName: groupName.trim(),
      description: description.trim(),
      category: category,
      imageUrl: imageUrl.trim(),

      // Creator
      createdBy: uid,

      // Creator automatically Admin
      admins: [uid],

      // Creator automatically Member
      members: [uid],
    );

    await _firestore.collection('groups').add(group.toMap());
  }

  // ============================================================
  // JOIN GROUP
  // ============================================================

  Future<void> joinGroup(String groupId) async {
    final uid = currentUserId;

    if (uid == null) {
      throw Exception('User not logged in');
    }

    final groupRef = _firestore.collection('groups').doc(groupId);

    final snapshot = await groupRef.get();

    if (!snapshot.exists) {
      throw Exception('Group not found');
    }

    final data = snapshot.data();

    if (data == null) {
      throw Exception('Group data not found');
    }

    final members = List<String>.from(data['members'] ?? []);

    // Already joined
    if (members.contains(uid)) {
      return;
    }

    final createdBy = data['createdBy']?.toString() ?? '';

    final admins = data['admins'] != null
        ? List<String>.from(data['admins'])
        : createdBy.isNotEmpty
        ? [createdBy]
        : <String>[];

    final groupName = data['groupName']?.toString() ?? 'Group';

    // Add member
    await groupRef.update({
      'members': FieldValue.arrayUnion([uid]),
    });

    final memberName = await _getUserName(uid);

    // Notify all admins
    for (final adminId in admins.toSet()) {
      if (adminId == uid) {
        continue;
      }

      await _notificationService.createNotification(
        userId: adminId,
        type: 'member_joined',
        title: 'New Member Joined',
        message: '$memberName joined $groupName.',
        groupId: groupId,
        groupName: groupName,
      );
    }
  }

  // ============================================================
  // MEMBER CHECK
  // ============================================================

  bool isCurrentUserMember(GroupModel group) {
    final uid = currentUserId;

    if (uid == null) {
      return false;
    }

    return group.members.contains(uid);
  }

  // ============================================================
  // ADMIN CHECK
  // IMPORTANT: Check admins[], not only createdBy
  // ============================================================

  bool isCurrentUserAdmin(GroupModel group) {
    final uid = currentUserId;

    if (uid == null) {
      return false;
    }

    return group.admins.contains(uid);
  }

  // ============================================================
  // EXIT GROUP
  // ============================================================

  Future<void> exitGroup(String groupId) async {
    final uid = currentUserId;

    if (uid == null) {
      throw Exception('User not logged in');
    }

    final groupRef = _firestore.collection('groups').doc(groupId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(groupRef);

      if (!snapshot.exists) {
        throw Exception('Group not found');
      }

      final data = snapshot.data();

      if (data == null) {
        throw Exception('Group data not found');
      }

      final members = List<String>.from(data['members'] ?? []);

      final createdBy = data['createdBy']?.toString() ?? '';

      final admins = data['admins'] != null
          ? List<String>.from(data['admins'])
          : createdBy.isNotEmpty
          ? [createdBy]
          : <String>[];

      // User is not a member
      if (!members.contains(uid)) {
        throw Exception('You are not a member of this group.');
      }

      // Remove from members
      members.remove(uid);

      // Remove from admins too
      admins.remove(uid);

      // Ensure admins are still members
      admins.removeWhere((adminId) => !members.contains(adminId));

      // Last member exits
      if (members.isEmpty) {
        transaction.delete(groupRef);
        return;
      }

      // Admin exited and there is no admin left
      if (admins.isEmpty) {
        final random = Random();

        final newAdmin = members[random.nextInt(members.length)];

        admins.add(newAdmin);
      }

      var newCreatedBy = createdBy;

      // Original creator exited
      if (createdBy == uid || !members.contains(createdBy)) {
        newCreatedBy = admins.first;
      }

      transaction.update(groupRef, {
        'members': members,
        'admins': admins,
        'createdBy': newCreatedBy,
      });
    });
  }

  // ============================================================
  // UPDATE GROUP - ADMIN ONLY
  // ============================================================

  Future<void> updateGroupDetails({
    required String groupId,
    required String groupName,
    required String description,
    required String category,
  }) async {
    final uid = currentUserId;

    if (uid == null) {
      throw Exception('User not logged in');
    }

    if (groupName.trim().isEmpty) {
      throw Exception('Group name cannot be empty.');
    }

    if (description.trim().isEmpty) {
      throw Exception('Description cannot be empty.');
    }

    final groupRef = _firestore.collection('groups').doc(groupId);

    final snapshot = await groupRef.get();

    if (!snapshot.exists) {
      throw Exception('Group not found');
    }

    final data = snapshot.data();

    if (data == null) {
      throw Exception('Group data not found');
    }

    final createdBy = data['createdBy']?.toString() ?? '';

    final admins = data['admins'] != null
        ? List<String>.from(data['admins'])
        : createdBy.isNotEmpty
        ? [createdBy]
        : <String>[];

    // Security check
    if (!admins.contains(uid)) {
      throw Exception('Only group admins can update this group.');
    }

    await groupRef.update({
      'groupName': groupName.trim(),
      'description': description.trim(),
      'category': category,
    });
  }

  // ============================================================
  // DELETE GROUP - ADMIN ONLY
  // ============================================================

  Future<void> deleteGroup(String groupId) async {
    final uid = currentUserId;

    if (uid == null) {
      throw Exception('User not logged in');
    }

    final groupRef = _firestore.collection('groups').doc(groupId);

    final snapshot = await groupRef.get();

    if (!snapshot.exists) {
      throw Exception('Group not found');
    }

    final data = snapshot.data();

    if (data == null) {
      throw Exception('Group data not found');
    }

    final createdBy = data['createdBy']?.toString() ?? '';

    final admins = data['admins'] != null
        ? List<String>.from(data['admins'])
        : createdBy.isNotEmpty
        ? [createdBy]
        : <String>[];

    if (!admins.contains(uid)) {
      throw Exception('Only an admin can delete this group.');
    }

    final members = List<String>.from(data['members'] ?? []);

    final groupName = data['groupName']?.toString() ?? 'Group';

    // ------------------------------------------------------------
    // Create notifications + delete group in one batch
    // ------------------------------------------------------------

    final batch = _firestore.batch();

    for (final memberId in members.toSet()) {
      // User deleting the group doesn't need notification
      if (memberId == uid) {
        continue;
      }

      final notificationRef = _firestore.collection('notifications').doc();

      batch.set(notificationRef, {
        'userId': memberId,
        'type': 'group_deleted',
        'title': 'Group Deleted',
        'message': '$groupName was deleted by an admin.',
        'groupId': groupId,
        'groupName': groupName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    batch.delete(groupRef);

    await batch.commit();
  }

  Future<List<GroupMemberModel>> getGroupMembers(GroupModel group) async {
    if (group.members.isEmpty) {
      return [];
    }

    final userDocuments = await Future.wait(
      group.members.map((uid) => _firestore.collection('users').doc(uid).get()),
    );

    final members = userDocuments.map((doc) {
      final data = doc.data();

      String fullName = data?['fullName']?.toString().trim() ?? '';

      final email = data?['email']?.toString().trim() ?? '';

      if (fullName.isEmpty) {
        if (email.isNotEmpty) {
          fullName = email.split('@').first;
        } else {
          fullName = 'Unknown User';
        }
      }

      return GroupMemberModel(
        uid: doc.id,
        fullName: fullName,
        email: email,
        isAdmin: group.admins.contains(doc.id),
      );
    }).toList();

    // Admins first, then alphabetical
    members.sort((a, b) {
      if (a.isAdmin && !b.isAdmin) {
        return -1;
      }

      if (!a.isAdmin && b.isAdmin) {
        return 1;
      }

      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });

    return members;
  }

  // ============================================================
  // MAKE MEMBER ADMIN
  // ============================================================

  Future<void> makeMemberAdmin({
    required String groupId,
    required String memberId,
  }) async {
    final currentUid = currentUserId;

    if (currentUid == null) {
      throw Exception('User not logged in');
    }

    final groupRef = _firestore.collection('groups').doc(groupId);

    String? notificationGroupName;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(groupRef);

      if (!snapshot.exists) {
        throw Exception('Group not found');
      }

      final data = snapshot.data();

      if (data == null) {
        throw Exception('Group data not found');
      }

      final createdBy = data['createdBy']?.toString() ?? '';

      final admins = data['admins'] != null
          ? List<String>.from(data['admins'])
          : createdBy.isNotEmpty
          ? [createdBy]
          : <String>[];

      final members = List<String>.from(data['members'] ?? []);

      if (!admins.contains(currentUid)) {
        throw Exception('Only an admin can make another member an admin.');
      }

      if (!members.contains(memberId)) {
        throw Exception('This user is not a member of the group.');
      }

      // Already admin
      if (admins.contains(memberId)) {
        return;
      }

      admins.add(memberId);

      transaction.update(groupRef, {'admins': admins});

      notificationGroupName = data['groupName']?.toString() ?? 'Group';
    });

    // Notify new admin
    if (notificationGroupName != null) {
      await _notificationService.createNotification(
        userId: memberId,
        type: 'admin_changed',
        title: 'You Are Now an Admin',
        message: 'You are now an admin of $notificationGroupName.',
        groupId: groupId,
        groupName: notificationGroupName!,
      );
    }
  }
}
