import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/financial_summary.dart';
import '../../providers/category_notifier.dart';
import '../../providers/financial_summary_provider.dart';
import '../../sheets/add_transaction_sheet.dart';
import '../../widgets/budget_summary_card.dart';
import '../../widgets/financial_health_indicator.dart';

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
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    final currencyFormat = NumberFormat.currency(locale: 'ca_ES', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inici'),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NetWorthHeader(
                          summary: summary,
                          currencyFormat: currencyFormat,
                        ),
                        const SizedBox(height: 24),
                        _FluxDeCaixaCard(
                          summary: summary,
                          currencyFormat: currencyFormat,
                        ),
                        const SizedBox(height: 24),
                        const BudgetSummaryCard(),
                        const SizedBox(height: 24),
                        const FinancialHealthIndicator(),
                        const SizedBox(height: 32),

                        // Quick Access Section (Retained)
                        Text(
                          'Accés Ràpid',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppTheme.anthracite,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        categoriesAsync.when(
                          skipLoadingOnRefresh: true,
                          data: (categories) {
                            if (categories.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: categories.map((category) {
                                return _QuickAccessChip(
                                  icon: category.icon,
                                  label: category.name,
                                  category: category,
                                );
                              }).toList(),
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, s) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 80), // Space for FAB
                      ],
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

class _NetWorthHeader extends StatelessWidget {
  final FinancialSummary summary;
  final NumberFormat currencyFormat;

  const _NetWorthHeader({required this.summary, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 180,
                width: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 70,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        color: AppTheme.copper,
                        value: summary.equityRatio * 100,
                        title: '',
                        radius: 12,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        color: Colors.grey[200]!,
                        value: (1 - summary.equityRatio) * 100,
                        title: '',
                        radius: 12,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'El meu Patrimoni',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(summary.totalNetWorth),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.anthracite,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _AssetLiabilityInfo(
              label: 'Actiu',
              amount: summary.totalAssets,
              color: Colors.green[600]!,
              icon: Icons.trending_up,
              currencyFormat: currencyFormat,
            ),
            Container(width: 1, height: 40, color: Colors.grey[300]),
            _AssetLiabilityInfo(
              label: 'Passiu',
              amount: summary.totalLiabilities,
              color: Colors.red[600]!,
              icon: Icons.trending_down,
              currencyFormat: currencyFormat,
            ),
          ],
        ),
      ],
    );
  }
}

class _AssetLiabilityInfo extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final NumberFormat currencyFormat;

  const _AssetLiabilityInfo({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(amount),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.anthracite,
          ),
        ),
      ],
    );
  }
}

class _FluxDeCaixaCard extends StatelessWidget {
  final FinancialSummary summary;
  final NumberFormat currencyFormat;

  const _FluxDeCaixaCard({required this.summary, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    // Progress Bar Logic: Value = Expenses / Income
    // If Income is 0, avoid division by zero.
    double progress = 0.0;
    if (summary.monthlyIncome > 0) {
      progress = (summary.monthlyExpenses / summary.monthlyIncome).clamp(
        0.0,
        1.0,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Flux de Caixa Mensual',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final cycle = ref.watch(activeCycleProvider);
                    final dateFormat = DateFormat('dd MMM', 'ca_ES');
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          cycle.name.toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${dateFormat.format(cycle.startDate)} - ${dateFormat.format(cycle.endDate)}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                color: AppTheme
                    .anthracite, // or a specific color for accumulated expenses
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingressos',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      currencyFormat.format(summary.monthlyIncome),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Disponible',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      currencyFormat.format(summary.availableToSpend),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppTheme.anthracite,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessChip extends StatelessWidget {
  final String icon;
  final String label;
  final Category category;

  const _QuickAccessChip({
    required this.icon,
    required this.label,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddTransactionSheet(initialCategory: category),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.copper.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.copper.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.anthracite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
