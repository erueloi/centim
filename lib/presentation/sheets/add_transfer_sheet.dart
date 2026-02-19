import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/asset.dart';
import '../../domain/models/transfer.dart';
import '../providers/asset_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/transfer_provider.dart';

class AddTransferSheet extends ConsumerStatefulWidget {
  const AddTransferSheet({super.key});

  @override
  ConsumerState<AddTransferSheet> createState() => _AddTransferSheetState();
}

class _AddTransferSheetState extends ConsumerState<AddTransferSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  String? _sourceAssetId;
  String? _destinationId;
  TransferDestinationType _destinationType = TransferDestinationType.asset;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0 || _sourceAssetId == null || _destinationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Omple tots els camps obligatoris')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get names for snapshot
      final assets = await ref.read(assetNotifierProvider.future);
      final source = assets.firstWhere((a) => a.id == _sourceAssetId);

      String destName;
      if (_destinationType == TransferDestinationType.asset) {
        final dest = assets.firstWhere((a) => a.id == _destinationId);
        destName = dest.name;
      } else {
        final debts = await ref.read(debtNotifierProvider.future);
        final dest = debts.firstWhere((d) => d.id == _destinationId);
        destName = dest.name;
      }

      await ref.read(transferNotifierProvider.notifier).addTransfer(
            amount: amount,
            sourceAssetId: _sourceAssetId!,
            sourceAssetName: source.name,
            destinationType: _destinationType,
            destinationId: _destinationId!,
            destinationName: destName,
            date: _selectedDate,
            note: _noteController.text.isNotEmpty ? _noteController.text : null,
          );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(assetNotifierProvider);
    final debtsAsync = ref.watch(debtNotifierProvider);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Center(
                child: Text(
                  'Nova Transferència',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.anthracite,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Icon(
                  Icons.swap_horiz,
                  size: 40,
                  color: Colors.blueGrey[400],
                ),
              ),
              const SizedBox(height: 24),

              // --- Amount ---
              Center(
                child: Text(
                  'Import',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '€',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  IntrinsicWidth(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.anthracite,
                              ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Source (Origen) ---
              Text(
                'Origen',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              assetsAsync.when(
                data: (assets) {
                  final liquidAssets = assets
                      .where(
                        (a) =>
                            a.type == AssetType.bankAccount ||
                            a.type == AssetType.cash,
                      )
                      .toList();
                  if (liquidAssets.isEmpty) {
                    return const Text(
                      'No tens comptes líquids. Crea un actiu de tipus "Compte Bancari" o "Efectiu".',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _sourceAssetId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                    ),
                    items: liquidAssets
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              '${a.name} (${a.amount.toStringAsFixed(2)}€)',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _sourceAssetId = val),
                    hint: const Text('Selecciona origen'),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error carregant actius'),
              ),
              const SizedBox(height: 24),

              // --- Destination (Destí) ---
              Text(
                'Destí',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              // Destination type selector
              SegmentedButton<TransferDestinationType>(
                segments: const [
                  ButtonSegment(
                    value: TransferDestinationType.asset,
                    label: Text('Actiu'),
                    icon: Icon(Icons.account_balance),
                  ),
                  ButtonSegment(
                    value: TransferDestinationType.debt,
                    label: Text('Deute'),
                    icon: Icon(Icons.credit_card),
                  ),
                ],
                selected: {_destinationType},
                onSelectionChanged:
                    (Set<TransferDestinationType> newSelection) {
                  setState(() {
                    _destinationType = newSelection.first;
                    _destinationId = null;
                  });
                },
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
              const SizedBox(height: 12),

              if (_destinationType == TransferDestinationType.asset)
                assetsAsync.when(
                  data: (assets) {
                    final liquidAssets = assets
                        .where(
                          (a) =>
                              (a.type == AssetType.bankAccount ||
                                  a.type == AssetType.cash) &&
                              a.id != _sourceAssetId,
                        )
                        .toList();
                    if (liquidAssets.isEmpty) {
                      return const Text(
                        'No hi ha altres comptes líquids disponibles.',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: _destinationId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        prefixIcon: const Icon(Icons.account_balance),
                      ),
                      items: liquidAssets
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                '${a.name} (${a.amount.toStringAsFixed(2)}€)',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _destinationId = val),
                      hint: const Text('Selecciona destí'),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error carregant actius'),
                )
              else
                debtsAsync.when(
                  data: (debts) {
                    if (debts.isEmpty) {
                      return const Text(
                        'No tens deutes registrats.',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: _destinationId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        prefixIcon: const Icon(Icons.credit_card),
                      ),
                      items: debts
                          .map(
                            (d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(
                                '${d.name} (${d.currentBalance.toStringAsFixed(2)}€)',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _destinationId = val),
                      hint: const Text('Selecciona deute'),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error carregant deutes'),
                ),
              const SizedBox(height: 24),

              // --- Date & Note ---
              Row(
                children: [
                  InputChip(
                    avatar: const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppTheme.anthracite,
                    ),
                    label: Text(
                      DateUtils.isSameDay(_selectedDate, DateTime.now())
                          ? 'Avui'
                          : '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _selectedDate = d);
                    },
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'Nota (opcional)',
                  prefixIcon: const Icon(Icons.note_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 32),

              // --- Save Button ---
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.swap_horiz),
                  label: const Text(
                    'Fer Transferència',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
