import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../onboarding/presentation/widgets/onboarding_screen_layout.dart';
import '../widgets/auth_form_components.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _hasSubmitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() {
      _hasSubmitted = true;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    _showInfoMessage('TODO: Connect password reset logic later.');
  }

  String? _validateEmail(String? value) {
    if (!_hasSubmitted) {
      return null;
    }

    final trimmed = value?.trim() ?? '';
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (trimmed.isEmpty) {
      return 'Enter your email address.';
    }

    if (!emailPattern.hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  void _goBackToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AuthUi.backgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final horizontalPadding =
                  (screenWidth * 0.075).clamp(24.0, 32.0).toDouble();
              final contentWidth =
                  (screenWidth - (horizontalPadding * 2))
                      .clamp(280.0, 380.0)
                      .toDouble();
              final illustrationWidth =
                  (screenWidth * 0.56).clamp(190.0, 230.0).toDouble();

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  28,
                  horizontalPadding,
                  28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _hasSubmitted
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Material(
                              color: Colors.white,
                              elevation: 3,
                              shadowColor: Colors.black.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: _goBackToLogin,
                                borderRadius: BorderRadius.circular(14),
                                child: const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: Color(0xFF5D5D5D),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 44),
                          Center(
                            child: SizedBox(
                              width: illustrationWidth,
                              child: Image.asset(
                                'assets/images/auth/forgot_password.jpg',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          Text(
                            'Forgot Password?',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              color: Colors.black,
                              fontSize: screenWidth < 360 ? 30 : 33,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'Enter your registered email address and we’ll send you a link to reset your password',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyLarge?.copyWith(
                                color: AuthUi.subtitleColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          AuthTextField(
                            controller: _emailController,
                            hintText: 'Email Address',
                            prefixIcon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 58),
                          PrimaryAuthButton(
                            label: 'Send Reset Link',
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AuthUi.inputTextColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  const TextSpan(text: 'Back to  '),
                                  TextSpan(
                                    text: 'Login',
                                    style: const TextStyle(
                                      color: OnboardingScreenLayout.primaryBlue,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = _goBackToLogin,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
