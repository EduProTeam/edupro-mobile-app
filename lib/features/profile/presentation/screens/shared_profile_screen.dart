import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../auth/presentation/widgets/shared_link_auth_gate.dart';
import 'user_profile_screen.dart';

/// Keeps the shared author's identity through authentication.
class SharedProfileScreen extends StatelessWidget {
  const SharedProfileScreen({
    super.key,
    required this.userId,
    this.firebaseAuth,
    this.profileBuilder,
  });

  final String userId;
  final FirebaseAuth? firebaseAuth;
  final WidgetBuilder? profileBuilder;

  @override
  Widget build(BuildContext context) => SharedLinkAuthGate(
    title: 'Profile',
    signInPrompt: 'Sign in to view this profile.',
    contentKey: 'shared-profile:$userId',
    firebaseAuth: firebaseAuth,
    contentBuilder: profileBuilder ?? (_) => UserProfileScreen(userId: userId),
    destinationBuilder: (_) => SharedProfileScreen(
      userId: userId,
      firebaseAuth: firebaseAuth,
      profileBuilder: profileBuilder,
    ),
  );
}
