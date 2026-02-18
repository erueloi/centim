import 'package:flutter/material.dart';
import '../../widgets/auth_wrapper.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.anthracite, // Dark Grey
      body: Stack(
        children: [
          // Centered Logo
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // We can use the logo here, maybe with a color blend if needed for "white" style,
                // or just the image if it fits. For now, assuming standard logo.
                // Ideally, we'd have a 'logo_white.png' for dark backgrounds.
                // Using ColorFilter to tint it white for the "illuminated" look users asked for.
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/logo_centim.png',
                    height: 150,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "CÈNTIM",
                  style: TextStyle(
                    fontFamily: 'Roboto', // Or system default
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Text
          const Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Center(
              child: Text(
                "Per tenir registrat fins l'últim CÈNTIM",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
