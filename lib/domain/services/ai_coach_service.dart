import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/financial_summary.dart';
import '../../domain/models/billing_cycle.dart';

class AiCoachService {
  final String _modelName = 'gemini-2.5-flash';

  Future<String> getInsight({
    required String userName,
    required FinancialSummary summary,
    required BillingCycle activeCycle,
    required Map<String, double> categoryExpenses,
    required Map<String, double> categoryBudgets,
    required int zeroExpenseDays,
    required List<Map<String, dynamic>> unexpectedExpenses,
    bool isHistorical = false,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'posa_la_teva_clau_aqui') {
      throw Exception(
          'API Key no configurada. Si us plau, afegeix-la al fitxer .env.');
    }

    final model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      systemInstruction: Content.system('''
Ets el 'Cèntim Coach', l'assistent financer personal de l'Eloi i el Jose. Saps que estan enmig de la gran aventura de reformar una Masia del 1768 a la Floresta 🏡.

To i Actitud: 
El teu to ha de ser assertiu, super empàtic, motivador, còmplice i divertit. Tens totalment prohibit fer-los sentir culpables, renyar-los de forma agressiva o fer-los posar tristos.

Comportament davant les dades:
1. Analitza el JSON de dades financeres (un sol paràgraf de màxim 3-4 frases).
2. Celebra efusivament els encerts i els "Dies a Zero" 🎉.
3. Si hi ha imprevistos o desviacions (especialment amb la Masia), treu-hi ferro amb humor compassiu (és normal que una casa del 1768 tingui sorpreses amagades! 🏚️✨), però dona'ls un consell assertiu i pràctic per intentar preveure-ho millor.
4. Fes servir emojis per donar calidesa al text.

Regla d'Or (Última frase):
La teva última frase ha de ser SEMPRE un repte assequible i positiu que comenci exactament per: "🎯 Objectiu pel cicle vinent:".
'''),
    );

    final contextJson = _prepareContextJson(
      summary: summary,
      activeCycle: activeCycle,
      categoryExpenses: categoryExpenses,
      categoryBudgets: categoryBudgets,
      zeroExpenseDays: zeroExpenseDays,
      unexpectedExpenses: unexpectedExpenses,
      isHistorical: isHistorical,
    );

    final response = await model.generateContent(
        [Content.text('Analitza aquestes dades financeres:\n$contextJson')]);

    return response.text?.trim() ?? "Ho sento, m'he quedat sense paraules!";
  }

  String _prepareContextJson({
    required FinancialSummary summary,
    required BillingCycle activeCycle,
    required Map<String, double> categoryExpenses,
    required Map<String, double> categoryBudgets,
    required int zeroExpenseDays,
    required List<Map<String, dynamic>> unexpectedExpenses,
    required bool isHistorical,
  }) {
    // Calculate month elapsed percentage
    final totalDays =
        activeCycle.endDate.difference(activeCycle.startDate).inDays;
    // Prevent division by zero if start and end are the same day
    final safeTotalDays = totalDays > 0 ? totalDays : 1;

    int monthElapsedPercentage = 100;
    int elapsedDays = safeTotalDays;

    if (!isHistorical) {
      final now = DateTime.now();
      elapsedDays =
          now.difference(activeCycle.startDate).inDays.clamp(0, safeTotalDays);
      monthElapsedPercentage = (elapsedDays / safeTotalDays * 100).round();
    }

    // Calculate total budget spent percentage
    final totalIncome = summary.monthlyIncome;
    final totalSpent = summary.monthlyExpenses;
    final spentPercentage =
        totalIncome > 0 ? ((totalSpent / totalIncome) * 100).round() : 0;

    // Calculate deviations and top 3
    final deviations = <String, double>{};
    for (final category in categoryExpenses.keys) {
      final spent = categoryExpenses[category] ?? 0.0;
      final budget = categoryBudgets[category] ?? 0.0;

      // Calculate deviation. E.g. spent 150, budget 100 -> deviation is +50
      if (budget > 0) {
        deviations[category] = spent - budget;
      }
    }

    // Sort by largest deviation (overspending)
    final sortedCategories = deviations.keys.toList()
      ..sort((a, b) => (deviations[b]!).compareTo(deviations[a]!));

    final top3Deviations = sortedCategories.take(3).map((c) {
      return {
        'categoria': c,
        'despesa': categoryExpenses[c],
        'pressupost': categoryBudgets[c],
        'desviacio': deviations[c]
      };
    }).toList();

    // Check masia/obres
    bool masiaMoviments = false;
    double masiaCost = 0.0;
    for (final cat in categoryExpenses.keys) {
      final upperCat = cat.toUpperCase();
      if (upperCat.contains('MASIA') ||
          upperCat.contains('OBRES') ||
          upperCat.contains('REFORMA')) {
        masiaMoviments = true;
        masiaCost += categoryExpenses[cat] ?? 0.0;
      }
    }

    // Savings status
    final savingsStatus = {
      'estalvi_previst': summary
          .availableToSpend, // In zero-based, availableToSpend should ideally be 0, but if positive means we could save more
      'percentatge_estalvi_actual': summary.savingsPercentage.round(),
    };

    return '''
{
  "mes_tancat": $isHistorical,
  "mes_transcorregut_percent": $monthElapsedPercentage,
  "pressupost_total_gastat_percent": $spentPercentage,
  "top_3_categories_desviades": ${top3Deviations.toString()},
  "estat_estalvi": ${savingsStatus.toString()},
  "masia_o_obres_moviments": $masiaMoviments,
  "masia_cost_actual": $masiaCost,
  "dies_restants_cicle": ${safeTotalDays - elapsedDays},
  "dies_a_zero_despeses": $zeroExpenseDays,
  "compres_imprevistes_sense_pressupost": ${unexpectedExpenses.toString()}
}
''';
  }
}
