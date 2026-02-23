import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/category.dart';
import '../sheets/add_transaction_sheet.dart';
import '../providers/category_notifier.dart';

class DashboardQuickActions extends ConsumerStatefulWidget {
  final VoidCallback onNominaReceived;

  const DashboardQuickActions({super.key, required this.onNominaReceived});

  @override
  ConsumerState<DashboardQuickActions> createState() =>
      _DashboardQuickActionsState();
}

class _DashboardQuickActionsState extends ConsumerState<DashboardQuickActions> {
  TransactionType? _expandedType;

  void _toggleExpanded(TransactionType type) {
    setState(() {
      if (_expandedType == type) {
        _expandedType = null;
      } else {
        _expandedType = type;
      }
    });
  }

  void _openTransactionSheet(BuildContext context, Category category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => AddTransactionSheet(
        initialCategory: category,
        initialIsExpense: _expandedType == TransactionType.expense,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accés Ràpid',
          style: TextStyle(
            color: AppTheme.anthracite,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.money_off,
                        label: 'Despesa',
                        color: Colors.red.shade400,
                        isSelected: _expandedType == TransactionType.expense,
                        onTap: () => _toggleExpanded(TransactionType.expense),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.attach_money,
                        label: 'Ingrés',
                        color: Colors.green.shade500,
                        isSelected: _expandedType == TransactionType.income,
                        onTap: () => _toggleExpanded(TransactionType.income),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.monetization_on,
                        label: 'Ja he cobrat!',
                        color: AppTheme.copper,
                        isSelected: false,
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text('💰 Confirmar nòmina'),
                              content: const Text(
                                'Has rebut la nòmina? Això tancarà el cicle actual i n\'obrirà un de nou.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel·lar'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.copper,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Sí, he cobrat!'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            widget.onNominaReceived();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (_expandedType != null) ...[
                  const SizedBox(height: 16),
                  Consumer(
                    builder: (context, ref, child) {
                      final categoriesAsync =
                          ref.watch(categoryNotifierProvider);
                      return categoriesAsync.when(
                        data: (categories) {
                          final filteredCats = categories
                              .where((c) => c.type == _expandedType)
                              .toList();
                          if (filteredCats.isEmpty) {
                            return const Center(
                                child: Text("No hi ha categories"));
                          }
                          return _buildCategoryGrid(filteredCats);
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Center(child: Text('Error: $e')),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(List<Category> categories) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _expandedType == TransactionType.expense
                ? 'On has fet la despesa?'
                : 'D\'on prové l\'ingrés?',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.anthracite,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 90,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final rawColor = cat.color;
              final color =
                  rawColor != null ? Color(rawColor) : Colors.grey.shade400;

              return InkWell(
                onTap: () => _openTransactionSheet(context, cat),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.1),
                      radius: 26,
                      child:
                          Text(cat.icon, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? color.withValues(alpha: 0.2)
          : color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
