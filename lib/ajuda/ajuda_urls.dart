import 'package:firebase_remote_config/firebase_remote_config.dart';

/// URL de la guia de Cèntim al portafoli. La base ve de Remote Config
/// (`help_site_base_url`) perquè es pugui canviar sense publicar l'app.
abstract final class AjudaConfig {
  static const baseUrlParameter = 'help_site_base_url';
  static const defaultBaseUrl = 'https://erueloi-portfolio.web.app';
  static const guiaPath = '/apps/centim/guia';
}

/// Construeix `<base>/apps/centim/guia#<àncora>`. Fes servir sempre una
/// constant de [AncoresAjuda] com a [ancora].
///
/// Una base buida, que no sigui https o mal formada fa servir la de per
/// defecte: un valor remot erroni no pot portar l'usuari a un lloc estrany.
Uri ajudaUri(String ancora, {String? baseUrl}) {
  final base = _validBase(baseUrl ?? _remoteBaseUrl()) ?? AjudaConfig.defaultBaseUrl;
  return Uri.parse('$base${AjudaConfig.guiaPath}').replace(fragment: ancora);
}

String? _validBase(String raw) {
  final trimmed = raw.trim().replaceAll(RegExp(r'/+$'), '');
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  if (uri.hasQuery || uri.hasFragment) return null;
  return trimmed;
}

String _remoteBaseUrl() {
  try {
    return FirebaseRemoteConfig.instance.getString(AjudaConfig.baseUrlParameter);
  } catch (_) {
    return ''; // Remote Config no inicialitzat (p. ex. tests): base per defecte
  }
}
