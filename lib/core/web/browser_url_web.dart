import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// `history.replaceState`: canvia l'URL de la pestanya sense recarregar ni
/// deixar l'antiga a l'historial.
void replaceBrowserUrl(String url) {
  final history = globalContext['history'] as JSObject;
  history.callMethod('replaceState'.toJS, null, ''.toJS, url.toJS);
}
