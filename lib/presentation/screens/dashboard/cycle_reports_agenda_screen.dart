import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/billing_cycle_provider.dart';
import '../../widgets/cycle_report_view.dart';
import '../../../domain/models/billing_cycle.dart';

class CycleReportsAgendaScreen extends ConsumerStatefulWidget {
  const CycleReportsAgendaScreen({super.key});

  @override
  ConsumerState<CycleReportsAgendaScreen> createState() =>
      _CycleReportsAgendaScreenState();
}

class _CycleReportsAgendaScreenState
    extends ConsumerState<CycleReportsAgendaScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  List<BillingCycle> _closedCycles = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // We will jump to the correct page in build once data is loaded
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (_currentIndex < _closedCycles.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cyclesAsync = ref.watch(billingCycleNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Cicles'),
        // No custom actions needed yet
      ),
      body: cyclesAsync.when(
        data: (cycles) {
          final now = DateTime.now();
          // Filter closed cycles (end date is in the past)
          _closedCycles = cycles.where((c) {
            // Need to compare properly including the 12:00:00 normalized time
            return c.endDate.isBefore(now);
          }).toList();

          // Sort chronologically (oldest first, so swiping right goes to newer)
          _closedCycles.sort((a, b) => a.startDate.compareTo(b.startDate));

          if (_closedCycles.isEmpty) {
            return const Center(
              child: Text(
                'Encara no tens cicles tancats.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // Initialize controller to the last closed cycle if it's the first build
          // (we check if _pageController has clients. If not, we set initialPage)
          if (!_pageController.hasClients) {
            _currentIndex = _closedCycles.length - 1;
            _pageController = PageController(initialPage: _currentIndex);
          }

          final currentCycle = _closedCycles[_currentIndex];

          return Column(
            children: [
              // Date Selector Header
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentIndex > 0 ? _goToPrevious : null,
                      color: _currentIndex > 0
                          ? AppTheme.copper
                          : Colors.grey[300],
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            currentCycle.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.anthracite,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '${DateFormat('dd MMM').format(currentCycle.startDate)} - ${DateFormat('dd MMM').format(currentCycle.endDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentIndex < _closedCycles.length - 1
                          ? _goToNext
                          : null,
                      color: _currentIndex < _closedCycles.length - 1
                          ? AppTheme.copper
                          : Colors.grey[300],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _closedCycles.length,
                  itemBuilder: (context, index) {
                    final cycle = _closedCycles[index];
                    return CycleReportView(cycle: cycle);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
