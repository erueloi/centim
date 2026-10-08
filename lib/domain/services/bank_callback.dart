/// Reté el `code` + `state` que arriben a /bank-callback després de la SCA
/// (web: redirect al mateix navegador). Es captura a l'arrencada (main) i es
/// consumeix un cop l'usuari està autenticat (finalizeBankSession).
class BankCallback {
  static String? _code;
  static String? _state;

  /// Captura code/state si la URL d'arrencada és el callback bancari. Retorna
  /// cert si la URL és el callback (amb codi o amb error del banc): llavors
  /// cal treure-la de la barra d'adreces (vegeu [cleanUrlFor]).
  static bool captureFromUri(Uri uri) {
    if (!isCallback(uri)) return false;
    final c = uri.queryParameters['code'];
    final s = uri.queryParameters['state'];
    if (c != null && c.isNotEmpty && s != null && s.isNotEmpty) {
      _code = c;
      _state = s;
    }
    return true;
  }

  static bool isCallback(Uri uri) => uri.path.contains('bank-callback');

  /// Camí net per substituir el callback: l'arrel de l'app, sense el `code`
  /// (és una credencial d'un sol ús) ni el `state`. Si es quedessin a la
  /// barra, recarregar la pàgina o entrar amb un altre usuari a la mateixa
  /// pestanya tornaria a intentar tancar una autorització ja gastada.
  /// Relatiu (mateix origen); el fragment de Flutter el conserva qui el fa servir.
  static const cleanPath = '/';

  /// Només per als tests.
  static void resetForTest() {
    _code = null;
    _state = null;
  }

  static bool get hasPending => _code != null && _state != null;

  /// Retorna i esborra el callback pendent (un sol ús).
  static ({String code, String state})? consume() {
    if (!hasPending) return null;
    final r = (code: _code!, state: _state!);
    _code = null;
    _state = null;
    return r;
  }
}
