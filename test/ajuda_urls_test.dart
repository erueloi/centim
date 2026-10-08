import 'package:flutter_test/flutter_test.dart';

import 'package:centim/ajuda/ajuda_urls.dart';
import 'package:centim/ajuda/ancores_ajuda.dart';

void main() {
  test('l\'àncora del banc propi és la que comprova el portafoli', () {
    expect(AncoresAjuda.bancPropi, 'banc-propi');
  });

  test('construeix <base>/apps/centim/guia#<àncora>', () {
    expect(
      ajudaUri(AncoresAjuda.bancPropi, baseUrl: 'https://erueloi-portfolio.web.app').toString(),
      'https://erueloi-portfolio.web.app/apps/centim/guia#banc-propi',
    );
  });

  test('accepta la base amb una barra final', () {
    expect(
      ajudaUri(AncoresAjuda.bancPropi, baseUrl: 'https://exemple.cat/').toString(),
      'https://exemple.cat/apps/centim/guia#banc-propi',
    );
  });

  test('una base buida, sense https o amb query fa servir la de per defecte', () {
    const expected = 'https://erueloi-portfolio.web.app/apps/centim/guia#banc-propi';
    for (final base in ['', 'http://exemple.cat', 'javascript:alert(1)', 'https://x.cat?a=1', 'no és una url']) {
      expect(ajudaUri(AncoresAjuda.bancPropi, baseUrl: base).toString(), expected, reason: base);
    }
  });

  test('sense Remote Config inicialitzat (tests), fa servir la base per defecte', () {
    expect(
      ajudaUri(AncoresAjuda.bancPropi).toString(),
      'https://erueloi-portfolio.web.app/apps/centim/guia#banc-propi',
    );
  });
}
