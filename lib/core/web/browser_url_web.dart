import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Canvia el camí i la query de l'URL de la pestanya sense recarregar ni
/// deixar l'antiga a l'historial (`history.replaceState`).
///
/// - Conserva `history.state` i el fragment (`#/...`): són de la navegació de
///   Flutter i, si es perden, la desconfigurarien.
/// - Fa servir `callMethodVarArgs`: amb `callMethod`, un primer argument null
///   es tracta com "cap argument" i `replaceState()` sense arguments llança
///   una excepció (va deixar l'app en blanc a la 1.4.1).
void replaceBrowserUrl(String pathAndQuery) {
  final history = globalContext['history'] as JSObject;
  final location = globalContext['location'] as JSObject;
  final hash = (location['hash'] as JSString?)?.toDart ?? '';
  history.callMethodVarArgs('replaceState'.toJS, [
    history['state'],
    ''.toJS,
    '$pathAndQuery$hash'.toJS,
  ]);
}
