import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Configuració remota del Coach.
///
/// El valor local garanteix que el Coach funcioni encara que Remote Config no
/// estigui disponible. El valor remot permet canviar de model sense publicar
/// una versió nova de l'app.
class AiCoachConfig {
  static const modelParameter = 'ai_coach_model';
  static const defaultModel = 'gemini-3.6-flash';

  static Future<void> initialize() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 12),
      ),
    );
    await remoteConfig.setDefaults(const {
      modelParameter: defaultModel,
    });

    try {
      await remoteConfig.fetchAndActivate();
    } catch (error) {
      // El valor local continua actiu. No bloquegem l'arrencada ni el Coach
      // perquè Remote Config sigui temporalment inaccessible.
      debugPrint('⚠️ Remote Config no disponible: $error');
    }
  }

  static String get modelName {
    final configured =
        FirebaseRemoteConfig.instance.getString(modelParameter).trim();
    return sanitizeAiCoachModelName(configured);
  }
}

String sanitizeAiCoachModelName(String configured) {
  final validModel = RegExp(r'^gemini-[a-z0-9][a-z0-9.-]*$');
  return validModel.hasMatch(configured)
      ? configured
      : AiCoachConfig.defaultModel;
}
