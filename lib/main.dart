import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash/splash_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:centim/l10n/app_localizations.dart';

import 'package:firebase_core/firebase_core.dart';

import 'core/firebase/app_check_bootstrap.dart';
import 'core/web/browser_url.dart';
import 'firebase_options.dart';
import 'domain/services/bank_callback.dart';
import 'domain/services/ai_coach_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeAppCheck();
  await AiCoachConfig.initialize();

  // Captura el retorn de l'SCA bancària (web: /bank-callback?code&state) i
  // treu el codi de la barra d'adreces: és d'un sol ús i no s'ha de tornar a
  // processar en recarregar ni quedar a l'historial.
  // És una neteja: si falla, l'app ha d'arrencar igualment (a la 1.4.1 una
  // excepció aquí la deixava en blanc).
  if (BankCallback.captureFromUri(Uri.base)) {
    try {
      replaceBrowserUrl(BankCallback.cleanPath);
    } catch (e) {
      debugPrint('No s\'ha pogut netejar l\'URL del callback bancari: $e');
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
