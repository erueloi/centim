import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/annual_report.dart';
import '../../domain/models/category.dart';
import '../../domain/models/transaction.dart';
import '../../domain/services/annual_report_service.dart';
import '../../domain/services/annual_report_pdf_service.dart';
import '../../domain/services/subcategory_movement_grouping_service.dart';
import '../../l10n/app_localizations.dart';
import '../providers/annual_view_provider.dart';
import '../providers/transaction_notifier.dart';
import '../providers/category_notifier.dart';
import '../providers/billing_cycle_provider.dart';
import '../sheets/add_transaction_sheet.dart';

class AnnualViewTab extends ConsumerWidget {
  const AnnualViewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(annualReportNotifierProvider);
    final selectedYear = ref.watch(annualSelectedYearNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(annualReportNotifierProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Selector d'any + Toggle Real/Projecció compacte + Exportació
            _YearSelectorHeader(
              year: selectedYear,
              reportData: reportAsync.valueOrNull,
              onPrevious: () =>
                  ref.read(annualSelectedYearNotifierProvider.notifier).previousYear(),
              onNext: () =>
                  ref.read(annualSelectedYearNotifierProvider.notifier).nextYear(),
              onShare: reportAsync.hasValue
                  ? () => _showExportDialog(context, reportAsync.value!)
                  : null,
            ),
            const SizedBox(height: 12),

            // 2. Contingut del Report
            reportAsync.when(
              data: (data) => _AnnualReportContent(data: data),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    l10n.errorText(err.toString()),
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, AnnualReportData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AnnualExportSheet(data: data),
    );
  }
}

class _YearSelectorHeader extends ConsumerWidget {
  final int year;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onShare;
  final AnnualReportData? reportData;

  const _YearSelectorHeader({
    required this.year,
    required this.onPrevious,
    required this.onNext,
    required this.onShare,
    this.reportData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayMode = ref.watch(annualDisplayModeNotifierProvider);
    final completedCycles = reportData?.completedCyclesCount ?? 0;
    final totalCycles = reportData?.totalCyclesInYear ?? 12;
    final canProject = completedCycles >= AnnualReportService.kMinCyclesForProjection;
    final effectiveMode = canProject ? displayMode : AnnualDisplayMode.real;

    final dateFormat = DateFormat('dd/MM/yyyy');
    final startDateStr = reportData?.periodStartDate != null ? dateFormat.format(reportData!.periodStartDate!) : '01/01/$year';
    final endDateStr = reportData?.periodEndDate != null ? dateFormat.format(reportData!.periodEndDate!) : dateFormat.format(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Any i fletxes
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Any anterior',
                    onPressed: onPrevious,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$year',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Any següent',
                    onPressed: onNext,
                  ),
                ],
              ),

