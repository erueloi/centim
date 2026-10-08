import 'package:flutter_test/flutter_test.dart';

import 'package:centim/domain/services/bank_callback.dart';

void main() {
  setUp(BankCallback.resetForTest);

  test('captura code i state del callback i demana netejar la URL', () {
    final uri = Uri.parse('https://centim-162bd.web.app/bank-callback?code=c1&state=s1');
    expect(BankCallback.captureFromUri(uri), isTrue);
    expect(BankCallback.consume(), (code: 'c1', state: 's1'));
    // Un sol ús.
    expect(BankCallback.consume(), isNull);
  });

  test('un callback amb error del banc (sense code) també es neteja, però no es processa', () {
    final uri = Uri.parse('https://centim-162bd.web.app/bank-callback?error=access_denied&state=s1');
    expect(BankCallback.captureFromUri(uri), isTrue);
    expect(BankCallback.hasPending, isFalse);
  });

  test('qualsevol altra URL no es toca', () {
    expect(BankCallback.captureFromUri(Uri.parse('https://centim-162bd.web.app/')), isFalse);
    expect(BankCallback.captureFromUri(Uri.parse('http://localhost:5000/#/perfil')), isFalse);
    expect(BankCallback.hasPending, isFalse);
  });

  test('la URL neta és l\'arrel de l\'app, sense code ni state', () {
    for (final raw in [
      'https://centim-162bd.web.app/bank-callback?code=c1&state=s1',
      'http://localhost:5000/bank-callback?code=c1&state=s1#/',
    ]) {
      final clean = BankCallback.cleanUrlFor(Uri.parse(raw));
      expect(clean, isNot(contains('code')));
      expect(clean, isNot(contains('state')));
      expect(clean, isNot(contains('bank-callback')));
      expect(clean, endsWith('/'));
    }
    expect(
      BankCallback.cleanUrlFor(Uri.parse('http://localhost:5000/bank-callback?code=c')),
      'http://localhost:5000/',
    );
  });
}
