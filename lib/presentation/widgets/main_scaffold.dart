import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'package:centim/l10n/app_localizations.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/patrimoni/patrimoni_screen.dart';
import '../screens/transaction/moviments_screen.dart';
import '../screens/budget/pressupost_screen.dart';
import '../screens/budget/budget_control_screen.dart';
import '../sheets/add_transaction_sheet.dart';
import '../sheets/add_transfer_sheet.dart';
import '../sheets/wealth_sheet.dart';
// Dialogs removed as they are replaced by WealthSheet
// keeping imports for now to avoid breaking other files before refactor
// But usage in FAB:

final selectedIndexProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    // Patrimoni view provider not strictly needed here anymore for FAB logic,
    // as we unified the sheet, but keeping it if needed for other things or removing if unused.
    // It is used in PatrimoniScreen, but here we just need selectedIndex.

    final pages = [
      const DashboardScreen(),
      const BudgetControlScreen(isReadOnly: true),
      const MovimentsScreen(),
      const PressupostScreen(),
      const PatrimoniScreen(),
    ];

    Widget? fab;
    // Indices:
    // 0: Inici
    // 1: Estat
    // 2: Moviments
    // 3: Pressupost
    // 4: Patrimoni

    if (selectedIndex == 0 || selectedIndex == 2) {
      // Inici or Moviments -> Add Transaction or Transfer
      fab = FloatingActionButton(
        heroTag: 'main_fab_transaction',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (_) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.copper,
                    ),
                    title: Text(AppLocalizations.of(context)!.newTransaction),
                    subtitle: Text(AppLocalizations.of(context)!.expenseOrIncome),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AddTransactionSheet(),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.swap_horiz,
                      color: Colors.blueGrey[600],
                    ),
                    title: Text(AppLocalizations.of(context)!.newTransfer),
                    subtitle: Text(
                      AppLocalizations.of(context)!.transferDescription,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AddTransferSheet(),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
        backgroundColor: AppTheme.copper,
        child: const Icon(Icons.add, size: 32),
      );
    } else if (selectedIndex == 4) {
      // Patrimoni -> WealthSheet (Asset, Debt, or Goal)
      fab = FloatingActionButton(
        heroTag: 'main_fab_wealth',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            backgroundColor: Colors.transparent,
            builder: (_) {
              final currentView = ref.read(patrimoniViewProvider);
              final initialType = switch (currentView) {
                PatrimoniView.assets => WealthType.asset,
                PatrimoniView.debts => WealthType.debt,
                PatrimoniView.goals => WealthType.goal,
              };
              return WealthSheet(initialType: initialType);
            },
          );
        },
        backgroundColor: AppTheme.anthracite,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 32),
      );
    }

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(selectedIndexProvider.notifier).state = index;
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, color: AppTheme.anthracite),
            label: AppLocalizations.of(context)!.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.analytics_outlined),
            selectedIcon: const Icon(Icons.analytics, color: AppTheme.anthracite),
            label: AppLocalizations.of(context)!.navDetail,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt, color: AppTheme.anthracite),
            label: AppLocalizations.of(context)!.navTransactions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: const Icon(Icons.pie_chart, color: AppTheme.anthracite),
            label: AppLocalizations.of(context)!.navBudget,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_outlined),
            selectedIcon: const Icon(
              Icons.account_balance,
              color: AppTheme.anthracite,
            ),
            label: AppLocalizations.of(context)!.navWealth,
          ),
        ],
      ),
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
