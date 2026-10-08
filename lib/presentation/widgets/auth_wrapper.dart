import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:centim/l10n/app_localizations.dart';
import '../widgets/main_scaffold.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/setup_group_screen.dart';
import '../screens/settings/bank_sync_screen.dart';
import '../providers/auth_providers.dart';
import '../providers/group_providers.dart';
import '../../data/providers/repository_providers.dart';
import '../../domain/services/bank_callback.dart';
import '../../domain/services/bank_sync_service.dart';
import '../providers/bank_consent_provider.dart';

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

            return const _GroupAccessGuard(
              child: _BankCallbackHandler(child: MainScaffold()),
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, s) => _ProfileErrorScreen(error: e),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

/// No s'ha pogut carregar el perfil ni després dels reintents: deixa
/// tornar-ho a provar o canviar de compte, en lloc d'encallar l'app.
class _ProfileErrorScreen extends ConsumerWidget {
  final Object error;
  const _ProfileErrorScreen({required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No s\'ha pogut carregar el teu perfil.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(userProfileProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tornar-ho a provar'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
                child: const Text('Tancar sessió'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Si l'usuari perd l'accés al grup actual (l'owner l'ha tret del grup), les
/// regles deneguen la lectura del grup. Llavors es buida el currentGroupId
/// perquè l'app torni a la pantalla de crear o unir-se a un grup, en lloc de
/// quedar-se amb totes les dades en error.
class _GroupAccessGuard extends ConsumerWidget {
  final Widget child;
  const _GroupAccessGuard({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(currentGroupProvider, (_, next) {
      final error = next.error;
      if (error is FirebaseException && error.code == 'permission-denied') {
        ref.read(authRepositoryProvider).clearCurrentGroupId();
      }
    });
    return child;
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
    // NOTA: aquí NO es repara res automàticament. Les transaccions
    // desincronitzades es detecten en mode NOMÉS LECTURA i es mostren a
    // Configuració → Incoherències, on l'usuari decideix si es reparen.
    // Una escriptura silenciosa a cada arrencada és inacceptable.
  }

  Future<void> _process(({String code, String state}) pending) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(bankSyncServiceProvider).finalizeSession(
            code: pending.code,
            state: pending.state,
          );
      ref.invalidate(bankConnectionStateProvider);
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
        SnackBar(
          content: Text(
            isBankNotEnabled(e)
                ? AppLocalizations.of(context)!.bankNotEnabledForGroup
                : 'No s\'ha pogut connectar el banc: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
