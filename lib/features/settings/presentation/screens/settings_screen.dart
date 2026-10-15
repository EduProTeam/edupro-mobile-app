import 'package:edupro_mobile_app/core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../shared/branding/edupro_brand.dart';

import '../../../auth/services/auth_service.dart';
import '../../../profile/presentation/screens/edit_profile_screen.dart';
import '../../../onboarding/presentation/screens/onboarding_screen_1.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.user});

  static const _primaryBlue = Color(0xFF3D8FEF);
  static const _danger = Color(0xFFEF4444);

  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        surfaceTintColor: context.appColors.surface,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data?.data();
          final name =
              _firstNonEmpty([
                profile?['fullName'],
                user.displayName,
                user.email?.split('@').first,
              ]) ??
              'User';
          final email =
              _firstNonEmpty([profile?['email'], user.email]) ??
              'No email available';
          final imageUrl = _firstNonEmpty([
            profile?['profileImageUrl'],
            user.photoURL,
          ]);

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileCard(
                    name: name,
                    email: email,
                    imageUrl: imageUrl,
                    onTap: () => _openEditProfile(context),
                  ),
                  const SizedBox(height: 26),
                  _SettingsSection(
                    title: 'Account',
                    children: [
                      _SettingsTile(
                        icon: Icons.person_outline,
                        title: 'Personal Information',
                        subtitle: 'Manage your profile information',
                        onTap: () => _openEditProfile(context),
                      ),
                      _SettingsTile(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        subtitle: 'Update your account password',
                        onTap: () => _showSnackBar(
                          context,
                          'Change Password will be implemented next.',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.mail_outline,
                        title: 'Email & Phone',
                        subtitle: 'Manage contact information',
                        onTap: () => _openEditProfile(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: 'Preferences',
                    children: [
                      _SettingsTile(
                        icon: Icons.notifications_none,
                        title: 'Notifications',
                        subtitle: 'Manage notification preferences',
                        onTap: () => _showSnackBar(
                          context,
                          'Notification settings coming soon.',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.language,
                        title: 'Language',
                        trailingText: 'English',
                        onTap: () => _showLanguageDialog(context),
                      ),
                      _SettingsTile(
                        icon: Icons.school_outlined,
                        title: 'Learning Preferences',
                        subtitle: 'Manage your interests',
                        onTap: () => _openEditProfile(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: 'Privacy & Security',
                    children: [
                      _SettingsTile(
                        icon: Icons.shield_outlined,
                        title: 'Privacy Settings',
                        onTap: () => _showSnackBar(
                          context,
                          'Privacy settings coming soon.',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.person_off_outlined,
                        title: 'Blocked Users',
                        onTap: () => _showSnackBar(
                          context,
                          'Blocked users management coming soon.',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Login & Security',
                        onTap: () => _showSnackBar(
                          context,
                          'Login & Security settings coming soon.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: 'Support',
                    children: [
                      _SettingsTile(
                        icon: Icons.help_outline,
                        title: 'Help Center',
                        onTap: () =>
                            _showSnackBar(context, 'Help Center coming soon.'),
                      ),
                      _SettingsTile(
                        icon: Icons.warning_amber_outlined,
                        title: 'Report a Problem',
                        onTap: () => _showSnackBar(
                          context,
                          'Report a Problem coming soon.',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.info_outline,
                        title: 'About EduPro',
                        onTap: () => _showAboutDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _SettingsTile(
                    icon: Icons.logout,
                    title: 'Log Out',
                    isDanger: true,
                    onTap: () => _confirmLogout(context),
                    standalone: true,
                  ),
                  TextButton(
                    onPressed: () => _confirmDeleteAccount(context),
                    child: const Text(
                      'Delete Account',
                      style: TextStyle(color: _danger, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'EduPro Version 1.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditProfile(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => EditProfileScreen(user: user)),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text(
          'Are you sure you want to log out of your EduPro account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: _danger),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await AuthService().signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const OnboardingScreen1()),
        (route) => false,
      );
    } catch (_) {
      _showSnackBar(context, 'Unable to log out. Please try again.');
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'Deleting your account will permanently remove your EduPro account and associated data.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: _danger),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      _showSnackBar(
        context,
        'Account deletion will be implemented separately.',
      );
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.check, color: context.appColors.primary),
              title: Text('English'),
            ),
            Text(
              'More languages will be added later.',
              style: TextStyle(color: context.appColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'EduPro',
        applicationVersion: '1.0.0',
        applicationIcon: const EduProMark(size: 36),
        children: [
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Community Skill Exchange & Micro-Learning Platform'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.onTap,
  });
  final String name;
  final String email;
  final String? imageUrl;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: context.appColors.surface,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: context.appColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.appColors.primarySoft,
                border: Border.all(color: context.appColors.surface, width: 3),
                image: imageUrl == null
                    ? null
                    : DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      ),
              ),
              child: imageUrl == null
                  ? Icon(
                      Icons.person,
                      size: 44,
                      color: context.appColors.primary,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: context.appColors.primary,
              size: 30,
            ),
          ],
        ),
      ),
    ),
  );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: context.appColors.textPrimary,
        ),
      ),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: context.appColors.surface,
          border: Border.all(color: context.appColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0)
                Divider(
                  height: 1,
                  indent: 72,
                  endIndent: 16,
                  color: context.appColors.border,
                ),
              children[index],
            ],
          ],
        ),
      ),
    ],
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailingText,
    this.isDanger = false,
    this.standalone = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback onTap;
  final bool isDanger;
  final bool standalone;
  @override
  Widget build(BuildContext context) {
    final color = isDanger
        ? SettingsScreen._danger
        : SettingsScreen._primaryBlue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(standalone ? 16 : 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(standalone ? 16 : 0),
            border: standalone
                ? Border.all(color: context.appColors.border)
                : null,
            boxShadow: standalone
                ? const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDanger
                      ? (context.appColors.isDark
                            ? Colors.red.withValues(alpha: 0.14)
                            : const Color(0xFFFFF1F2))
                      : context.appColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDanger
                            ? SettingsScreen._danger
                            : context.appColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 15,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: TextStyle(
                    fontSize: 16,
                    color: context.appColors.primary,
                  ),
                ),
              Icon(Icons.chevron_right, color: color, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
