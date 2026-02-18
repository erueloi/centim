import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/billing_cycle_provider.dart';
import '../../domain/models/billing_cycle.dart';
import 'package:intl/intl.dart';

class CycleSelector extends ConsumerWidget {
  const CycleSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCycle = ref.watch(activeCycleProvider);
    final cycles = ref.watch(billingCycleNotifierProvider).valueOrNull ?? [];
    final dateFormat = DateFormat('dd MMM', 'ca_ES');

    // Find index of active cycle to determine PREV/NEXT validity
    // Logic: sorted by date
    final sortedCycles = List<BillingCycle>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final currentIndex = sortedCycles.indexWhere((c) => c.id == activeCycle.id);
    final hasPrevious = currentIndex > 0;
    final hasNext =
        currentIndex != -1 && currentIndex < sortedCycles.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: hasPrevious
                    ? () {
                        // Select previous
                        final prev = sortedCycles[currentIndex - 1];
                        ref.read(selectedCycleProvider.notifier).select(prev);
                      }
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                activeCycle.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.anthracite,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: hasNext
                    ? () {
                        // Select next
                        final next = sortedCycles[currentIndex + 1];
                        ref.read(selectedCycleProvider.notifier).select(next);
                      }
                    : null,
              ),
            ],
          ),
          Text(
            '${dateFormat.format(activeCycle.startDate)} - ${dateFormat.format(activeCycle.endDate)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
