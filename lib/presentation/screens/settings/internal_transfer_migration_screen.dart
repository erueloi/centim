import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/asset.dart';
import '../../../domain/models/transfer.dart';
import '../../../domain/services/internal_transfer_migration_service.dart';
import '../../providers/asset_provider.dart';
import '../../providers/transfer_provider.dart';

class InternalTransferMigrationScreen extends ConsumerStatefulWidget {
  const InternalTransferMigrationScreen({super.key});

  @override
  ConsumerState<InternalTransferMigrationScreen> createState() =>
      _InternalTransferMigrationScreenState();
}

class _InternalTransferMigrationScreenState
    extends ConsumerState<InternalTransferMigrationScreen> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final candidates = ref.watch(internalTransferCandidatesProvider);
    final assets =
        ref.watch(assetNotifierProvider).valueOrNull ?? const <Asset>[];
    final converted = (ref.watch(transferNotifierProvider).valueOrNull ??
            const <Transfer>[])
        .where((transfer) => transfer.migratedTransactionSnapshots.isNotEmpty)
        .toList();
    final money = NumberFormat.currency(locale: 'ca_ES', symbol: '€');
    final date = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Traspassos interns històrics')),
      body: candidates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Només són propostes. Cap moviment es modifica fins que '
                'revisis la parella, els comptes i confirmis la conversió.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final convertible =
                    items.where((plan) => plan.canConvert).length;
                final blocked = items.length - convertible;
                final conversionLabel = convertible == 1
                    ? '1 conversió segura'
                    : '$convertible conversions segures';
                final blockedLabel =
                    blocked == 1 ? '1 bloquejada' : '$blocked bloquejades';
                return Text(
                  '$conversionLabel'
                  '${blocked == 0 ? '' : ' · $blockedLabel'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                );
              },
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('No hi ha cap parella històrica pendent.'),
                ),
              ),
            for (final plan in items)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.swap_horiz, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              money.format(plan.candidate.expense.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          Text(
                            '±${plan.candidate.dayDifference} dies',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _legLine(
                        color: Colors.red,
                        sign: '−',
                        concept: plan.candidate.expense.concept,
                        category:
                            '${plan.candidate.expense.categoryName} › ${plan.candidate.expense.subCategoryName}',
                        date: date.format(plan.candidate.expense.date),
                        account: _assetName(
                          assets,
                          plan.candidate.expense.accountId,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _legLine(
                        color: Colors.green,
                        sign: '+',
                        concept: plan.candidate.income.concept,
                        category:
                            '${plan.candidate.income.categoryName} › ${plan.candidate.income.subCategoryName}',
                        date: date.format(plan.candidate.income.date),
                        account: _assetName(
                          assets,
                          plan.candidate.income.accountId,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _migrationCheck(plan, money),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed:
                              _working || assets.isEmpty || !plan.canConvert
                                  ? null
                                  : () => _review(plan, assets),
                          icon: Icon(
                            plan.canConvert
                                ? Icons.fact_check_outlined
                                : Icons.block,
                          ),
                          label: Text(
                            plan.canConvert ? 'Revisar' : 'Bloquejat',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (converted.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Conversions que es poden desfer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              for (final transfer in converted)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history, color: Colors.blueGrey),
                    title: Text(
                      '${transfer.sourceAssetName} → ${transfer.destinationName}',
                    ),
                    subtitle: Text(
                      '${date.format(transfer.date)} · '
                      '${money.format(transfer.amount)} · '
                      '${transfer.migratedTransactionSnapshots.length} apunts',
                    ),
                    trailing: TextButton(
                      onPressed: _working ? null : () => _undo(transfer),
                      child: const Text('Desfer'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _migrationCheck(
    InternalTransferMigrationPlan plan,
    NumberFormat money,
  ) {
    final safe = plan.canConvert;
    final color = safe ? Colors.green : Colors.orange;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: safe
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.savingsGoalName!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  'Saldo de la guardiola: '
                  '${money.format(plan.savingsBalanceBefore)} → '
                  '${money.format(plan.savingsBalanceAfter)}  ✓',
                  style: TextStyle(
                    color: color.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'La retirada «${plan.savingsTransaction!.concept}» es '
                  'conserva. Només es substituirà la despesa '
                  '«${plan.expenseToReplace!.concept}».',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            )
          : Text(
              plan.blockedReason!,
              style: TextStyle(
                color: color.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
    );
  }

  Widget _legLine({
    required Color color,
    required String sign,
    required String concept,
    required String category,
    required String date,
    required String account,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Text(sign, style: TextStyle(color: color)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(concept,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '$date · $account · $category',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _assetName(List<Asset> assets, String? id) {
    if (id == null) return 'sense compte';
    final matches = assets.where((asset) => asset.id == id);
    return matches.isEmpty ? 'compte desconegut' : matches.first.name;
  }

  Future<void> _review(
    InternalTransferMigrationPlan plan,
    List<Asset> assets,
  ) async {
    if (!plan.canConvert) return;
    final candidate = plan.candidate;
    final money = NumberFormat.currency(locale: 'ca_ES', symbol: '€');
    final liquid = assets
        .where(
          (asset) =>
              asset.type == AssetType.bankAccount ||
              asset.type == AssetType.cash,
        )
        .toList();
    String? sourceId = candidate.expense.accountId;
    String? destinationId = candidate.income.accountId;
    if (!liquid.any((asset) => asset.id == sourceId)) sourceId = null;
    if (!liquid.any((asset) => asset.id == destinationId)) {
      destinationId = null;
    }

    final selection = await showDialog<({String source, String destination})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Convertir en traspàs intern?'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Es conservarà la retirada «${plan.savingsTransaction!.concept}» '
                  'i només se substituirà la despesa '
                  '«${plan.expenseToReplace!.concept}» per un traspàs de '
                  '${money.format(candidate.expense.amount)}.',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                _migrationCheck(plan, money),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: sourceId,
                  decoration: const InputDecoration(
                    labelText: 'Compte origen',
                    border: OutlineInputBorder(),
                  ),
                  items: liquid
                      .map(
                        (asset) => DropdownMenuItem(
                          value: asset.id,
                          child: Text(asset.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => sourceId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: destinationId,
                  decoration: const InputDecoration(
                    labelText: 'Compte destí',
                    border: OutlineInputBorder(),
                  ),
                  items: liquid
                      .map(
                        (asset) => DropdownMenuItem(
                          value: asset.id,
                          child: Text(asset.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => destinationId = value),
                ),
                if (sourceId != null && sourceId == destinationId) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Els dos extrems són el mateix actiu de Cèntim: '
                    'el traspàs tindrà efecte zero i quedarà ocult al llistat.',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel·lar'),
            ),
            FilledButton(
              onPressed: sourceId == null || destinationId == null
                  ? null
                  : () => Navigator.pop(
                        dialogContext,
                        (source: sourceId!, destination: destinationId!),
                      ),
              child: const Text('Convertir'),
            ),
          ],
        ),
      ),
    );
    if (selection == null || !mounted) return;

    setState(() => _working = true);
    try {
      await ref.read(internalTransferMigrationServiceProvider).convert(
            plan: plan,
            sourceAssetId: selection.source,
            destinationAssetId: selection.destination,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parella convertida en traspàs.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No s’ha pogut convertir: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _undo(Transfer transfer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desfer la conversió?'),
        content: Text(
          'Es restauraran els ${transfer.migratedTransactionSnapshots.length} '
          'apunts substituïts i s’eliminarà el traspàs. La pota de guardiola '
          'no es modificarà.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel·lar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Desfer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _working = true);
    try {
      await ref.read(internalTransferMigrationServiceProvider).undo(transfer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversió desfeta.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No s’ha pogut desfer: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }
}
