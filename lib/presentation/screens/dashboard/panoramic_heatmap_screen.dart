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
                  (cycle) => DataColumn(
                    label: Text(
                      dateFormat.format(cycle.endDate).toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
              rows: state.visibleRows.map((row) {
                final isTotalRow = row.isTotalRow;
                return DataRow(
                  color: isTotalRow
                      ? WidgetStateProperty.all(
                          colorScheme.primaryContainer.withValues(alpha: 0.3))
                      : null,
                  cells: [
                    DataCell(
                      _CategoryNameCell(
                        row: row,
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
                        _HeatmapCellWidget(cell: cell, isTotalRow: isTotalRow),
                      );
                    }),
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

  const _CategoryNameCell({required this.row, this.onToggle});

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
                  color: colorScheme.onSurface.withValues(alpha: 0.7)),
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
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _HeatmapCellWidget extends StatelessWidget {
  final HeatmapCell? cell;
  final bool isTotalRow;

  const _HeatmapCellWidget({this.cell, this.isTotalRow = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (cell == null) {
      return Center(
          child: Text('-',
              style:
                  TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4))));
    }

    final deviation = cell!.deviation;
    final budgeted = cell!.budgeted;
    final spent = cell!.spent;

    // Color logic
    Color backgroundColor = Colors.transparent;
    double opacity = 0.0;

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

    final color = backgroundColor.withValues(alpha: opacity);
    final text = '${deviation > 0 ? '+' : ''}${deviation.toStringAsFixed(0)}€';

    return Tooltip(
      message:
          'Pressupostat: ${budgeted.toStringAsFixed(2)}€ | Gastat: ${spent.toStringAsFixed(2)}€',
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
            fontSize: isTotalRow ? 14 : 12,
            fontWeight:
                (deviation != 0 || isTotalRow) ? FontWeight.bold : FontWeight.normal,
            color: opacity > 0.5 ? Colors.white : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