              // Inline Toggle Real/Projecció + Export
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<AnnualDisplayMode>(
                    segments: [
                      const ButtonSegment<AnnualDisplayMode>(
                        value: AnnualDisplayMode.real,
                        label: Text('Real', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      ButtonSegment<AnnualDisplayMode>(
                        value: AnnualDisplayMode.projected,
                        enabled: canProject,
                        label: const Text('Projecció', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                    selected: {effectiveMode},
                    onSelectionChanged: (Set<AnnualDisplayMode> selected) {
                      ref.read(annualDisplayModeNotifierProvider.notifier).setMode(selected.first);
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 6, vertical: 0)),
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.copper.withValues(alpha: 0.2);
                        }
                        return null;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.copper;
                        }
                        return colorScheme.onSurface.withValues(alpha: 0.7);
                      }),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.ios_share_rounded, size: 16),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    tooltip: 'Exportar informe',
                    onPressed: onShare,
                  ),
                ],
              ),
            ],
          ),
          if (reportData != null && completedCycles > 0) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                '$startDateStr – $endDateStr · $completedCycles de $totalCycles cicles${!canProject ? " · Calen 3 cicles per projectar" : ""}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnnualReportContent extends ConsumerWidget {
  final AnnualReportData data;

  const _AnnualReportContent({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy');

    // 1. CAS LÍMIT: 0 cicles tancats
    if (data.completedCyclesCount == 0 || (data.categories.isEmpty && data.totalRealExpense == 0)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.query_stats_rounded, size: 56, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(
                'Encara no hi ha cap cicle tancat del ${data.year}',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Les xifres reals i les projeccions apareixeran un cop s\'hagi completat el primer cicle.',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final displayMode = ref.watch(annualDisplayModeNotifierProvider);
    final canProject = data.completedCyclesCount >= AnnualReportService.kMinCyclesForProjection;
    final effectiveMode = canProject ? displayMode : AnnualDisplayMode.real;
    final isProjected = effectiveMode == AnnualDisplayMode.projected;

    // Dates del període
    final startDateStr = data.periodStartDate != null ? dateFormat.format(data.periodStartDate!) : '01/01/${data.year}';
    final endDateStr = data.periodEndDate != null ? dateFormat.format(data.periodEndDate!) : dateFormat.format(DateTime.now());

    // Ordenar categories segons el mode actiu
    final sortedCategories = List<AnnualCategoryData>.from(data.categories)..sort((a, b) {
      if (isProjected) {
        return b.projectedAnnualTotal.compareTo(a.projectedAnnualTotal);
      }
      return b.realSpent.compareTo(a.realSpent);
    });

    final sortedIncomeCategories = List<AnnualCategoryData>.from(data.incomeCategories)..sort((a, b) {
      if (isProjected) {
        return b.projectedAnnualTotal.compareTo(a.projectedAnnualTotal);
      }
      return b.realSpent.compareTo(a.realSpent);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Titular KPI Principal
        _AnnualHeadlineCard(data: data, mode: effectiveMode),
        const SizedBox(height: 14),

        // 2. Targeta de Servei de Deute
        _DebtServiceCard(data: data, mode: effectiveMode),
        const SizedBox(height: 20),

        // 3. Despesa per Categoria
        Text(
          'Despesa per Categoria',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedCategories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final categoryData = sortedCategories[index];
            return _CategoryAnnualCard(
              key: ValueKey('annual-cat-${categoryData.categoryId}'),
              categoryData: categoryData,
              totalActiveExpense: isProjected ? data.projectedAnnualExpense : data.totalRealExpense,
              mode: effectiveMode,
              completedCyclesCount: data.completedCyclesCount,
              year: data.year,
            );
          },
        ),
        const SizedBox(height: 24),

        // 4. Ingressos per Categoria
        if (sortedIncomeCategories.isNotEmpty) ...[
          Text(
            'Ingressos per Categoria',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedIncomeCategories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final categoryData = sortedIncomeCategories[index];
              return _CategoryAnnualCard(
                key: ValueKey('annual-inc-cat-${categoryData.categoryId}'),
                categoryData: categoryData,
                totalActiveExpense: isProjected ? data.projectedAnnualIncome : data.totalRealIncome,
                mode: effectiveMode,
                completedCyclesCount: data.completedCyclesCount,
                year: data.year,
              );
            },
          ),
          const SizedBox(height: 24),
        ],

        // 5. Guardioles i Estalvi (al final, col·lapsades)
        if (data.totalRealSavingsDeposits > 0 || data.totalRealSavingsWithdrawals > 0) ...[
          _AnnualSavingsCard(data: data),
          const SizedBox(height: 32),
        ] else ...[
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _AnnualHeadlineCard extends StatelessWidget {
  final AnnualReportData data;
  final AnnualDisplayMode mode;

  const _AnnualHeadlineCard({
    required this.data,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€', decimalDigits: 0);
    final isProjected = mode == AnnualDisplayMode.projected;
    final activeExpense = isProjected ? data.projectedAnnualExpense : data.totalRealExpense;
    final activeIncome = isProjected ? data.projectedAnnualIncome : data.totalRealIncome;
    final activeDiff = isProjected ? data.netAnnualDifference : data.netRealDifference;
    final prefix = isProjected ? '≈ ' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.anthracite,
            AppTheme.anthracite.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.copper.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.copper.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_graph_rounded, color: AppTheme.copper, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isProjected ? 'Projecció Anual (${data.year})' : 'Despesa Real (${data.year})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Import principal
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$prefix${currency.format(activeExpense)}',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isProjected ? '/ any' : 'acumulat',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Mitjana mensual invariant
          Text(
            '${currency.format(data.monthlyAverageExpense)} / mes de mitjana',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.copper,
            ),
          ),
          const SizedBox(height: 14),

          // Badges d'estat (només en mode PROJECCIÓ)
          if (isProjected) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _StatusBadge(
                  label: 'Real',
                  value: '${currency.format(data.totalRealExpense)} (${data.completedCyclesCount} cicles)',
                  color: Colors.greenAccent[700]!,
                  icon: Icons.check_circle_outline_rounded,
                ),
                if (data.remainingCyclesCount > 0)
                  _StatusBadge(
                    label: 'Resta',
                    value: '≈ ${currency.format(data.projectedAnnualExpense - data.totalRealExpense)} (${data.remainingCyclesCount} mesos)',
                    color: Colors.lightBlueAccent,
                    icon: Icons.trending_up_rounded,
                  ),
              ],
            ),
          ],

          if (data.totalRealIncome > 0) ...[
            const SizedBox(height: 14),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),

            // Ingressos i Diferencial Estructural (DOMINANT)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isProjected ? 'Nòmines (contractuals)' : 'Nòmines del període',
                      style: const TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isProjected
                          ? '≈ ${currency.format(data.projectedAnnualRecurringIncome)}'
                          : currency.format(data.totalRealRecurringIncome),
                      style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    if (data.totalRealVariableIncome > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '+${currency.format(data.totalRealVariableIncome)} puntuals',
                        style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Diferencial Estructural',
                      style: TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    () {
                      final structuralDiff = isProjected ? data.netStructuralDifference : data.netRealStructuralDifference;
                      final sign = structuralDiff >= 0 ? "+" : "−";
                      return Text(
                        '${isProjected ? "≈ " : ""}$sign${currency.format(structuralDiff.abs())}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: structuralDiff >= 0 ? Colors.greenAccent[400] : Colors.redAccent[100],
                        ),
                      );
                    }(),
                    const SizedBox(height: 2),
                    () {
                      final treasuryDiff = isProjected ? data.netAnnualDifference : data.netRealDifference;
                      final sign = treasuryDiff >= 0 ? "+" : "−";
                      return Text(
                        'Tresoreria: ${isProjected ? "≈ " : ""}$sign${currency.format(treasuryDiff.abs())}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      );
                    }(),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtServiceCard extends StatelessWidget {
  final AnnualReportData data;
  final AnnualDisplayMode mode;

  const _DebtServiceCard({
    required this.data,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€', decimalDigits: 0);
    final pct = (data.debtServicePercentage * 100).toStringAsFixed(1);
    final colorScheme = Theme.of(context).colorScheme;
    final isProjected = mode == AnnualDisplayMode.projected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_rounded, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Servei de Deute Bancari',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$pct% despesa',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isProjected
                      ? '≈ ${currency.format(data.debtServiceAnnualTotal)} / any  ·  ${currency.format(data.debtServiceMonthlyAverage)} / mes'
                      : '${currency.format(data.debtServiceMonthlyAverage * data.completedCyclesCount)} real  ·  ${currency.format(data.debtServiceMonthlyAverage)} / mes',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnualSavingsCard extends StatefulWidget {
  final AnnualReportData data;

  const _AnnualSavingsCard({
    super.key,
    required this.data,
  });

  @override
  State<_AnnualSavingsCard> createState() => _AnnualSavingsCardState();
}

class _AnnualSavingsCardState extends State<_AnnualSavingsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€', decimalDigits: 0);
    final colorScheme = Theme.of(context).colorScheme;
    final net = widget.data.netSavings;
    final isNegative = net < 0;
    final returnPct = widget.data.savingsReturnedPercentage.toStringAsFixed(0);

    final summaryText = isNegative
        ? 'S\'ha consumit ${currency.format(net.abs())} d\'estalvi acumulat'
        : '$returnPct % retornat al compte';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.savings_rounded, color: Colors.teal, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Moviments de guardioles · $summaryText',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isNegative ? Colors.orangeAccent[200] : colorScheme.onSurface,
                          ),
                        ),
                        if (!_isExpanded) ...[
                          const SizedBox(height: 2),
                          Text(
                            '+${currency.format(widget.data.totalRealSavingsDeposits)} aportats  ·  −${currency.format(widget.data.totalRealSavingsWithdrawals)} retirats',
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Període auditat (${widget.data.completedCyclesCount} cicles tancats) · Valors reals',
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 10),

                  // Línia 1: Aportacions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Aportacions a guardioles (${widget.data.totalRealSavingsDepositsCount} mov.)',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.8)),
                      ),
                      Text(
                        '+${currency.format(widget.data.totalRealSavingsDeposits)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.tealAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Línia 2: Retirades
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Retirades de guardioles (${widget.data.totalRealSavingsWithdrawalsCount} mov.)',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.8)),
                      ),
                      Text(
                        '−${currency.format(widget.data.totalRealSavingsWithdrawals)}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.orangeAccent[200]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Línia 3: Estalvi Net
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estalvi net del període',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                      ),
                      Text(
                        '${net >= 0 ? "+" : "−"}${currency.format(net.abs())}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isNegative ? Colors.redAccent[100] : Colors.greenAccent[400],
                        ),
                      ),
                    ],
                  ),

                  if (isNegative) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'S\'ha consumit ${currency.format(net.abs())} d\'estalvi acumulat d\'exercicis anteriors.',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.redAccent[100]),
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  // Línia 4: Retornat al compte
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Retornat al compte corrent',
                        style: TextStyle(fontSize: 11.5, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                      Text(
                        '$returnPct %',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryAnnualCard extends StatelessWidget {
  final AnnualCategoryData categoryData;
  final double totalActiveExpense;
  final AnnualDisplayMode mode;
  final int completedCyclesCount;
  final int year;

  const _CategoryAnnualCard({
    super.key,
    required this.categoryData,
    required this.totalActiveExpense,
    required this.mode,
    required this.completedCyclesCount,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€', decimalDigits: 0);
    final colorScheme = Theme.of(context).colorScheme;
    final catColor = categoryData.color != null ? Color(categoryData.color!) : AppTheme.copper;
    final isProjected = mode == AnnualDisplayMode.projected;

    final activeAmount = isProjected ? categoryData.projectedAnnualTotal : categoryData.realSpent;
    final activePct = totalActiveExpense > 0 ? (activeAmount / totalActiveExpense) : 0.0;
    final pctFormatted = (activePct * 100).toStringAsFixed(1);
    final prefix = isProjected ? '≈ ' : '';

    // Ordenar subcategories segons el mode actiu
    final sortedSubs = List<AnnualSubcategoryData>.from(categoryData.subcategories)..sort((a, b) {
      if (isProjected) {
        return b.projectedAnnualTotal.compareTo(a.projectedAnnualTotal);
      }
      return b.realSpent.compareTo(a.realSpent);
    });

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(categoryData.icon, style: const TextStyle(fontSize: 20)),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  categoryData.categoryName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$prefix${currency.format(activeAmount)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${currency.format(categoryData.monthlyAverage)} / mes',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '$pctFormatted%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: catColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: activePct.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: colorScheme.outline.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(catColor),
                  ),
                ),
                if (categoryData.yearOverYearDelta != null) ...[
                  const SizedBox(height: 4),
                  _YoYDeltaBadge(delta: categoryData.yearOverYearDelta!),
                ],
              ],
            ),
          ),
          children: [
            if (sortedSubs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sense detall de subcategories',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              )
            else
              ...sortedSubs.map(
                (sub) => _SubcategoryAnnualRow(
                  key: ValueKey('annual-sub-${sub.id}'),
                  categoryId: categoryData.categoryId,
                  sub: sub,
                  parentRealSpent: categoryData.realSpent,
                  parentProjectedTotal: categoryData.projectedAnnualTotal,
                  catColor: catColor,
                  mode: mode,
                  completedCyclesCount: completedCyclesCount,
                  year: year,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SubcategoryAnnualRow extends ConsumerStatefulWidget {
  final String categoryId;
  final AnnualSubcategoryData sub;
  final double parentRealSpent;
  final double parentProjectedTotal;
  final Color catColor;
  final AnnualDisplayMode mode;
  final int completedCyclesCount;
  final int year;

  const _SubcategoryAnnualRow({
    super.key,
    required this.categoryId,
    required this.sub,
    required this.parentRealSpent,
    required this.parentProjectedTotal,
    required this.catColor,
    required this.mode,
    required this.completedCyclesCount,
    required this.year,
  });

  @override
  ConsumerState<_SubcategoryAnnualRow> createState() => _SubcategoryAnnualRowState();
}

class _SubcategoryAnnualRowState extends ConsumerState<_SubcategoryAnnualRow> {
  bool _isExpanded = false;
  bool _isOtherExpanded = false;
  SubcategoryMovementGrouping? _cachedGrouping;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded && _cachedGrouping == null) {
        _computeGrouping();
      }
    });
  }

  void _computeGrouping() {
    final transactions = ref.read(transactionNotifierProvider).valueOrNull ?? [];
    final categories = ref.read(categoryNotifierProvider).valueOrNull ?? [];
    final cycles = ref.read(billingCycleNotifierProvider).valueOrNull ?? [];
    final now = DateTime.now();

    final parentCat = categories.where((c) => c.id == widget.categoryId).firstOrNull ??
        Category(
          id: widget.categoryId,
          name: 'Categoria',
          icon: '📦',
          type: TransactionType.expense,
        );

    // Filtrar estrictament els cicles completats de l'any objectiu per garantir coincidència al 100% amb realSpent
    final yearCycles = cycles.where((c) {
      return c.endDate.year == widget.year || (c.startDate.year == widget.year && c.endDate.year == widget.year);
    }).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final completedCycles = yearCycles.where((c) => c.endDate.isBefore(now)).toList();
    final List<Transaction> yearTxs;

    if (yearCycles.isNotEmpty) {
      yearTxs = transactions.where((tx) {
        final txDate = tx.date;
        return completedCycles.any((cycle) {
          final s = DateTime(cycle.startDate.year, cycle.startDate.month, cycle.startDate.day, 0, 0, 0);
          final e = DateTime(cycle.endDate.year, cycle.endDate.month, cycle.endDate.day, 23, 59, 59);
          return (txDate.isAtSameMomentAs(s) || txDate.isAfter(s)) &&
              (txDate.isAtSameMomentAs(e) || txDate.isBefore(e));
        });
      }).toList();
    } else {
      final completedMonthsCount = widget.year < now.year
          ? 12
          : (widget.year == now.year ? (now.month - 1).clamp(0, 12) : 0);
      if (completedMonthsCount <= 0) {
        yearTxs = [];
      } else {
        final startOfYear = DateTime(widget.year, 1, 1);
        final endOfCompleted = DateTime(widget.year, completedMonthsCount + 1, 0, 23, 59, 59);
        yearTxs = transactions.where((tx) {
          return (tx.date.isAtSameMomentAs(startOfYear) || tx.date.isAfter(startOfYear)) &&
              (tx.date.isAtSameMomentAs(endOfCompleted) || tx.date.isBefore(endOfCompleted));
        }).toList();
      }
    }

    _cachedGrouping = groupSubcategoryMovements(
      cycleTransactions: yearTxs,
      categories: categories,
      category: parentCat,
      subcategoryId: widget.sub.id,
      expectedTotal: widget.sub.realSpent,
      maxVisiblePositiveGroups: 15,
      minimumShare: 0.01,
      minimumAmount: 10.0,
    );
  }

  void _openMovementDetailSheet(BuildContext context, MovementConceptGroup group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MovementGroupDetailSheet(
        group: group,
        subcategoryName: widget.sub.name,
        catColor: widget.catColor,
      ),
    );
  }

  void _openTransactionEditor(BuildContext context, Transaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(
        transactionToEdit: tx,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€', decimalDigits: 0);
    final colorScheme = Theme.of(context).colorScheme;
    final isProjected = widget.mode == AnnualDisplayMode.projected;

    final activeAmount = isProjected ? widget.sub.projectedAnnualTotal : widget.sub.realSpent;
    final activeParentTotal = isProjected ? widget.parentProjectedTotal : widget.parentRealSpent;
    final activePctCat = activeParentTotal > 0 ? (activeAmount / activeParentTotal) : 0.0;
    final pctCat = (activePctCat * 100).toStringAsFixed(0);
    final prefix = isProjected ? '≈ ' : '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: _isExpanded ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.sub.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$prefix${currency.format(activeAmount)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${currency.format(widget.sub.monthlyAverage)} / mes',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                      Text(
                        '$pctCat% categoria',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: activePctCat.clamp(0.0, 1.0),
                      minHeight: 3.5,
                      backgroundColor: colorScheme.outline.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(widget.catColor.withValues(alpha: 0.7)),
                    ),
                  ),
                  if (widget.sub.yearOverYearDelta != null) ...[
                    const SizedBox(height: 2),
                    _YoYDeltaBadge(delta: widget.sub.yearOverYearDelta!, isSmall: true),
                  ],
                ],
              ),
            ),
          ),

          // Detall de comerços desplegats (Lazy / Caching)
          if (_isExpanded) ...[
            if (_cachedGrouping == null || _cachedGrouping!.groups.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  'Sense moviments desglossables per comerç',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isProjected)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Text(
                          'Detall sobre ${widget.completedCyclesCount} cicles reals (${currency.format(widget.sub.realSpent)})',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    Divider(height: 8, thickness: 0.5, color: colorScheme.outline.withValues(alpha: 0.2)),
                    ..._cachedGrouping!.groups.map((group) {
                      if (group.isOther) {
                        final hasFewChildren = group.children.length <= 5 ||
                            group.children.every((c) => c.movementCount == 1);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isOtherExpanded = !_isOtherExpanded;
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.more_horiz_rounded, size: 14, color: AppTheme.copper),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Altres (${group.movementCount})',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface.withValues(alpha: 0.85),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${currency.format(group.amount)} · ${group.displayPercentage}%',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface.withValues(alpha: 0.85),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _isOtherExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 14,
                                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Desplegament intern d'Altres
                            if (_isOtherExpanded)
                              Padding(
                                padding: const EdgeInsets.only(left: 12, top: 2, bottom: 4),
                                child: hasFewChildren
                                    ? Column(
                                        children: group.movements.map((gm) {
                                          final tx = gm.transaction;
                                          final isRefund = tx.isIncome;
                                          return InkWell(
                                            onTap: () => _openTransactionEditor(context, tx),
                                            borderRadius: BorderRadius.circular(4),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 4),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    DateFormat('dd/MM').format(tx.date),
                                                    style: TextStyle(fontSize: 10.5, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      tx.concept,
                                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${isRefund ? '+' : ''}${currency.format(gm.ledgerDelta)}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: isRefund ? Colors.greenAccent[700] : colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      )
                                    : Column(
                                        children: group.children.map((child) {
                                          return InkWell(
                                            onTap: () => _openMovementDetailSheet(context, child),
                                            borderRadius: BorderRadius.circular(4),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 4,
                                                    height: 4,
                                                    decoration: BoxDecoration(
                                                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      '${child.name} (${child.movementCount})',
                                                      style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.8)),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${currency.format(child.amount)} · ${child.percentage >= 0.5 ? "${child.percentage.toStringAsFixed(0)}%" : "<1%"}',
                                                    style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.65)),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Icon(Icons.chevron_right_rounded, size: 12, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ),
                          ],
                        );
                      }

                      // Grup regular de comerç
                      return InkWell(
                        onTap: () => _openMovementDetailSheet(context, group),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.storefront_rounded, size: 13, color: AppTheme.copper),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${group.name} (${group.movementCount})',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${currency.format(group.amount)} · ${group.displayPercentage}%',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.chevron_right_rounded, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MovementGroupDetailSheet extends StatelessWidget {
  final MovementConceptGroup group;
  final String subcategoryName;
  final Color catColor;

  const _MovementGroupDetailSheet({
    required this.group,
    required this.subcategoryName,
    required this.catColor,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: AppTheme.copper, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${group.movementCount} moviments · ${group.displayPercentage}% de $subcategoryName',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                Text(
                  NumberFormat.currency(locale: 'ca_ES', symbol: '€', decimalDigits: 0).format(group.amount),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Llista de moviments scrollable
          Flexible(
            child: group.movements.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Sense moviments'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: group.movements.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 48),
                    itemBuilder: (context, index) {
                      final gm = group.movements[index];
                      final tx = gm.transaction;
                      final isRefund = tx.isIncome;

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isRefund
                                ? Colors.green.withValues(alpha: 0.12)
                                : Colors.red.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isRefund ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isRefund ? Colors.greenAccent[700] : Colors.redAccent[100],
                            size: 15,
                          ),
                        ),
                        title: Text(
                          tx.concept.isNotEmpty ? tx.concept : 'Sense concepte',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                        ),
                        subtitle: Text(
                          '${dateFormat.format(tx.date)}${tx.bankAccountKey != null ? ' · ${tx.bankAccountKey}' : (tx.payer.isNotEmpty ? ' · ${tx.payer}' : '')}',
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                        trailing: Text(
                          '${isRefund ? '+' : '-'}${currency.format(tx.amount)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isRefund ? Colors.greenAccent[700] : colorScheme.onSurface,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => AddTransactionSheet(
                              transactionToEdit: tx,
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _YoYDeltaBadge extends StatelessWidget {
  final double delta;
  final bool isSmall;

  const _YoYDeltaBadge({required this.delta, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    final isPositive = delta > 0;
    final isNeutral = delta == 0;
    final color = isPositive ? Colors.redAccent : (isNeutral ? Colors.grey : Colors.greenAccent[700]!);
    final sign = isPositive ? '+' : '';
    final pctText = '$sign${(delta * 100).toStringAsFixed(1)}%';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: isSmall ? 10 : 12,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          '$pctText vs any anterior',
          style: TextStyle(
            fontSize: isSmall ? 10 : 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _AnnualExportSheet extends StatelessWidget {
  final AnnualReportData data;

  const _AnnualExportSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summaryText = AnnualReportService.generateExecutiveSummary(data);
    final csvText = AnnualReportService.exportToCsv(data);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.ios_share_rounded, color: AppTheme.copper),
              const SizedBox(width: 10),
              Text(
                'Compartir Informe Anual (${data.year})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Exporta o genera l\'informe financer preparat per a converses amb el banc.',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),

          // Botó 1: Exportar / Compartir PDF
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Theme.of(context).colorScheme.surface,
            leading: const CircleAvatar(
              backgroundColor: Colors.redAccent,
              child: Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
            ),
            title: const Text('Exportar PDF Oficial (per al Banc)', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Document A4 net i preparat per imprimir o enviar.'),
            onTap: () async {
              Navigator.pop(context);
              await AnnualReportPdfService.shareOrPrintPdf(data);
            },
          ),
          const SizedBox(height: 10),

          // Botó 2: Copiar Resum Executiu
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Theme.of(context).colorScheme.surface,
            leading: const CircleAvatar(
              backgroundColor: AppTheme.copper,
              child: Icon(Icons.copy_rounded, color: Colors.white, size: 20),
            ),
            title: const Text('Copiar Resum al Portapapers', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Text formatat net amb totals, percentatges i deute bancari.'),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: summaryText));
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.annualSummaryCopied),
                    backgroundColor: Colors.green[800],
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 10),

          // Botó 3: Copiar CSV
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Theme.of(context).colorScheme.surface,
            leading: CircleAvatar(
              backgroundColor: Colors.blueGrey[700],
              child: const Icon(Icons.table_chart_rounded, color: Colors.white, size: 20),
            ),
            title: const Text('Copiar Format CSV', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Dades tabulars per importar fàcilment a Excel o Google Sheets.'),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: csvText));
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CSV copiat al portapapers!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
