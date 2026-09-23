import 'package:flutter/material.dart';

import '../../core/widgets/connection_help.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authStateProvider = StreamProvider<AuthState>(
  (ref) => Supabase.instance.client.auth.onAuthStateChange,
);
final signedInProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider);
  final user = Supabase.instance.client.auth.currentUser;
  return user != null && !user.isAnonymous;
});

Future<bool> requireAccount(BuildContext context) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user != null && !user.isAnonymous) return true;
  await Navigator.of(context)
      .push<bool>(MaterialPageRoute(builder: (_) => const AuthScreen()));
  final signedIn = Supabase.instance.client.auth.currentUser;
  return signedIn != null && !signedIn.isAnonymous;
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController(text: '+95');
  bool _phoneMode = false;
  final _form = GlobalKey<FormState>();
  bool _signup = true, _busy = false, _obscure = true;
  String? _message;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      final phone = _phoneMode
          ? _phone.text.replaceAll(RegExp(r'[\s()-]'), '')
          : null;
      final email = _phoneMode ? null : _email.text.trim();
      final response = _signup
          ? await auth.signUp(
              email: email,
              phone: phone,
              password: _password.text,
            )
          : await auth.signInWithPassword(
              email: email,
              phone: phone,
              password: _password.text,
            );
      if (!mounted) return;
      if (response.session != null) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _signup = false;
          _message = _phoneMode
              ? 'Phone confirmation is still required by the service. Contact support or register with email instead.'
              : 'Check your email to confirm your account, then return here to sign in.';
        });
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
      if (mounted && isConnectionFailure(error)) {
        await showConnectionHelp(context);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = 'Could not connect. Check your internet connection and try again.',
        );
        if (isConnectionFailure(error)) await showConnectionHelp(context);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your Novella account')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.auto_stories_rounded,
                    size: 60,
                    color: Color(0xFF1477FA),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _signup ? 'Make room for your next read' : 'Welcome back',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Browse freely as a guest. Create an account or sign in to read and save books.',
                  ),
                  const SizedBox(height: 24),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Email'),
                        icon: Icon(Icons.email_outlined),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Phone'),
                        icon: Icon(Icons.phone_outlined),
                      ),
                    ],
                    selected: {_phoneMode},
                    onSelectionChanged: _busy
                        ? null
                        : (value) => setState(() {
                            _phoneMode = value.first;
                            _message = null;
                            _form.currentState?.reset();
                          }),
                  ),
                  const SizedBox(height: 16),
                  if (_phoneMode) ...[
                    TextFormField(
                      controller: _phone,
                      enabled: !_busy,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        helperText: 'Include country code. Myanmar: +959… (omit the first 0).',
                        helperMaxLines: 2,
                      ),
                      validator: (value) =>
                          RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(
                            (value ?? '').replaceAll(RegExp(r'[\s()-]'), ''),
                          )
                          ? null
                          : 'Use international format, for example +959123456789',
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          value != null &&
                              RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(value.trim())
                          ? null
                          : 'Enter a valid email address',
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    enabled: !_busy,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your password'
                        : _signup && value.length < 8
                        ? 'Use at least 8 characters'
                        : null,
                  ),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(_message!, semanticsLabel: _message),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(
                      _busy
                          ? 'Please wait…'
                          : _signup
                          ? 'Create account'
                          : 'Sign in',
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _signup = !_signup;
                            _message = null;
                          }),
                    child: Text(
                      _signup
                          ? 'Already have an account? Sign in'
                          : 'New here? Create an account',
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.pop(context, false),
                    child: const Text('Continue browsing as guest'),
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

class AccountGate extends ConsumerWidget {
  const AccountGate({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(signedInProvider)) return child;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 48),
              const SizedBox(height: 16),
              const Text('Sign in to start reading'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => requireAccount(context),
                child: const Text('Sign up / Sign in'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep browsing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
