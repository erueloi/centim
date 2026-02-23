import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/billing_cycle.dart';
import '../../providers/billing_cycle_provider.dart';
import '../../providers/auth_providers.dart';
import '../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class BillingCyclesSettingsScreen extends ConsumerWidget {
  const BillingCyclesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclesAsync = ref.watch(billingCycleNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cicles de Facturació'),
        actions: [
          // Delete All (Trash) - Keep only this one
          cyclesAsync.maybeWhen(
            data: (cycles) => cycles.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    tooltip: 'Esborrar Tot',
                    color: Colors.red,
                    onPressed: () => _showDeleteAllDialog(context, ref),
                  )
                : const SizedBox(),
            orElse: () => const SizedBox(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Consolidated "Plan" FAB
          FloatingActionButton.small(
            heroTag: 'plan_fab',
            onPressed: () =>
                _showPlanSheet(context, ref), // Renamed from Replan
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.anthracite,
            tooltip: 'Planificar Anualitat',
            child: const Icon(Icons.calendar_month),
          ),
          const SizedBox(height: 16),

          // Add Single (Extended)
          FloatingActionButton.extended(
            heroTag: 'add_fab',
            onPressed: () => _showEditCycleSheet(context, ref),
            backgroundColor: AppTheme.anthracite,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Nou Cicle'),
          ),
        ],
      ),
      body: cyclesAsync.when(
        data: (cycles) {
          if (cycles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'No hi ha cicles configurats.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showPlanSheet(context, ref),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Planificar Anualitat'),
                  ),
                ],
              ),
            );
          }

          // Sort and Group
          final sortedCycles = List<BillingCycle>.from(cycles)
            ..sort((a, b) => a.startDate.compareTo(b.startDate));

          final grouped = _groupCyclesByYear(sortedCycles);
          final now = DateTime.now();

          return CustomScrollView(
            slivers: [
              for (final year in grouped.keys) ...[
                SliverStickyHeader(year: year),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final cycle = grouped[year]![index];
                    return _TimelineItem(
                      cycle: cycle,
                      isLast: index == grouped[year]!.length - 1,
                      now: now,
                      onEdit: () => _showEditCycleSheet(context, ref, cycle),
                      onDelete: () => ref
                          .read(billingCycleNotifierProvider.notifier)
                          .deleteBillingCycle(cycle.id),
                    );
                  }, childCount: grouped[year]!.length),
                ),
              ],
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ), // Space for FABs
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Map<int, List<BillingCycle>> _groupCyclesByYear(List<BillingCycle> cycles) {
    final Map<int, List<BillingCycle>> groups = {};
    for (var cycle in cycles) {
      final year = cycle.startDate.year;
      if (!groups.containsKey(year)) {
        groups[year] = [];
      }
      groups[year]!.add(cycle);
    }
    return groups;
  }

  // DIALOGS & SHEETS

  Future<void> _showPlanSheet(BuildContext context, WidgetRef ref) async {
    double selectedDay = 28.0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: AppTheme.anthracite,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Planificar Cicles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Això farà dues coses:\n1. Actualitzarà tots els cicles FUTURS que ja existeixen.\n2. Generarà cicles nous per completar els propers 12 mesos.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dia de càrrec mensual:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.copper.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        selectedDay.round().toString(),
                        style: const TextStyle(
                          color: AppTheme.copper,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: selectedDay,
                  min: 1,
                  max: 31,
                  divisions: 30,
                  activeColor: AppTheme.copper,
                  onChanged: (val) => setState(() => selectedDay = val),
                ),
                Center(
                  child: Text(
                    'Es cobrarà el dia ${selectedDay.round()} de cada mes',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await ref
                        .read(billingCycleNotifierProvider.notifier)
                        .configureAnnualSchedule(selectedDay.round());

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Planificació anual configurada!'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.anthracite,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Aplicar Planificació'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ... (Keep existing _showGenerateDialog, _showEditCycleDialog, _showDeleteAllDialog logic)
  Future<void> _showDeleteAllDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esborrar TOTS els cicles?'),
        content: const Text(
          'Aquesta acció eliminarà tots els cicles de facturació existents.\n\nNo es pot desfer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Esborrar Tot'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(billingCycleNotifierProvider.notifier).deleteAllCycles();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tots els cicles s\'han esborrat.')),
        );
      }
    }
  }

  Future<void> _showEditCycleSheet(
    BuildContext context,
    WidgetRef ref, [
    BillingCycle? existingCycle,
  ]) async {
    final isEditing = existingCycle != null;
    final nameController = TextEditingController(
      text: existingCycle?.name ?? '',
    );
    DateTime startDate = existingCycle?.startDate ?? DateTime.now();
    DateTime endDate =
        existingCycle?.endDate ?? DateTime.now().add(const Duration(days: 30));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final dateFormat = DateFormat('dd MMM yyyy');
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Editar Cicle' : 'Nou Cicle',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom del Cicle (ex: Febrer 2025)',
                    border: OutlineInputBorder(),
                    hintText: 'Introdueix un nom únic',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => startDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data Inici',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today, size: 20),
                          ),
                          child: Text(dateFormat.format(startDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => endDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data Fi',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today, size: 20),
                          ),
                          child: Text(dateFormat.format(endDate)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;

                    final groupId =
                        ref.read(currentGroupIdProvider).valueOrNull;
                    if (groupId == null) return;

                    final adjustedEndDate = DateTime(
                      endDate.year,
                      endDate.month,
                      endDate.day,
                      23,
                      59,
                      59,
                    );

                    final cycle = BillingCycle(
                      id: existingCycle?.id ?? '',
                      groupId: groupId,
                      name: nameController.text,
                      startDate: startDate,
                      endDate: adjustedEndDate,
                    );

                    if (isEditing) {
                      await ref
                          .read(billingCycleNotifierProvider.notifier)
                          .updateBillingCycle(cycle);
                    } else {
                      // Check for duplicate name
                      final cycles =
                          ref.read(billingCycleNotifierProvider).valueOrNull ??
                              [];
                      final duplicate =
                          cycles.where((c) => c.name == cycle.name).firstOrNull;

                      if (duplicate != null) {
                        // Show warning dialog ON TOP of the sheet
                        final confirmOverwrite = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Cicle existent'),
                            content: Text(
                              "Ja existeix un cicle anomenat '${cycle.name}'. Vols sobreescriure'l?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel·lar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Sobreescriure'),
                              ),
                            ],
                          ),
                        );

                        if (confirmOverwrite != true) return;

                        final updatedCycle = cycle.copyWith(id: duplicate.id);
                        await ref
                            .read(billingCycleNotifierProvider.notifier)
                            .updateBillingCycle(updatedCycle);
                      } else {
                        await ref
                            .read(billingCycleNotifierProvider.notifier)
                            .addBillingCycle(cycle);
                      }
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.anthracite,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SliverStickyHeader extends StatelessWidget {
  final int year;
  const SliverStickyHeader({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: Colors.grey[50], // Slightly distinguished background
        child: Row(
          children: [
            Text(
              year.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.anthracite,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: Divider()),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final BillingCycle cycle;
  final bool isLast;
  final DateTime now;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TimelineItem({
    required this.cycle,
    required this.isLast,
    required this.now,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Determine Type
    final isPast = cycle.endDate.isBefore(now);
    final isActive = !isPast && cycle.startDate.isBefore(now);
    final isFuture = !isPast && !isActive;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Line
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Expanded(child: Container(width: 2, color: Colors.grey[300])),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 16),
              child: _buildCard(context, isPast, isActive, isFuture),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    bool isPast,
    bool isActive,
    bool isFuture,
  ) {
    final dateFormat = DateFormat('dd MMM');

    if (isPast) {
      // Past: Minimal text
      return Opacity(
        opacity: 0.6,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cycle.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${dateFormat.format(cycle.startDate)} - ${dateFormat.format(cycle.endDate)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (isActive) {
      // Active: Big Primary Card
      final daysLeft = cycle.endDate.difference(now).inDays;

      return Card(
        elevation: 4,
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${cycle.name} (Actual)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const Icon(Icons.edit, color: AppTheme.anthracite),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${dateFormat.format(cycle.startDate)} - ${dateFormat.format(cycle.endDate)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Falten ${daysLeft > 0 ? daysLeft : 0} dies per tancar',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Future: Editable Card
    return Dismissible(
      key: Key(cycle.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (dir) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Esborrar cicle?'),
            content: const Text('Segur que vols esborrar aquest cicle futur?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sí'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cycle.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${dateFormat.format(cycle.startDate)} - ${dateFormat.format(cycle.endDate)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
