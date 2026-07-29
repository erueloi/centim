import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

const _webRecaptchaEnterpriseSiteKey =
    '6LefL2stAAAAAIr5-h0slY1DraYh3_z5wQUvdwSm';

/// Activa App Check abans que cap servei Firebase faci peticions.
///
/// Web usa una clau pública reCAPTCHA Enterprise restringida als dominis de
/// Cèntim. Android release usa Play Integrity; en debug genera un token de
/// desenvolupament que es pot registrar a la consola.
Future<void> initializeAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      providerWeb: ReCaptchaEnterpriseProvider(_webRecaptchaEnterpriseSiteKey),
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  } catch (error) {
    // App Check encara pot estar propagant configuració en una instal·lació
    // nova. L'app arrenca, però Firebase AI Logic decidirà segons l'enforcement
    // del servidor si admet o rebutja la petició.
    debugPrint('⚠️ App Check no s’ha pogut activar: $error');
  }
}
