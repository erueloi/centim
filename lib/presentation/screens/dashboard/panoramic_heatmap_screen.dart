import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/panoramic_heatmap_provider.dart';
import '../../../domain/models/heatmap_data.dart';
import 'package:centim/l10n/app_localizations.dart';
import 'heatmap_filter_sheet.dart';

class PanoramicHeatmapScreen extends ConsumerWidget {
  const PanoramicHeatmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapAsync = ref.watch(panoramicHeatmapProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.panoramicTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const HeatmapFilterSheet(),
              );
            },
          ),
        ],
      ),
      body: heatmapAsync.when(
        data: (state) => _HeatmapBody(state: state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _HeatmapBody extends ConsumerWidget {
  final HeatmapState state;

  const _HeatmapBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.allCycles.isEmpty || state.allCategories.isEmpty) {
      return const Center(child: Text('No hi ha dades suficients.'));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM yyyy', 'ca_ES');
    // Filter only selected cycles for columns
    final selectedCycles = state.allCycles
        .where((c) => state.selectedCycleIds.contains(c.id))
        .toList();
    final cycleIdsWithData =
        ref.watch(panoramicCycleIdsWithTransactionsProvider);
    final selectedCycleIdsWithData = selectedCycles
        .where((cycle) => cycleIdsWithData.contains(cycle.id))
        .map((cycle) => cycle.id)
        .toList();
    final savingsCategories =
        state.allCategories.where(isSavingsBudgetCategory).toList();

    bool isSavingsRow(HeatmapRow row) {
      return savingsCategories.any(
        (category) =>
            category.id == row.id ||
            category.subcategories.any((sub) => sub.id == row.id),
      );
    }

    final horizontalController = ScrollController();
    final verticalController = ScrollController();

    return Scrollbar(
      controller: verticalController,
      thumbVisibility: true,
      child: Scrollbar(
        controller: horizontalController,
        thumbVisibility: true,
        notificationPredicate: (notification) => notification.depth == 1,
        child: SingleChildScrollView(
          controller: verticalController,
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            controller: horizontalController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              horizontalMargin: 16,
              headingRowColor:
                  WidgetStateProperty.all(colorScheme.surfaceContainerHighest),
              columns: [
                DataColumn(
                  label: Text(
                    'CATEGORIA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                ...selectedCycles.map(
                  (cycle) {
                    final hasTransactions = cycleIdsWithData.contains(cycle.id);
                    return DataColumn(
                      label: Text(
                        dateFormat.format(cycle.endDate).toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasTransactions
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                      ),
                    );
                  },
                ),
                const DataColumn(
                  numeric: true,
                  label: Text(
                    'MITJANA',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const DataColumn(
                  numeric: true,
                  label: Text(
                    'ACUM.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: state.visibleRows.map((row) {
                final isTotalRow = row.isTotalRow;
                final savingsRow = isSavingsRow(row);
                final savingsSummaryRow = savingsCategories.any(
                  (category) => category.id == row.id,
                );
                final averageCell = aggregateHeatmapCells(
                  row,
                  selectedCycleIdsWithData,
                  average: true,
                );
                final accumulatedCell = aggregateHeatmapCells(
                  row,
                  selectedCycleIdsWithData,
                  average: false,
                );
                return DataRow(
                  color: isTotalRow
                      ? WidgetStateProperty.all(
                          colorScheme.primaryContainer.withValues(alpha: 0.3))
                      : savingsRow
                          ? WidgetStateProperty.all(
                              Colors.green.withValues(alpha: 0.07))
                          : null,
                  cells: [
                    DataCell(
                      _CategoryNameCell(
                        row: row,
                        isSavingsRow: savingsRow,
                        onToggle: isTotalRow
                            ? null
                            : () => ref
                                .read(panoramicHeatmapProvider.notifier)
                                .toggleCategoryExpansion(row.id),
                      ),
                    ),
                    ...selectedCycles.map((cycle) {
                      final cell = row.cells[cycle.id];
                      return DataCell(
                        _HeatmapCellWidget(
                          cell: cell,
                          isTotalRow: isTotalRow,
                          isSavingsRow: savingsRow,
                          isSavingsSummaryRow: savingsSummaryRow,
                          hasTransactions: cycleIdsWithData.contains(cycle.id),
                        ),
                      );
                    }),
                    DataCell(
                      _HeatmapCellWidget(
                        cell: averageCell,
                        isTotalRow: isTotalRow,
                        isSavingsRow: savingsRow,
                        isSavingsSummaryRow: savingsSummaryRow,
                        hasTransactions: averageCell != null,
                        isSummary: true,
                      ),
                    ),
                    DataCell(
                      _HeatmapCellWidget(
                        cell: accumulatedCell,
                        isTotalRow: isTotalRow,
                        isSavingsRow: savingsRow,
                        isSavingsSummaryRow: savingsSummaryRow,
                        hasTransactions: accumulatedCell != null,
                        isSummary: true,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryNameCell extends StatelessWidget {
  final HeatmapRow row;
  final VoidCallback? onToggle;
  final bool isSavingsRow;

  const _CategoryNameCell({
    required this.row,
    required this.isSavingsRow,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (row.isTotalRow) {
      return Text(
        row.name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: colorScheme.primary,
        ),
      );
    }

    if (row.isSubCategory) {
      return Padding(
        padding: const EdgeInsets.only(left: 32.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.subdirectory_arrow_right,
                size: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(
              row.name,
              style: TextStyle(
                color: isSavingsRow
                    ? Colors.green.shade800
                    : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            row.isExpanded
                ? Icons.keyboard_arrow_down
                : Icons.keyboard_arrow_right,
            color: colorScheme.onSurface,
          ),
          onPressed: onToggle,
        ),
        const SizedBox(width: 8),
        Text(row.icon),
        const SizedBox(width: 8),
        Text(
          row.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSavingsRow ? Colors.green.shade800 : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _HeatmapCellWidget extends StatelessWidget {
  final HeatmapCell? cell;
  final bool isTotalRow;
  final bool isSavingsRow;
  final bool isSavingsSummaryRow;
  final bool hasTransactions;
  final bool isSummary;

  const _HeatmapCellWidget({
    this.cell,
    this.isTotalRow = false,
    this.isSavingsRow = false,
    this.isSavingsSummaryRow = false,
    this.hasTransactions = true,
    this.isSummary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (cell == null || !hasTransactions) {
      return Tooltip(
        message: isSummary
            ? 'No hi ha mesos amb moviments.'
            : 'Aquest cicle no té moviments.',
        child: Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '—',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
      );
    }

    final deviation = cell!.deviation;
    final budgeted = cell!.budgeted;
    final spent = cell!.spent;

    // Color logic
    Color backgroundColor = Colors.transparent;
    double opacity = 0.0;

    if (isSavingsRow) {
      // Estalviar per sobre del previst és positiu; el dèficit és l'alerta.
      if (deviation > 0 || (budgeted == 0 && spent > 0)) {
        backgroundColor = Colors.green;
        opacity = 0.55;
      } else if (deviation < 0) {
        final percentageUnder = budgeted > 0 ? deviation.abs() / budgeted : 1.0;
        backgroundColor = percentageUnder > 0.20 ? Colors.red : Colors.orange;
        opacity = 0.55;
      }
    } else {
      if (budgeted == 0.0 && spent > 0.0) {
        backgroundColor = Colors.red;
        opacity = 0.8;
      } else if (deviation > 0) {
        final percentageOver = deviation / budgeted;
        if (percentageOver > 0.20) {
          backgroundColor = Colors.red;
          opacity = 0.6;
        } else {
          backgroundColor = Colors.orange;
          opacity = 0.6;
        }
      } else if (deviation < 0) {
        backgroundColor = Colors.green;
        opacity = 0.4;
      }
    }

    final color = backgroundColor.withValues(alpha: opacity);
    final text = '${deviation > 0 ? '+' : ''}${deviation.toStringAsFixed(0)}€';

    return Tooltip(
      message: '${isSavingsRow ? 'Previst' : 'Pressupostat'}: '
          '${budgeted.toStringAsFixed(2)}€ | '
          '${isSavingsSummaryRow ? 'Estalvi net' : isSavingsRow ? 'Aportat' : 'Gastat'}: '
          '${spent.toStringAsFixed(2)}€',
      child: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: isTotalRow || isSummary ? 14 : 12,
            fontWeight: (deviation != 0 || isTotalRow)
                ? FontWeight.bold
                : FontWeight.normal,
            color: opacity > 0.5 ? Colors.white : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
