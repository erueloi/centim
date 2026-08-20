import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../widgets/auth_wrapper.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _version = '1.3.5';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _navigateToHome();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = info.version;
        });
      }
    } catch (_) {}
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
                    fontFamily: 'Roboto',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Text & Version
          Positioned(
            left: 0,
            right: 0,
            bottom: 36,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Per tenir registrat fins l'últim CÈNTIM",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'v$_version',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11.5,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
