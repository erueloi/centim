import 'package:flutter/material.dart';

/// Colors semàntics compartits pels percentatges de pressupost.
/// No s'usen per repintar les barres existents de Detall.
Color budgetConsumptionColor(double ratio) {
  if (ratio >= 1.0) return Colors.red;
  if (ratio >= 0.8) return Colors.orange;
  return Colors.green;
}

Color budgetAchievementColor(double ratio) {
  if (ratio >= 1.0) return Colors.green;
  if (ratio >= 0.8) return Colors.orange;
  return Colors.red;
}
