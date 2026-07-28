import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:centim/l10n/app_localizations.dart';
import '../../providers/financial_summary_provider.dart';
import '../../widgets/financial_health_indicator.dart';
import '../../widgets/dashboard_quick_actions.dart';
import '../../widgets/dashboard_donut_chart.dart';
import '../../widgets/cash_flow_card.dart';
import '../../widgets/close_cycle_dialog.dart';
import '../../widgets/dashboard_savings_card.dart';
import '../../widgets/watchlist_section.dart';
import '../../widgets/ai_insight_card.dart';

import '../../providers/billing_cycle_provider.dart';
import '../../providers/incoherences_provider.dart';
import '../../providers/cash_flow_provider.dart';
import '../settings/billing_cycles_settings_screen.dart';
import '../settings/user_profile_screen.dart';
import '../settings/incoherences_screen.dart';
import 'cycle_reports_agenda_screen.dart';

import '../../../domain/services/version_check_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late ConfettiController _confettiController;
  late final VersionCheckService _versionCheckService; // Service instance
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    // Check for smart banner after frame build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSmartBanner();
    });

    // Initialize & Check for updates
    _versionCheckService = VersionCheckService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _versionCheckService.checkForUpdates(context);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _checkSmartBanner() {
    final activeCycle = ref.read(activeCycleProvider);
    if (activeCycle.id == 'virtual_natural_month') {
      return; // Don't check virtual
    }

    final now = DateTime.now();
    final daysSinceStart = now.difference(activeCycle.startDate).inDays;
    final daysUntilEnd = activeCycle.endDate.difference(now).inDays;

    // Logic: >25 days passed OR <= 3 days left
    if (daysSinceStart > 25 || daysUntilEnd <= 3) {
      if (mounted) {
        setState(() {
          _showBanner = true;
        });
      }
    }
  }

  Future<void> _closeCycleAndCelebrate() async {
    final activeCycle = ref.read(activeCycleProvider);
    if (activeCycle.id == 'virtual_natural_month') {
      return;
    }

    // 1. Confirmació: el saldo inicial del cicle nou arrossega tota la cadena
    //    posterior, així que l'usuari l'ha de veure i validar abans.
    final decision = await showCloseCycleDialog(context, ref, activeCycle);
    if (decision == null) return; // cancel·lat

    // 2. Tancament únic: calendari i saldo segellat passen pel mateix mètode.
    try {
      await ref
          .read(billingCycleNotifierProvider.notifier)
          .closeCurrentAndStartNextCycle(
            activeCycle,
            payday: decision.payday,
            openingBalanceForNext: decision.openingBalance,
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No s’ha pogut tancar el cicle: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // 3. UI Updates
    setState(() {
      _showBanner = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.cycleClosedMessage(activeCycle.name),
        ),
        backgroundColor: Colors.green,
      ),
    );

    // 4. Confetti!
    _confettiController.play();
  }

  /// Badge d'incoherències a la barra superior (estil notificació): apareix
  /// NOMÉS si n'hi ha i desapareix sol quan la llista queda a zero.
  Widget _buildIncoherencesBadge(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        // Totes les comprovacions de manteniment sumen al mateix badge: són
        // coses per revisar, i l'usuari no ha de recordar quantes llistes hi ha.
        final int incoherences = ref.watch(incoherencesProvider).maybeWhen(
              data: (items) => items.length,
              orElse: () => 0,
            );
        final int noAccount = ref.watch(movementsWithoutAccountCountProvider);
        final int gridProblems = ref.watch(cycleGridProblemsProvider).length;
        final int count = incoherences + noAccount + gridProblems;
        if (count == 0) return const SizedBox.shrink();
        return IconButton(
          tooltip: '$count avís${count == 1 ? '' : 'os'} a revisar',
          icon: Badge.count(
            count: count,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
            child: const Icon(Icons.rule),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const IncoherencesScreen()),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // l10n unused here as title is hardcoded "Inici"
    final summaryAsync = ref.watch(financialSummaryNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Consumer(
          builder: (context, ref, child) {
            final cycle = ref.watch(activeCycleProvider);
            final dateFormat = DateFormat('dd MMM', 'ca_ES');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cycle.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  '${dateFormat.format(cycle.startDate)} - ${dateFormat.format(cycle.endDate)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            );
          },
        ),
        automaticallyImplyLeading: false,
        actions: [
          _buildIncoherencesBadge(context),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: AppLocalizations.of(context)!.cycleHistoryTooltip,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CycleReportsAgendaScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: AppLocalizations.of(context)!.cycleSettingsTooltip,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BillingCyclesSettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: AppLocalizations.of(context)!.profileTooltip,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_showBanner)
                MaterialBanner(
                  padding: const EdgeInsets.all(16),
                  content: Text(
                    AppLocalizations.of(context)!.endOfMonthBanner,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.anthracite,
                    ),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.copper,
                    child: Icon(Icons.priority_high, color: Colors.white),
                  ),
                  backgroundColor: AppTheme.copper.withValues(alpha: 0.1),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showBanner = false;
                        });
                      },
                      child: Text(AppLocalizations.of(context)!.notYet),
                    ),
                    TextButton(
                      onPressed: _closeCycleAndCelebrate,
                      child: Text(
                        AppLocalizations.of(context)!.startNewMonth,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              Expanded(
                child: summaryAsync.when(
                  skipLoadingOnRefresh: true,
                  data: (summary) => SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AiInsightCard(),
                            const SizedBox(height: 16),
                            DashboardDonutChart(summary: summary),
                            const SizedBox(height: 16),
                            // Caixa just sota el pressupost: les dues preguntes
                            // ("quants diners hi ha" i "on gasto") separades,
                            // però adjacents, que és on neix la confusió.
                            const CashFlowCard(),
                            const SizedBox(height: 16),
                            const WatchlistSection(),
                            const SizedBox(height: 16),
                            const DashboardSavingsCard(),
                            const SizedBox(height: 32),
                            const FinancialHealthIndicator(),
                            const SizedBox(height: 32),
                            // Quick Access Section (Nou disseny)
                            DashboardQuickActions(
                              onNominaReceived: _closeCycleAndCelebrate,
                            ),
                            const SizedBox(height: 80), // Space for FAB
                          ],
                        ),
                      ),
                    ),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
