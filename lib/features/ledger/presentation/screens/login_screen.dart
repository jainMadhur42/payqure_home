import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/widgets/app_logo_mark.dart';
import '../../../../common/widgets/app_snack_bar.dart';
import '../../../../core/auth/auth_validators.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../legal/domain/legal_content.dart';
import '../../../legal/presentation/legal_screens.dart';
import '../../domain/entities/app_route.dart';
import '../controllers/ledger_controller.dart';
import '../widgets/otp_resend_panel.dart';

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
                validator: (value) =>
                    AuthValidators.requiredText(value, 'Password'),
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
  bool _privacyPolicyAccepted = false;

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
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                key: const ValueKey('signup-privacy-checkbox'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _privacyPolicyAccepted,
                onChanged: (value) {
                  setState(() => _privacyPolicyAccepted = value ?? false);
                },
                title: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('I have read and agree to the '),
                    InkWell(
                      onTap: _openPrivacyPolicy,
                      child: Text(
                        'Privacy Policy.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          key: const ValueKey('register-submit'),
          onPressed: widget.controller.isLoading || !_privacyPolicyAccepted
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
                    privacyPolicyAccepted: _privacyPolicyAccepted,
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

  void _openPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Privacy Policy')),
          body: const PrivacyPolicyView(),
        ),
      ),
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
                readOnly: true,
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
        OtpResendPanel(
          buttonKey: const ValueKey('resend-verification-otp'),
          availableAt: widget.controller.emailVerificationResendAvailableAt,
          status: widget.controller.emailVerificationOtpStatus,
          isLoading: widget.controller.isLoading,
          onResend: widget.controller.resendEmailVerification,
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
      onBack: () => widget.controller.goTo(
        widget.controller.isAuthenticated
            ? LedgerRoute.profile
            : LedgerRoute.login,
      ),
      title: 'Reset Password',
      subtitle: 'We will send a recovery OTP to your registered email',
      errorMessage: widget.controller.errorMessage,
      children: [
        Form(
          key: _formKey,
          child: _LabeledField(
            label: 'Email or Phone',
            controller: _emailController,
            hintText: 'Email or phone number',
            validator: AuthValidators.emailOrPhone,
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
        const SizedBox(height: AppSpacing.sm),
        OtpResendPanel(
          availableAt: null,
          status: widget.controller.passwordResetOtpStatus,
          onResend: () async {},
          showResendButton: false,
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
      onBack: () => widget.controller.goTo(LedgerRoute.forgotPassword),
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
                readOnly: true,
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
        const SizedBox(height: AppSpacing.sm),
        OtpResendPanel(
          buttonKey: const ValueKey('resend-password-reset-otp'),
          availableAt: widget.controller.passwordResetResendAvailableAt,
          status: widget.controller.passwordResetOtpStatus,
          isLoading: widget.controller.isLoading,
          onResend: widget.controller.resendPasswordResetOtp,
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
    this.onBack,
  });

  final String title;
  final String subtitle;
  final String? errorMessage;
  final String? statusMessage;
  final VoidCallback? onBack;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          keyboardOpen ? 88 : AppSpacing.xl,
        ),
        children: [
          SizedBox(
            height: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: onBack == null
                  ? null
                  : IconButton(
                      tooltip: 'Back',
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                    ),
            ),
          ),
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
          const SizedBox(height: AppSpacing.xl),
          const _AuthSupportFooter(),
        ],
      ),
    );
  }
}

class _AuthSupportFooter extends StatelessWidget {
  const _AuthSupportFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Need help with account access?',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        TextButton.icon(
          onPressed: () => _contactSupport(context),
          icon: const Icon(Icons.support_agent_outlined, size: 18),
          label: const Text(LegalContent.supportEmail),
        ),
      ],
    );
  }

  Future<void> _contactSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: LegalContent.supportEmail,
      queryParameters: {'subject': 'Payqure Home account access support'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    await Clipboard.setData(
      const ClipboardData(text: LegalContent.supportEmail),
    );
    if (!context.mounted) {
      return;
    }
    AppSnackBar.show(context, message: 'Support email copied.');
  }
}

class _LabeledField extends StatefulWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.readOnly = false,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final bool readOnly;
  final FormFieldValidator<String>? validator;

  @override
  State<_LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<_LabeledField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant _LabeledField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _isObscured = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: widget.controller,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          obscureText: widget.obscureText && _isObscured,
          readOnly: widget.readOnly,
          validator: widget.validator,
          scrollPadding: const EdgeInsets.only(bottom: 120),
          enableSuggestions: !widget.obscureText,
          autocorrect: !widget.obscureText,
          decoration: InputDecoration(
            hintText: widget.hintText ?? widget.label,
            suffixIcon: widget.readOnly
                ? const Icon(
                    Icons.lock_outline,
                    semanticLabel: 'Email cannot be edited',
                  )
                : widget.obscureText
                ? IconButton(
                    key: ValueKey(
                      '${widget.label.toLowerCase().replaceAll(' ', '-')}-visibility',
                    ),
                    tooltip: _isObscured ? 'Show password' : 'Hide password',
                    onPressed: () {
                      setState(() => _isObscured = !_isObscured);
                    },
                    icon: Icon(
                      _isObscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
