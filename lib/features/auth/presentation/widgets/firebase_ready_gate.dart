import 'package:flutter/material.dart';

import '../../../../core/firebase/app_firebase.dart';

/// Initializes Firebase before building a selected app-link destination.
class FirebaseReadyGate extends StatefulWidget {
  const FirebaseReadyGate({super.key, required this.builder, this.initialize});

  final WidgetBuilder builder;
  final Future<void> Function()? initialize;

  @override
  State<FirebaseReadyGate> createState() => _FirebaseReadyGateState();
}

class _FirebaseReadyGateState extends State<FirebaseReadyGate> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<void> _initialize() =>
      Future<void>.sync(widget.initialize ?? AppFirebase.ensureInitialized);

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(semanticsLabel: 'Loading EduPro'),
          ),
        );
      }
      if (snapshot.hasError) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Unable to initialize EduPro. Please try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => setState(() {
                        _initialization = _initialize();
                      }),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      return widget.builder(context);
    },
  );
}
