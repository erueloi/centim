import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:centim/l10n/app_localizations_ca.dart';
import 'package:centim/presentation/screens/auth/login_screen.dart';

void main() {
  final l10n = AppLocalizationsCa();

  String messageFor(String code) =>
      authErrorMessage(l10n, FirebaseAuthException(code: code));

  test('les credencials incorrectes no revelen si el compte existeix', () {
    for (final code in [
      'invalid-credential',
      'invalid-login-credentials',
      'wrong-password',
      'user-not-found',
    ]) {
      expect(messageFor(code), l10n.authErrorInvalidCredentials, reason: code);
    }
  });

  test('errors habituals de registre i xarxa tenen missatge propi', () {
    expect(messageFor('email-already-in-use'), l10n.authErrorEmailInUse);
    expect(messageFor('weak-password'), l10n.authErrorWeakPassword);
    expect(messageFor('invalid-email'), l10n.authErrorInvalidEmail);
    expect(messageFor('too-many-requests'), l10n.authErrorTooManyRequests);
    expect(messageFor('network-request-failed'), l10n.authErrorNetwork);
  });

  test('qualsevol altre error mostra el missatge genèric, mai el codi cru', () {
    expect(messageFor('internal-error'), l10n.authErrorGeneric);
    expect(authErrorMessage(l10n, Exception('boom')), l10n.authErrorGeneric);
  });
}
