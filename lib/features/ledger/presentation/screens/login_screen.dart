import 'package:flutter/material.dart';

import '../../../../core/auth/auth_validators.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/app_route.dart';
import '../controllers/ledger_controller.dart';
import '../widgets/service_icon.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.controller, super.key});

  final LedgerController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Welcome Back!',
      subtitle: 'Login to your account',
      errorMessage: widget.controller.errorMessage,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              _LabeledField(
                label: 'Email or Phone',
                controller: _identifierController,
                hintText: 'Email or phone number',
                validator: AuthValidators.emailOrPhone,
              ),
              const SizedBox(height: AppSpacing.md),
              _LabeledField(
                label: 'Password',
                controller: _passwordController,
                hintText: 'Password',
                obscureText: true,
                validator: AuthValidators.password,
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => widget.controller.goTo(LedgerRoute.forgotPassword),
            child: const Text('Forgot Password?'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: widget.controller.isLoading
              ? null
              : () {
                  if (_formKey.currentState?.validate() != true) {
                    return;
                  }
                  widget.controller.signIn(
                    identifier: _identifierController.text,
                    password: _passwordController.text,
                  );
                },
          child: const Text('Login'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: widget.controller.bypassLoginForDevelopment,
          icon: const Icon(Icons.lock_open_outlined),
          label: const Text('Dev Bypass Login'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('New here?', style: Theme.of(context).textTheme.bodyMedium),
            TextButton(
              onPressed: () => widget.controller.goTo(LedgerRoute.register),
              child: const Text('Create Account'),
            ),
          ],
        ),
      ],
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({required this.controller, super.key});

  final LedgerController controller;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Create Account',
      subtitle: 'Use email and phone for secure access',
      errorMessage: widget.controller.errorMessage,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              _LabeledField(
                label: 'Name',
                controller: _nameController,
                validator: (value) =>
                    AuthValidators.requiredText(value, 'Name'),
              ),
              const SizedBox(height: AppSpacing.md),
              _LabeledField(
                label: 'Email',
                controller: _emailController,
                validator: AuthValidators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              _LabeledField(
                label: 'Phone',
                controller: _phoneController,
                validator: AuthValidators.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              _LabeledField(
                label: 'Password',
                controller: _passwordController,
                obscureText: true,
                validator: AuthValidators.password,
              ),
              const SizedBox(height: AppSpacing.md),
              _LabeledField(
                label: 'Confirm Password',
                controller: _confirmPasswordController,
                obscureText: true,
                validator: (value) => value == _passwordController.text
                    ? null
                    : 'Passwords must match',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: widget.controller.isLoading
              ? null
              : () {
                  if (_formKey.currentState?.validate() != true) {
                    return;
                  }
                  widget.controller.register(
                    name: _nameController.text,
                    email: _emailController.text,
                    phone: _phoneController.text,
                    password: _passwordController.text,
                  );
                },
          child: const Text('Register'),
        ),
        TextButton(
          onPressed: () => widget.controller.goTo(LedgerRoute.login),
          child: const Text('Back to Login'),
        ),
      ],
    );
  }
}

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({required this.controller, super.key});

  final LedgerController controller;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.controller.pendingVerificationEmail.isNotEmpty
          ? widget.controller.pendingVerificationEmail
          : widget.controller.profile?.email ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Verify your email',
      subtitle: 'Enter the OTP sent to your email',
      errorMessage: widget.controller.errorMessage,
      statusMessage: widget.controller.successMessage,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              _LabeledField(
                label: 'Email',
                controller: _emailController,
                validator: AuthValidators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              _LabeledField(
                label: 'OTP',
                controller: _otpController,
                validator: AuthValidators.otp,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: widget.controller.isLoading
              ? null
              : () {
                  if (_formKey.currentState?.validate() != true) {
                    return;
                  }
                  widget.controller.verifyEmailOtp(
                    email: _emailController.text,
                    token: _otpController.text,
                  );
                },
          child: const Text('Verify Email'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: widget.controller.resendEmailVerification,
          child: const Text('Resend OTP'),
        ),
        TextButton(
          onPressed: () => widget.controller.goTo(LedgerRoute.login),
          child: const Text('Back to Login'),
        ),
      ],
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({required this.controller, super.key});

  final LedgerController controller;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Reset Password',
      subtitle: 'We will send a recovery OTP to your email',
      errorMessage: widget.controller.errorMessage,
      children: [
        Form(
          key: _formKey,
          child: _LabeledField(
            label: 'Email',
            controller: _emailController,
            validator: AuthValidators.email,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: widget.controller.isLoading
              ? null
              : () {
                  if (_formKey.currentState?.validate() != true) {
                    return;
                  }
                  widget.controller.requestPasswordReset(_emailController.text);
                },
          child: const Text('Send OTP'),
        ),
      ],
    );
  }
}

class ResetPasswordOtpScreen extends StatefulWidget {
  const ResetPasswordOtpScreen({required this.controller, super.key});

  final LedgerController controller;

  @override
  State<ResetPasswordOtpScreen> createState() => _ResetPasswordOtpScreenState();
}

class _ResetPasswordOtpScreenState extends State<ResetPasswordOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.controller.pendingPasswordResetEmail,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Enter Recovery OTP',
      subtitle: 'Set your new password after OTP verification',
      errorMessage: widget.controller.errorMessage,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              _LabeledField(
                label: 'Email',
                controller: _emailController,
                validator: AuthValidators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              _LabeledField(
                label: 'OTP',
                controller: _otpController,
                validator: AuthValidators.otp,
              ),
              const SizedBox(height: AppSpacing.md),
              _LabeledField(
                label: 'New Password',
                controller: _passwordController,
                obscureText: true,
                validator: AuthValidators.password,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: widget.controller.isLoading
              ? null
              : () {
                  if (_formKey.currentState?.validate() != true) {
                    return;
                  }
                  widget.controller.resetPassword(
                    email: _emailController.text,
                    token: _otpController.text,
                    newPassword: _passwordController.text,
                  );
                },
          child: const Text('Update Password'),
        ),
      ],
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    this.errorMessage,
    this.statusMessage,
  });

  final String title;
  final String subtitle;
  final String? errorMessage;
  final String? statusMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const SizedBox(height: 24),
          const Center(child: AppLogoMark(size: 82)),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              errorMessage!,
              style: const TextStyle(color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
          ],
          if (statusMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              statusMessage!,
              style: const TextStyle(color: AppColors.success),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          ...children,
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(hintText: hintText ?? label),
        ),
      ],
    );
  }
}
