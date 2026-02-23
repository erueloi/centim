import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/financial_summary_provider.dart';
import '../../widgets/financial_health_indicator.dart';
import '../../widgets/dashboard_quick_actions.dart';
import '../../widgets/dashboard_donut_chart.dart';
import '../../widgets/watchlist_section.dart';

import '../../providers/billing_cycle_provider.dart';
import '../settings/billing_cycles_settings_screen.dart';

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

    // 1. Logic
    await ref
        .read(billingCycleNotifierProvider.notifier)
        .closeCurrentAndStartNextCycle(activeCycle);

    // 2. UI Updates
    setState(() {
      _showBanner = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cicle de ${activeCycle.name} tancat. Benvingut al nou mes!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }

    // 3. Confetti!
    _confettiController.play();
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'force_close') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('He cobrat avui?'),
                    content: const Text(
                      'Això tancarà el cicle actual i en començarà un de nou immediatament.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel·lar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _closeCycleAndCelebrate();
                        },
                        child: const Text('Sí, tancar mes'),
                      ),
                    ],
                  ),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BillingCyclesSettingsScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'force_close',
                child: Row(
                  children: [
                    Icon(Icons.monetization_on, color: Colors.green),
                    SizedBox(width: 8),
                    Text('💰 He cobrat avui'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Configuració de Cicles'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_showBanner)
                MaterialBanner(
                  padding: const EdgeInsets.all(16),
                  content: const Text(
                    'S\'acosta final de mes. Has cobrat ja la nòmina?',
                    style: TextStyle(
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
                      child: const Text('Encara no'),
                    ),
                    TextButton(
                      onPressed: _closeCycleAndCelebrate,
                      child: const Text(
                        'SÍ, INICIAR NOU MES',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
                            const SizedBox(height: 4),
                            DashboardDonutChart(summary: summary),
                            const SizedBox(height: 12),
                            const WatchlistSection(),
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
