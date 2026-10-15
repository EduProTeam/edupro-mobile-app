import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../posts/services/post_service.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../widgets/profile_dashboard.dart';
import '../widgets/profile_post_library.dart';
import '../widgets/profile_share_sheet.dart';
import 'edit_profile_screen.dart';
import 'profile_photo_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final User? user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _postService = PostService();
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _profile;
  Stream<int>? _postCount;

  @override
  void initState() {
    super.initState();
    _watchProfile();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user?.uid != widget.user?.uid) _watchProfile();
  }

  void _watchProfile() {
    final user = widget.user;
    _profile = user == null
        ? null
        : FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots();
    _watchPostCount();
  }

  void _watchPostCount() {
    _postCount = widget.user == null
        ? null
        : _postService.watchMyPosts().map((posts) => posts.length);
  }

  Future<void> _editProfile() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: widget.user!)),
    );
    if (saved == true && mounted) _showMessage('Profile updated successfully');
  }

  Future<void> _editPhoto(String? imageUrl) async {
    final result = await Navigator.of(context).push<ProfilePhotoResult>(
      MaterialPageRoute(
        builder: (_) =>
            ProfilePhotoScreen(user: widget.user!, imageUrl: imageUrl),
      ),
    );
    if (result != null && mounted) {
      _showMessage(
        result.imageUrl == null
            ? 'Profile photo removed successfully.'
            : 'Profile photo updated successfully.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    if (user == null) {
      return const SafeArea(
        child: Center(child: Text('No signed-in user available.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      key: ValueKey(user.uid),
      stream: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError && !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Unable to load your profile.'),
                TextButton(
                  onPressed: () => setState(_watchProfile),
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data?.data();
        final photo = _text(data?['profileImageUrl']);
        return StreamBuilder<int>(
          key: ValueKey('post-count:${user.uid}'),
          stream: _postCount,
          builder: (context, countSnapshot) => ProfileDashboard(
            name:
                _text(data?['fullName']) ??
                _text(user.displayName) ??
                user.email?.split('@').first ??
                'User',
            title: _text(data?['professionalTitle']) ?? 'EduPro Learner',
            organization: _text(data?['organization']),
            email: _text(data?['email']) ?? user.email,
            bio: _text(data?['bio']),
            imageUrl: photo,
            skills: _strings(data?['skills']),
            interests: _strings(data?['learningInterests']),
            postCount: countSnapshot.hasError ? null : countSnapshot.data,
            onRetryPostCount: countSnapshot.hasError
                ? () => setState(_watchPostCount)
                : null,
            postLibrary: ProfilePostLibrary(key: ValueKey(user.uid)),
            onSettings: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => SettingsScreen(user: user)),
            ),
            onPhoto: () => _editPhoto(photo),
            onEdit: _editProfile,
            onShare: () => showProfileShareSheet(
              context,
              userId: user.uid,
              profileName:
                  _text(data?['fullName']) ??
                  _text(user.displayName) ??
                  'EduPro user',
            ),
            onAddSkill: _editProfile,
            onAddInterest: _editProfile,
          ),
        );
      },
    );
  }

  String? _text(dynamic value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  List<String> _strings(dynamic value) => value is Iterable
      ? value
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList()
      : [];
}
