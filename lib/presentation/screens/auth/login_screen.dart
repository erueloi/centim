import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/repository_providers.dart';
import 'package:centim/l10n/app_localizations.dart';

/// Missatge comprensible per als errors de Firebase Auth (en lloc del
/// "[firebase_auth/...]" cru).
String authErrorMessage(AppLocalizations l10n, Object error) {
  if (error is! FirebaseAuthException) return l10n.authErrorGeneric;
  switch (error.code) {
    case 'invalid-credential':
    case 'invalid-login-credentials':
    case 'wrong-password':
    case 'user-not-found':
      return l10n.authErrorInvalidCredentials;
    case 'email-already-in-use':
      return l10n.authErrorEmailInUse;
    case 'weak-password':
      return l10n.authErrorWeakPassword;
    case 'invalid-email':
    case 'missing-email':
      return l10n.authErrorInvalidEmail;
    case 'too-many-requests':
      return l10n.authErrorTooManyRequests;
    case 'network-request-failed':
      return l10n.authErrorNetwork;
    default:
      return l10n.authErrorGeneric;
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistering = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = ref.read(authRepositoryProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isRegistering) {
        await auth.createUserWithEmailAndPassword(email, password);
      } else {
        await auth.signInWithEmailAndPassword(email, password);
      }
    } catch (e) {
      debugPrint('Error d\'autenticació: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _errorMessage = authErrorMessage(l10n, e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showResetPasswordDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final auth = ref.read(authRepositoryProvider);
    final emailController =
        TextEditingController(text: _emailController.text.trim());

    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        var sending = false;
        String? error;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> send() async {
              setDialogState(() {
                sending = true;
                error = null;
              });
              try {
                await auth.sendPasswordResetEmail(emailController.text.trim());
                if (ctx.mounted) Navigator.pop(ctx, true);
              } on FirebaseAuthException catch (e) {
                // No revelem si el compte existeix: es tracta com un enviament.
                if (e.code == 'user-not-found') {
                  if (ctx.mounted) Navigator.pop(ctx, true);
                  return;
                }
                setDialogState(() {
                  sending = false;
                  error = authErrorMessage(l10n, e);
                });
              } catch (e) {
                setDialogState(() {
                  sending = false;
                  error = authErrorMessage(l10n, e);
                });
              }
            }

            return AlertDialog(
              title: Text(l10n.resetPasswordTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.resetPasswordBody),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorText: error,
                      errorMaxLines: 3,
                    ),
                    onSubmitted: (_) => sending ? null : send(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancelButton),
                ),
                TextButton(
                  onPressed: sending ? null : send,
                  child: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.resetPasswordSendButton),
                ),
              ],
            );
          },
        );
      },
    );
    emailController.dispose();

    if (sent == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.resetPasswordSent),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = ref.read(authRepositoryProvider);

    try {
      await auth.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _errorMessage = l10n.googleSignInError);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with top margin/safe area considerations not strictly needed if centered
                // but added spacing as requested for "air"
                const SizedBox(height: 48),
                Image.asset('assets/images/logo_centim.png', height: 280),
                const SizedBox(height: 32),

                // Login Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          width: double.infinity,
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: l10n.emailLabel,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: l10n.passwordLabel,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? l10n.showPassword
                                : l10n.hidePassword,
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        onSubmitted: (_) => _isLoading ? null : _submit(),
                      ),
                      if (!_isRegistering)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed:
                                _isLoading ? null : _showResetPasswordDialog,
                            child: Text(
                              l10n.forgotPasswordButton,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ),
                      SizedBox(height: _isRegistering ? 32 : 16),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed: _submit,
                              // Style handled by theme
                              child: Text(
                                _isRegistering
                                    ? l10n.signUpButton
                                    : l10n.signInButton,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _signInWithGoogle,
                              icon: const Icon(Icons.login),
                              label: Text(l10n.googleSignInButton),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () =>
                            setState(() => _isRegistering = !_isRegistering),
                        child: Text(
                          _isRegistering
                              ? l10n.alreadyHaveAccountText
                              : l10n.noAccountText,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48), // Bottom spacing
              ],
            ),
          ),
        ),
      ),
    );
  }
}
