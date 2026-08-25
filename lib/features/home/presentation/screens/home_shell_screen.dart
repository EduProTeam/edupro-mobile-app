import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../auth/services/auth_service.dart';
import '../../../posts/presentation/widgets/post_card.dart';
import '../../../posts/presentation/screens/new_post_screen.dart';
import '../../../posts/services/post_service.dart';
import '../../../profile/presentation/screens/edit_profile_screen.dart';
import '../../../profile/presentation/screens/profile_photo_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../splash/presentation/screens/splash_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  final _authService = AuthService();

  static const _createPostPurple = Color(0xFF5B2CCF);

  int _currentIndex = 0;

  Future<void> _logout() async {
    await _authService.signOut();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  void _openNewPost() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const NewPostScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final screens = [
      _SimpleHomeScreen(onLogout: _logout),
      _SimpleProfileScreen(user: user),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _openNewPost,
              backgroundColor: _createPostPurple,
              foregroundColor: Colors.white,
              elevation: 6,
              tooltip: 'New Post',
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
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
  const _SimpleHomeScreen({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  State<_SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends State<_SimpleHomeScreen> {
  final _postService = PostService();
  late Stream<List<PublishedPost>> _postsStream;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          TextButton(
            onPressed: () => widget.onLogout(),
            child: const Text('Logout'),
          ),
        ],
      ),
      body: StreamBuilder<List<PublishedPost>>(
        stream: _postsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Published posts feed error: ${snapshot.error}');
            return _FeedMessage(
              message: 'Unable to load posts.',
              actionLabel: 'Try again',
              onAction: _retryPosts,
              onRefresh: _refreshPosts,
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _FeedLoading();
          }

          final posts = snapshot.data ?? const <PublishedPost>[];
          if (posts.isEmpty) {
            return _FeedMessage(
              message: 'No posts yet',
              detail:
                  'Be the first to share something with the EduPro community.',
              onRefresh: _refreshPosts,
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshPosts,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 104),
              itemCount: posts.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Educational Posts',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PostCard(post: posts[index - 1]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 104),
      children: const [
        Text(
          'Educational Posts',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 96),
        Center(child: CircularProgressIndicator()),
        SizedBox(height: 14),
        Center(child: Text('Loading posts...')),
      ],
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.message,
    required this.onRefresh,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 104),
        children: [
          const Text(
            'Educational Posts',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 96),
          Center(
            child: Column(
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    detail!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
                if (actionLabel != null) ...[
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleProfileScreen extends StatelessWidget {
  const _SimpleProfileScreen({required this.user});

  static const _primaryBlue = Color(0xFF3D8FEF);
  static const _lightBlue = Color(0xFFEFF6FF);
  static const _textPrimary = Color(0xFF1E1E1E);
  static const _textSecondary = Color(0xFF6B7280);
  static const _borderColor = Color(0xFFE5E7EB);

  final User? user;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const SafeArea(
        child: Center(child: Text('No signed-in user available.')),
      );
    }

    final userDocument = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDocument.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = snapshot.data?.data();
        final name =
            _firstNonEmpty([
              profile?['fullName'],
              user!.displayName,
              user!.email?.split('@').first,
            ]) ??
            'User';
        final email = _firstNonEmpty([profile?['email'], user!.email]);
        final profileImageUrl = _firstNonEmpty([profile?['profileImageUrl']]);
        final professionalTitle =
            _firstNonEmpty([profile?['professionalTitle']]) ?? 'EduPro Learner';
        final organization = _firstNonEmpty([profile?['organization']]);
        final bio = _firstNonEmpty([profile?['bio']]);
        final skills = _stringList(profile?['skills']);
        final interests = _stringList(profile?['learningInterests']);

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  onSettingsTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => SettingsScreen(user: user!),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _ProfileAvatar(
                  imageUrl: profileImageUrl,
                  onCameraTap: () async {
                    final result = await Navigator.of(context)
                        .push<ProfilePhotoResult>(
                          MaterialPageRoute<ProfilePhotoResult>(
                            builder: (_) => ProfilePhotoScreen(
                              user: user!,
                              imageUrl: profileImageUrl,
                            ),
                          ),
                        );
                    if (result != null && context.mounted) {
                      _showSnackBar(
                        context,
                        result.imageUrl == null
                            ? 'Profile photo removed successfully.'
                            : 'Profile photo updated successfully.',
                      );
                    }
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  professionalTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17, color: _textSecondary),
                ),
                if (organization != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    organization,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: _textSecondary),
                  ),
                ],
                if (email != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: _textSecondary),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  bio ?? 'Add a bio to tell the community about yourself.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                const _StatsCard(),
                const SizedBox(height: 20),
                _ProfileActions(
                  onEdit: () async {
                    final wasSaved = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => EditProfileScreen(user: user!),
                      ),
                    );
                    if (wasSaved == true && context.mounted) {
                      _showSnackBar(context, 'Profile updated successfully');
                    }
                  },
                  onShare: () =>
                      _showSnackBar(context, 'Profile sharing coming soon'),
                ),
                const SizedBox(height: 28),
                _SectionHeading(
                  title: 'My Skills',
                  actionLabel: '+ Add Skill',
                  onAction: () =>
                      _showSnackBar(context, 'Add Skill coming soon'),
                ),
                const SizedBox(height: 14),
                if (skills.isEmpty)
                  const Text(
                    'No skills added yet',
                    style: TextStyle(fontSize: 16, color: _textSecondary),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: skills
                        .map((skill) => _SkillChip(label: skill))
                        .toList(),
                  ),
                const SizedBox(height: 28),
                const _SectionHeading(title: 'Learning Interests'),
                const SizedBox(height: 14),
                if (interests.isEmpty)
                  const Text(
                    'No learning interests selected yet',
                    style: TextStyle(fontSize: 16, color: _textSecondary),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: interests
                        .map((interest) => _InterestChip(label: interest))
                        .toList(),
                  ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  List<String> _stringList(dynamic value) {
    if (value is! Iterable) {
      return [];
    }
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSettingsTap});

  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'My Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onSettingsTap,
              icon: const Icon(Icons.settings_outlined, size: 28),
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imageUrl, required this.onCameraTap});

  final String? imageUrl;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 116,
        height: 116,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                color: const Color(0xFFEFF6FF),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? const Icon(
                      Icons.person,
                      size: 54,
                      color: _SimpleProfileScreen._primaryBlue,
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 5,
              child: Material(
                color: _SimpleProfileScreen._primaryBlue,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onCameraTap,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _SimpleProfileScreen._borderColor),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _StatItem(value: '0', label: 'Courses'),
          ),
          _StatDivider(),
          Expanded(
            child: _StatItem(value: '0', label: 'Skills'),
          ),
          _StatDivider(),
          Expanded(
            child: _StatItem(value: '0', label: 'Sessions'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w800,
          color: _SimpleProfileScreen._primaryBlue,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          color: _SimpleProfileScreen._textSecondary,
        ),
      ),
    ],
  );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 48,
    child: VerticalDivider(width: 1, color: _SimpleProfileScreen._borderColor),
  );
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({required this.onEdit, required this.onShare});
  final VoidCallback onEdit;
  final VoidCallback onShare;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: FilledButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Profile'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: _SimpleProfileScreen._primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.share_outlined),
          label: const Text('Share Profile'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: _SimpleProfileScreen._primaryBlue,
            side: const BorderSide(color: _SimpleProfileScreen._primaryBlue),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: _SimpleProfileScreen._textPrimary,
        ),
      ),
      const Spacer(),
      if (actionLabel != null)
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: _SimpleProfileScreen._primaryBlue,
          ),
          child: Text(
            actionLabel!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
    ],
  );
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _SimpleProfileScreen._primaryBlue),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _SimpleProfileScreen._primaryBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _SimpleProfileScreen._lightBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _SimpleProfileScreen._primaryBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
