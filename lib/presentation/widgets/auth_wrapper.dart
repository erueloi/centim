import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/main_scaffold.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/setup_group_screen.dart';
import '../screens/settings/bank_sync_screen.dart';
import '../providers/auth_providers.dart';
import '../../domain/services/bank_callback.dart';
import '../../domain/services/bank_sync_service.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        // User is logged in, check user profile for group
        final userProfileAsync = ref.watch(userProfileProvider);

        return userProfileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profile.currentGroupId == null) {
              return const SetupGroupScreen();
            }

            return const _BankCallbackHandler(child: MainScaffold());
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, s) =>
              Scaffold(body: Center(child: Text('Error loading profile: $e'))),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

/// Processa el retorn de l'SCA bancària un cop l'usuari està autenticat:
/// bescanvia el code/state (finalizeBankSession) i porta a la config del banc.
class _BankCallbackHandler extends ConsumerStatefulWidget {
  final Widget child;
  const _BankCallbackHandler({required this.child});

  @override
  ConsumerState<_BankCallbackHandler> createState() =>
      _BankCallbackHandlerState();
}

class _BankCallbackHandlerState extends ConsumerState<_BankCallbackHandler> {
  @override
  void initState() {
    super.initState();
    final pending = BankCallback.consume();
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _process(pending));
    }
  }

  Future<void> _process(({String code, String state}) pending) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(bankSyncServiceProvider).finalizeSession(
            code: pending.code,
            state: pending.state,
          );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Banc connectat correctament.')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BankSyncScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('No s\'ha pogut connectar el banc: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
