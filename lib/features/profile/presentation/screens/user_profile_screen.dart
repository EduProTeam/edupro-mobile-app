import 'package:edupro_mobile_app/core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../posts/services/post_service.dart';
import '../widgets/profile_dashboard.dart';
import '../widgets/profile_post_library.dart';

/// A visitor can view an author's public profile without owner controls.
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.userId,
    this.fallbackName,
    this.fallbackImageUrl,
    this.firestore,
    this.postService,
  });

  final String userId;
  final String? fallbackName;
  final String? fallbackImageUrl;
  final FirebaseFirestore? firestore;
  final PostService? postService;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final _firestore = widget.firestore ?? FirebaseFirestore.instance;
  late final _postService =
      widget.postService ?? PostService(firestore: _firestore);
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _profile;
  Stream<int>? _postCount;

  @override
  void initState() {
    super.initState();
    _watchProfile();
    _watchPostCount();
  }

  @override
  void didUpdateWidget(covariant UserProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _watchProfile();
      _watchPostCount();
    }
  }

  void _watchProfile() {
    _profile = widget.userId.trim().isEmpty
        ? null
        : _firestore.collection('users').doc(widget.userId).snapshots();
  }

  void _watchPostCount() {
    _postCount = _postService
        .watchPostsByUser(widget.userId, publicOnly: true)
        .map((posts) => posts.length);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColors.surface,
    appBar: AppBar(
      title: const Text('Profile'),
      backgroundColor: context.appColors.surface,
      surfaceTintColor: context.appColors.surface,
    ),
    body: widget.userId.trim().isEmpty
        ? const Center(child: Text('This profile is no longer available.'))
        : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            key: ValueKey(widget.userId),
            stream: _profile,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Unable to load this profile.'),
                      TextButton(
                        onPressed: () => setState(_watchProfile),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.data!.exists) {
                return const Center(
                  child: Text('This profile is no longer available.'),
                );
              }
              final data = snapshot.data!.data() ?? {};
              return StreamBuilder<int>(
                key: ValueKey('public-post-count:${widget.userId}'),
                stream: _postCount,
                builder: (context, countSnapshot) => ProfileDashboard(
                  readOnly: true,
                  name:
                      _text(data['fullName']) ??
                      _text(widget.fallbackName) ??
                      'EduPro user',
                  title: _text(data['professionalTitle']) ?? 'EduPro Learner',
                  organization: _text(data['organization']),
                  bio: _text(data['bio']),
                  imageUrl: data.containsKey('profileImageUrl')
                      ? _text(data['profileImageUrl'])
                      : _text(widget.fallbackImageUrl),
                  skills: _strings(data['skills']),
                  interests: _strings(data['learningInterests']),
                  postCount: countSnapshot.hasError ? null : countSnapshot.data,
                  onRetryPostCount: countSnapshot.hasError
                      ? () => setState(_watchPostCount)
                      : null,
                  postLibrary: ProfilePostLibrary(
                    key: ValueKey('public-posts:${widget.userId}'),
                    publicUserId: widget.userId,
                    postService: _postService,
                  ),
                ),
              );
            },
          ),
  );

  String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  List<String> _strings(Object? value) => value is Iterable
      ? value
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList()
      : [];
}
