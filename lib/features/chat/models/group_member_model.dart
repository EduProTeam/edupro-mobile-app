class GroupMemberModel {
  final String uid;
  final String fullName;
  final String email;
  final bool isAdmin;

  const GroupMemberModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.isAdmin,
  });
}
