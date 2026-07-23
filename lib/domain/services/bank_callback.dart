/// Reté el `code` + `state` que arriben a /bank-callback després de la SCA
/// (web: redirect al mateix navegador). Es captura a l'arrencada (main) i es
/// consumeix un cop l'usuari està autenticat (finalizeBankSession).
class BankCallback {
  static String? _code;
  static String? _state;

  /// Captura code/state si la URL d'arrencada és el callback bancari.
  static void captureFromUri(Uri uri) {
    if (!uri.path.contains('bank-callback')) return;
    final c = uri.queryParameters['code'];
    final s = uri.queryParameters['state'];
    if (c != null && c.isNotEmpty && s != null && s.isNotEmpty) {
      _code = c;
      _state = s;
    }
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
