import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/panoramic_heatmap_provider.dart';
import 'package:intl/intl.dart';
import 'package:centim/l10n/app_localizations.dart';

class HeatmapFilterSheet extends ConsumerWidget {
  const HeatmapFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapAsync = ref.watch(panoramicHeatmapProvider);
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('MMM yyyy', 'ca_ES');

    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: heatmapAsync.when(
        data: (state) {
          final notifier = ref.read(panoramicHeatmapProvider.notifier);
          final currentRange = notifier.currentCycleRange;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.panoramicTitle,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => notifier.resetFilters(),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.resetFilters),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cycle range selector
                      Text(
                        l10n.heatmapCycleRange,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<int>(
                          segments: [
                            const ButtonSegment(value: 6, label: Text('6')),
                            const ButtonSegment(value: 12, label: Text('12')),
                            const ButtonSegment(value: 24, label: Text('24')),
                            ButtonSegment(
                                value: 0, label: Text(l10n.heatmapAllCycles)),
                          ],
                          selected: {currentRange},
                          onSelectionChanged: (selected) {
                            notifier.setCycleRange(selected.first);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.billingCyclesLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: state.allCycles.map((cycle) {
                          final isSelected =
                              state.selectedCycleIds.contains(cycle.id);
                          return FilterChip(
                            label: Text(dateFormat.format(cycle.endDate)),
                            selected: isSelected,
                            onSelected: (_) =>
                                notifier.toggleCycleFilter(cycle.id),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.categoriesLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.allCategories.length,
                        itemBuilder: (context, index) {
                          final category = state.allCategories[index];
                          final isSelected =
                              state.selectedCategoryIds.contains(category.id);
                          return CheckboxListTile(
                            title: Row(
                              children: [
                                Text(category.icon),
                                const SizedBox(width: 8),
                                Text(category.name),
                              ],
                            ),
                            value: isSelected,
                            onChanged: (_) =>
                                notifier.toggleCategoryFilter(category.id),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
