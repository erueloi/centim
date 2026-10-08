// Substitueix l'URL de la pestanya sense recarregar (només al web; a la resta
// de plataformes no fa res).
export 'browser_url_stub.dart'
    if (dart.library.js_interop) 'browser_url_web.dart';
