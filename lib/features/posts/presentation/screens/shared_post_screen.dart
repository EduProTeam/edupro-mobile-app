import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../auth/presentation/widgets/shared_link_auth_gate.dart';
import 'post_detail_screen.dart';

/// Retains a shared post through authentication before loading its content.
class SharedPostScreen extends StatelessWidget {
  const SharedPostScreen({
    super.key,
    required this.postId,
    this.firebaseAuth,
    this.postBuilder,
  });

  final String postId;
  final FirebaseAuth? firebaseAuth;
  final WidgetBuilder? postBuilder;

  @override
  Widget build(BuildContext context) => SharedLinkAuthGate(
    title: 'Educational Post',
    signInPrompt: 'Sign in to view this post.',
    contentKey: 'shared-post:$postId',
    firebaseAuth: firebaseAuth,
    contentBuilder:
        postBuilder ??
        (_) => PostDetailScreen.fromId(postId: postId, publicOnly: true),
    destinationBuilder: (_) => SharedPostScreen(
      postId: postId,
      firebaseAuth: firebaseAuth,
      postBuilder: postBuilder,
    ),
  );
}
