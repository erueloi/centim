import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/financial_summary.dart';
import '../../domain/models/billing_cycle.dart';

class AiCoachService {
  final String _modelName = 'gemini-2.5-flash';

  Future<String> getInsight({
    required FinancialSummary summary,
    required BillingCycle activeCycle,
    required Map<String, double> categoryExpenses,
    required Map<String, double> categoryBudgets,
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
Ets el Cèntim Coach, un assistent financer personal, irònic però motivador, que parla en Català.
L'usuari (Eloi) està reformant una Masia del 1768 i utilitza un pressupost de base zero.

La teva missió: Analitzar el JSON de dades financeres que rebràs i generar un consell d'un sol paràgraf (màxim 3 frases).
Saps si el JSON parla del mes en curs o d'un mes ja tancat segons el paràmetre "mes_tancat". Si està tancat, fes valoracions sobre com ha anat.

Regles de to:
- Sigues directe. Si gasta massa en "Supermercat", digues-li clarament.
- Si ha estalviat o no ha tocat el pressupost de "Oci", felicita'l.
- Fes bromes subtils sobre "la ruïna de la Masia" si veus molta despesa en reformes.
- Fes servir emojis amb moderació.

Exemple de sortida desitjada:
"Eloi, portem mig mes i ja t'has polit el 80% del pressupost de Supermercat... toca menjar arròs la resta de setmana! 🍚 Per sort, la Masia avança a bon ritme. Vigila amb les despeses formiga o no arribarem a l'objectiu d'estalvi!"
'''),
    );

    final contextJson = _prepareContextJson(
      summary: summary,
      activeCycle: activeCycle,
      categoryExpenses: categoryExpenses,
      categoryBudgets: categoryBudgets,
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
  "dies_restants_cicle": ${safeTotalDays - elapsedDays}
}
''';
  }
}
