import 'package:flutter/material.dart';
import '../categories/manage_categories_screen.dart';

class PressupostScreen extends StatelessWidget {
  const PressupostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrapper to use BudgetControlScreen within the tab but maybe adjust AppBar if needed
    // Actually BudgetControlScreen has a Scaffold and AppBar.
    // We should probably strip it if we want it inside MainScaffold,
    // BUT MainScaffold has BottomBar, so pages are inside body.
    // If BudgetControlScreen has Scaffold, it might conflict or nest.
    // For now, let's just return it and see. Usually nested scaffolds are okay but duplicate AppBars are not ideal.
    // I'll reuse it as is for MVP.
    // Ideally, I should refactor BudgetControlScreen to be a Widget without Scaffold,
    // or just hide the AppBar here if MainScaffold provides one, but MainScaffold doesn't have a common AppBar.
    return const ManageCategoriesScreen();
  }
}
