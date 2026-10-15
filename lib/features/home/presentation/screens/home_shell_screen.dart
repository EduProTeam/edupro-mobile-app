import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edupro_mobile_app/core/theme/app_colors.dart';

import '../../../chat/screens/group_list_screen.dart';
import '../../../courses/models/course_draft.dart';
import '../../../courses/presentation/screens/create_course_screen.dart';
import '../../../courses/presentation/screens/recorded_courses_screen.dart';
import '../../../posts/presentation/screens/new_post_screen.dart';
import '../../../posts/presentation/screens/post_detail_screen.dart';
import '../../../posts/services/post_service.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../profile/presentation/widgets/profile_post_library.dart';
import '../../../skill_sharing/presentation/screens/skill_requests_screen.dart';
import '../widgets/home_post_feed.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  static const _createPostBlue = Color(0xFF167BFF);

  int _currentIndex = 0;

  Future<void> _openCreateCourseScreen() async {
    final result = await Navigator.of(context).push<CourseDraft>(
      MaterialPageRoute<CourseDraft>(
        builder: (_) => const CreateCourseScreen(),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _currentIndex = 1;
    });
  }

  void _openNewPost([PostAttachmentType? attachment]) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NewPostScreen(initialAttachmentType: attachment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final screens = [
      _SimpleHomeScreen(
        onCreatePost: _openNewPost,
        onOpenProfile: () => setState(() => _currentIndex = 4),
      ),
      RecordedCoursesScreen(onCreateCoursePressed: _openCreateCourseScreen),
      const SkillRequestsScreen(),
      const GroupListScreen(),
      ProfileScreen(user: user),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _openNewPost,
              backgroundColor: _createPostBlue,
              foregroundColor: Colors.white,
              elevation: 6,
              tooltip: 'New Post',
              child: const Icon(Icons.edit_outlined),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: context.appColors.surface,
        selectedItemColor: const Color(0xFF167BFF),
        unselectedItemColor: context.appColors.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 26,
        elevation: 0,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library_outlined),
            activeIcon: Icon(Icons.video_library),
            label: 'Videos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Skills',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _SimpleHomeScreen extends StatefulWidget {
  const _SimpleHomeScreen({
    required this.onCreatePost,
    required this.onOpenProfile,
  });

  final ValueChanged<PostAttachmentType?> onCreatePost;
  final VoidCallback onOpenProfile;

  @override
  State<_SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends State<_SimpleHomeScreen> {
  final _postService = PostService();
  late Stream<List<PublishedPost>> _postsStream;
  late final _user = FirebaseAuth.instance.currentUser;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>? _profile =
      _user == null
      ? null
      : FirebaseFirestore.instance
            .collection('users')
            .doc(_user.uid)
            .snapshots();

  @override
  void initState() {
    super.initState();
    _postsStream = _postService.watchPublishedPosts();
  }

  Future<void> _refreshPosts() async {
    final refreshedStream = _postService.watchPublishedPosts();
    setState(() {
      _postsStream = refreshedStream;
    });

    try {
      await refreshedStream.first;
    } catch (_) {
      // The StreamBuilder below presents the error state and retry option.
    }
  }

  void _retryPosts() {
    setState(() {
      _postsStream = _postService.watchPublishedPosts();
    });
  }

  void _openSavedPosts() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: context.appColors.surface,
          appBar: AppBar(
            title: const Text('Saved posts'),
            backgroundColor: context.appColors.surface,
            surfaceTintColor: context.appColors.surface,
          ),
          body: const SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ProfilePostLibrary(initialTab: 1),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.appColors.background,
      child: SafeArea(
        bottom: false,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _profile,
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
            final name = data?['fullName'];
            final photo = data?['profileImageUrl'];
            return HomePostFeed(
              postsStream: _postsStream,
              onRefresh: _refreshPosts,
              onRetry: _retryPosts,
              userName: name is String && name.trim().isNotEmpty
                  ? name.trim()
                  : _user?.displayName ?? 'Learner',
              userImageUrl: photo is String && photo.trim().isNotEmpty
                  ? photo.trim()
                  : null,
              onCreatePost: widget.onCreatePost,
              onOpenProfile: widget.onOpenProfile,
              onOpenSaved: _openSavedPosts,
              onOpenPost: (post) => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
              ),
            );
          },
        ),
      ),
    );
  }
}
