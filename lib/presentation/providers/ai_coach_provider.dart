import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/ai_coach_service.dart';
import 'financial_summary_provider.dart';
import 'billing_cycle_provider.dart';
import 'category_notifier.dart';
import 'transaction_notifier.dart';
import 'auth_providers.dart';
import '../../domain/models/category.dart';

final aiCoachServiceProvider = Provider<AiCoachService>((ref) {
  return AiCoachService();
});

class AiCoachState {
  final bool isVisible;
  final bool isLoading;
  final String? insight;
  final String? error;

  AiCoachState({
    this.isVisible = false,
    this.isLoading = false,
    this.insight,
    this.error,
  });

  AiCoachState copyWith({
    bool? isVisible,
    bool? isLoading,
    String? insight,
    String? error,
    bool clearError = false,
  }) {
    return AiCoachState(
      isVisible: isVisible ?? this.isVisible,
      isLoading: isLoading ?? this.isLoading,
      insight: insight ?? this.insight,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AiCoachNotifier extends StateNotifier<AiCoachState> {
  final Ref _ref;

  AiCoachNotifier(this._ref) : super(AiCoachState());

  Future<void> _fetchInsight() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 1. Get Summary directly future
      final summary = await _ref.read(financialSummaryNotifierProvider.future);

      // 2. Get active cycle
      final activeCycle = _ref.read(activeCycleProvider);

      // 3. Get categories
      final categories = await _ref.read(categoryNotifierProvider.future);

      // 4. Get transactions
      final allTransactions =
          await _ref.read(transactionNotifierProvider.future);

      // Filter for active cycle like financial_summary_provider does
      final currentMonthTransactions = allTransactions.where((t) {
        final tDay = DateTime(t.date.year, t.date.month, t.date.day, 12, 0, 0);
        final startDay = DateTime(activeCycle.startDate.year,
            activeCycle.startDate.month, activeCycle.startDate.day, 12, 0, 0);
        final endDay = DateTime(activeCycle.endDate.year,
            activeCycle.endDate.month, activeCycle.endDate.day, 12, 0, 0);

        return (tDay.isAtSameMomentAs(startDay) || tDay.isAfter(startDay)) &&
            !tDay.isAfter(endDay);
      }).toList();

      final categoryExpenses = <String, double>{};
      final categoryBudgets = <String, double>{};

      for (final cat in categories) {
        if (cat.type == TransactionType.income) continue;
        double catBudget = 0.0;
        for (final sub in cat.subcategories) {
          catBudget += sub.monthlyBudget;
        }
        categoryBudgets[cat.name] = catBudget;
        categoryExpenses[cat.name] = 0.0; // Initialize
      }

      for (final mov in currentMonthTransactions) {
        // Assume expense if it's not income
        if (!mov.isIncome && mov.categoryId.isNotEmpty) {
          final cat = categories.firstWhere((c) => c.id == mov.categoryId,
              orElse: () =>
                  categories.first // Fallback, shouldn't happen usually
              );
          if (cat.id == mov.categoryId) {
            categoryExpenses[cat.name] =
                (categoryExpenses[cat.name] ?? 0.0) + mov.amount;
          }
        }
      }

      final service = _ref.read(aiCoachServiceProvider);

      final userProfile = _ref.read(userProfileProvider).valueOrNull;
      final userName = userProfile?.name ?? 'Usuari';

      final insight = await service.getInsight(
        userName: userName,
        summary: summary,
        activeCycle: activeCycle,
        categoryExpenses: categoryExpenses,
        categoryBudgets: categoryBudgets,
      );

      if (mounted) {
        state = state.copyWith(isLoading: false, insight: insight);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  void dismiss() {
    state = state.copyWith(isVisible: false);
  }

  void refresh() {
    state = state.copyWith(isVisible: true);
    _fetchInsight();
  }
}

final aiCoachProvider =
    StateNotifierProvider<AiCoachNotifier, AiCoachState>((ref) {
  return AiCoachNotifier(ref);
});
