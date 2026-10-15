import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/login_screen.dart';

/// Requires a live session before building shared-link content.
class SharedLinkAuthGate extends StatefulWidget {
  const SharedLinkAuthGate({
    super.key,
    required this.title,
    required this.signInPrompt,
    required this.contentKey,
    required this.contentBuilder,
    required this.destinationBuilder,
    this.firebaseAuth,
  });

  final String title;
  final String signInPrompt;
  final String contentKey;
  final WidgetBuilder contentBuilder;
  final WidgetBuilder destinationBuilder;
  final FirebaseAuth? firebaseAuth;

  @override
  State<SharedLinkAuthGate> createState() => _SharedLinkAuthGateState();
}

class _SharedLinkAuthGateState extends State<SharedLinkAuthGate> {
  late final _auth = widget.firebaseAuth ?? FirebaseAuth.instance;
  late Stream<User?> _authChanges = _auth.authStateChanges();

  void _signIn() {
    // Capture this destination before replacing the route with authentication.
    final destinationBuilder = widget.destinationBuilder;
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(destinationBuilder: destinationBuilder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: _authChanges,
    initialData: _auth.currentUser,
    builder: (context, snapshot) {
      if (!snapshot.hasError && snapshot.data != null) {
        return KeyedSubtree(
          key: ValueKey('${widget.contentKey}:${snapshot.data!.uid}'),
          child: widget.contentBuilder(context),
        );
      }
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  snapshot.hasError
                      ? 'Unable to check your sign-in status.'
                      : widget.signInPrompt,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (snapshot.hasError)
                  TextButton(
                    onPressed: () =>
                        setState(() => _authChanges = _auth.authStateChanges()),
                    child: const Text('Try again'),
                  )
                else
                  FilledButton(
                    onPressed: _signIn,
                    child: const Text('Sign in'),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
