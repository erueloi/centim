import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash/splash_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:centim/l10n/app_localizations.dart';

import 'package:firebase_core/firebase_core.dart';

import 'core/firebase/app_check_bootstrap.dart';
import 'firebase_options.dart';
import 'domain/services/bank_callback.dart';
import 'domain/services/ai_coach_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeAppCheck();
  await AiCoachConfig.initialize();

  // Captura el retorn de l'SCA bancària (web: /bank-callback?code&state).
  BankCallback.captureFromUri(Uri.base);

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
