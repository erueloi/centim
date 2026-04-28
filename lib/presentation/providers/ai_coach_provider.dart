import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/ai_coach_service.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/category.dart';
import 'financial_summary_provider.dart';
import 'billing_cycle_provider.dart';
import 'category_notifier.dart';
import 'transaction_notifier.dart';
import 'auth_providers.dart';

final aiCoachServiceProvider = Provider<AiCoachService>((ref) {
  return AiCoachService();
});

class AiCoachState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  AiCoachState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AiCoachState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AiCoachState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AiCoachNotifier extends StateNotifier<AiCoachState> {
  final Ref _ref;

  AiCoachNotifier(this._ref) : super(AiCoachState());

  Future<void> sendMessage(String question) async {
    if (question.trim().isEmpty) return;

    // Afegir missatge de l'usuari
    final userMessage = ChatMessage(text: question.trim(), isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearError: true,
    );

    try {
      // 1. Recollir dades financeres
      final financialContext = await _buildFinancialContext();

      // 2. Obtenir nom d'usuari
      final userProfile = _ref.read(userProfileProvider).valueOrNull;
      final userName = userProfile?.name ?? 'Usuari';

      // 3. Cridar servei IA
      final service = _ref.read(aiCoachServiceProvider);
      final response = await service.askQuestion(
        question: question.trim(),
        financialContext: financialContext,
        conversationHistory: state.messages,
        userName: userName,
      );

      // 4. Afegir resposta de la IA
      final aiMessage = ChatMessage(text: response, isUser: false);
      if (mounted) {
        state = state.copyWith(
          messages: [...state.messages, aiMessage],
          isLoading: false,
        );
      }
    } catch (e) {
      if (mounted) {
        // Afegir missatge d'error com a resposta de la IA
        final errorMessage = ChatMessage(
          text: "Ho sento, hi ha hagut un error: ${e.toString().replaceAll('Exception: ', '')} 😔",
          isUser: false,
        );
        state = state.copyWith(
          messages: [...state.messages, errorMessage],
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  void clearHistory() {
    state = AiCoachState();
  }

  /// Construeix el context financer complet per enviar a Gemini.
  /// Limitat als últims 12 cicles per controlar el cost de tokens.
  Future<String> _buildFinancialContext() async {
    final buffer = StringBuffer();

    try {
      // 1. Cicles de facturació
      final cycles =
          _ref.read(billingCycleNotifierProvider).valueOrNull ?? [];
      final sortedCycles = List.from(cycles)
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      final recentCycles = sortedCycles.take(12).toList();

      buffer.writeln('=== CICLES DE FACTURACIÓ (últims 12) ===');
      for (final cycle in recentCycles) {
        buffer.writeln(
            '- ${cycle.name}: ${_formatDate(cycle.startDate)} → ${_formatDate(cycle.endDate)}');
      }

      // 2. Cicle actiu
      final activeCycle = _ref.read(activeCycleProvider);
      buffer.writeln(
          '\n=== CICLE ACTIU: ${activeCycle.name} (${_formatDate(activeCycle.startDate)} → ${_formatDate(activeCycle.endDate)}) ===');

      // 3. Categories i pressupostos
      final categories =
          await _ref.read(categoryNotifierProvider.future);
      buffer.writeln('\n=== CATEGORIES I PRESSUPOSTOS ===');
      for (final cat in categories) {
        if (cat.type == TransactionType.income) {
          buffer.writeln('[INGRÉS] ${cat.name}');
        } else {
          double totalBudget = 0.0;
          for (final sub in cat.subcategories) {
            totalBudget += sub.monthlyBudget;
          }
          buffer.writeln(
              '[DESPESA] ${cat.name} (pressupost total: ${totalBudget.toStringAsFixed(2)}€)');
          for (final sub in cat.subcategories) {
            buffer.writeln(
                '  · ${sub.name}: ${sub.monthlyBudget.toStringAsFixed(2)}€/mes${sub.isFixed ? " (fixa)" : ""}');
          }
        }
      }

      // 4. Transaccions dels últims 12 cicles
      final allTransactions =
          await _ref.read(transactionNotifierProvider.future);

      // Determinar data límit (startDate del cicle més antic dels 12)
      DateTime? cutoffDate;
      if (recentCycles.isNotEmpty) {
        cutoffDate = recentCycles.last.startDate;
      } else {
        // Fallback: 12 mesos enrere
        final now = DateTime.now();
        cutoffDate = DateTime(now.year - 1, now.month, now.day);
      }

      final recentTransactions = allTransactions
          .where((t) => t.date.isAfter(cutoffDate!))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      buffer.writeln(
          '\n=== TRANSACCIONS (${recentTransactions.length} moviments) ===');

      // Agrupar per mes per fer-ho més llegible
      final byMonth = <String, List<dynamic>>{};
      for (final tx in recentTransactions) {
        final monthKey =
            '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
        byMonth.putIfAbsent(monthKey, () => []);
        byMonth[monthKey]!.add(tx);
      }

      for (final entry in byMonth.entries) {
        buffer.writeln('\n--- ${entry.key} ---');
        for (final tx in entry.value) {
          final tipus = tx.isIncome ? 'INGRÉS' : 'DESPESA';
          buffer.writeln(
              '  ${_formatDate(tx.date)} | $tipus | ${tx.amount.toStringAsFixed(2)}€ | ${tx.categoryName} > ${tx.subCategoryName} | "${tx.concept}" | Pagador: ${tx.payer}');
        }
      }

      // 5. Resum financer actual
      final summary =
          await _ref.read(financialSummaryNotifierProvider.future);
      buffer.writeln('\n=== RESUM FINANCER CICLE ACTIU ===');
      buffer.writeln('Ingressos: ${summary.monthlyIncome.toStringAsFixed(2)}€');
      buffer.writeln(
          'Despeses: ${summary.monthlyExpenses.toStringAsFixed(2)}€');
      buffer.writeln(
          'Disponible: ${summary.availableToSpend.toStringAsFixed(2)}€');
      buffer.writeln(
          'Estalvi: ${summary.savingsPercentage.toStringAsFixed(1)}%');
    } catch (e) {
      buffer.writeln('\n[Error recollint context: $e]');
    }

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

final aiCoachProvider =
    StateNotifierProvider<AiCoachNotifier, AiCoachState>((ref) {
  return AiCoachNotifier(ref);
});
