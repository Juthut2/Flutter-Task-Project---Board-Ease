import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/helpers.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/message_banner.dart';
import '../../widgets/password_field.dart';
import '../../widgets/profile_details_fields.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String? _gender;
  DateTime? _birthday;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final gender = _gender;
    final birthday = _birthday;
    if (gender == null || birthday == null) return;

    final auth = context.read<AuthProvider>();
    setState(() => _submitting = true);
    final success = await auth.registerTenant(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      gender: gender,
      birthday: birthday,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      AppHelpers.showSnackBar(
        context,
        auth.errorMessage ?? 'Registration failed. Please try again.',
        isError: true,
      );
    }
  }

  Future<void> _google() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      AppHelpers.showSnackBar(
        context,
        auth.errorMessage ?? 'Google sign-in failed. Please try again.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final busy = _submitting || auth.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Create tenant account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Join BoardEase',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a tenant account to browse rooms and reserve '
                      'your next home.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (auth.errorMessage != null) ...<Widget>[
                      MessageBanner(
                        message: auth.errorMessage!,
                        icon: Icons.error_outline_rounded,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _nameController,
                      enabled: !busy,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.name],
                      validator: Validators.name,
                      onChanged: (_) => auth.clearError(),
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      enabled: !busy,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[
                        AutofillHints.telephoneNumber,
                      ],
                      validator: Validators.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: '09171234567',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ProfileDetailsFields(
                      gender: _gender,
                      onGenderChanged: (value) =>
                          setState(() => _gender = value),
                      birthday: _birthday,
                      onBirthdayChanged: (value) =>
                          setState(() => _birthday = value),
                      enabled: !busy,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.email],
                      validator: Validators.email,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _passwordController,
                      enabled: !busy,
                      label: 'Password',
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.newPassword],
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'At least 8 characters, with a letter and a number.',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _confirmController,
                      enabled: !busy,
                      label: 'Confirm password',
                      textInputAction: TextInputAction.done,
                      validator: (value) => Validators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                      onFieldSubmitted: (_) {
                        if (!busy) _submit();
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: busy ? null : _submit,
                      child: busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Text('Create account'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: busy ? null : _google,
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                      label: const Text('Continue with Google'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'A verification link will be sent to your email. You '
                      'must verify it before using the app. Google accounts '
                      'are already verified.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
