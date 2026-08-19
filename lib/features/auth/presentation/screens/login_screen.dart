import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../../home/presentation/screens/home_shell_screen.dart';
import '../../../onboarding/presentation/widgets/onboarding_screen_layout.dart';
import '../widgets/auth_form_components.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _hasSubmitted = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _hasSubmitted = true;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Login successful.'),
            behavior: SnackBarBehavior.floating,
          ),
        );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const HomeShellScreen(),
        ),
      );
    } on AuthFailure catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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

  String? _validatePassword(String? value) {
    if (!_hasSubmitted) {
      return null;
    }

    if ((value ?? '').isEmpty) {
      return 'Enter your password.';
    }

    return null;
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

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  22,
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
                          const SizedBox(height: 28),
                          const EduProAuthBranding(),
                          const SizedBox(height: 54),
                          Text(
                            'Welcome Back',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              color: Colors.black,
                              fontSize: screenWidth < 360 ? 31 : 35,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Continue learning, sharing, and growing with EduPro.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: AuthUi.subtitleColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 42),
                          AuthTextField(
                            controller: _emailController,
                            hintText: 'Email Address',
                            prefixIcon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _passwordController,
                            hintText: 'Password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: _validatePassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    OnboardingScreenLayout.primaryBlue,
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 54),
                          PrimaryAuthButton(
                            label: 'Login',
                            onPressed: _submit,
                            isLoading: _isSubmitting,
                          ),
                          const SizedBox(height: 22),
                          const AuthDivider(label: 'or continue with'),
                          const SizedBox(height: 20),
                          GoogleAuthButton(
                            label: 'Continue with Google',
                            onPressed: () {
                              _showInfoMessage(
                                'TODO: Connect Google sign-in next.',
                              );
                            },
                          ),
                          const SizedBox(height: 22),
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
                                  const TextSpan(
                                    text: 'Don’t have an account? ',
                                  ),
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: const TextStyle(
                                      color: Color(0xFF3D8FEF),
                                      fontWeight: FontWeight.w800,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const RegisterScreen(),
                                          ),
                                        );
                                      },
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
