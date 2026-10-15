import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/enums.dart';
import '../onboarding/service_selection_screen.dart';
import 'auth_controller.dart';

/// Combined login / register screen. Uses the service selected during onboarding.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.initialIsRegister = true});

  /// Whether to open in "Create account" mode (vs. "Log in").
  final bool initialIsRegister;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _isRegister = widget.initialIsRegister;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authControllerProvider);
    final service = ref.read(selectedServiceProvider) ?? AadiService.spaces;

    final ok = _isRegister
        ? await auth.register(
            email: _emailController.text,
            password: _passwordController.text,
            name: _nameController.text,
            service: service,
          )
        : await auth.login(
            email: _emailController.text,
            password: _passwordController.text,
          );

    if (!ok && mounted) {
      final message = ref.read(authControllerProvider).error ?? 'Failed.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
    // On success, the router redirect handles navigation automatically.
  }

  void _comingSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider sign-in arrives with the connected API.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final service = ref.watch(selectedServiceProvider) ?? AadiService.spaces;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegister ? 'Create account' : 'Welcome back'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Continuing to ${service.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.tagline,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (_isRegister) ...[
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isRegister ? 'Create account' : 'Log in'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: auth.isLoading
                      ? null
                      : () => setState(() => _isRegister = !_isRegister),
                  child: Text(_isRegister
                      ? 'Already have an account? Log in'
                      : 'New to Aadi? Create an account'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or continue with',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialIconButton(
                      tooltip: 'Continue with Google',
                      color: const Color(0xFF4285F4),
                      letter: 'G',
                      onTap: auth.isLoading ? null : () => _comingSoon('Google'),
                    ),
                    const SizedBox(width: 20),
                    _SocialIconButton(
                      tooltip: 'Continue with Facebook',
                      color: const Color(0xFF1877F2),
                      letter: 'f',
                      onTap: auth.isLoading ? null : () => _comingSoon('Facebook'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon-only circular social sign-in mark (current trend, vs. a full pill
/// button) — a plain lettered brand mark stands in for a trademarked logo.
class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({
    required this.tooltip,
    required this.color,
    required this.letter,
    required this.onTap,
  });

  final String tooltip;
  final Color color;
  final String letter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              letter,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
