import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/financial_summary.dart';
import '../models/billing_cycle.dart';
import '../models/chat_message.dart';

class AiCoachService {
  final String _modelName = 'gemini-2.5-flash';

  /// Chat conversacional: envia una pregunta amb context financer complet.
  Future<String> askQuestion({
    required String question,
    required String financialContext,
    required List<ChatMessage> conversationHistory,
    required String userName,
  }) async {
    final apiKey = _getApiKey();

    final model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      systemInstruction: Content.system('''
Ets el 'Cèntim Coach', l'assistent financer personal de $userName. Ets un expert analitzant dades financeres personals.

CONTEXT FINANCER (dades reals de l'usuari):
$financialContext

INSTRUCCIONS:
1. Respon SEMPRE en Català.
2. Basa les teves respostes EXCLUSIVAMENT en les dades del context financer proporcionat. Si no tens dades suficients per respondre, digues-ho clarament.
3. Quan l'usuari pregunta per una categoria o concepte, busca a les transaccions per nom de categoria, subcategoria o concepte (cerca parcial, case-insensitive).
4. Quan l'usuari pregunta per un mes, filtra les transaccions pel rang de dates dels cicles de facturació corresponents.
5. Respon de forma concisa i directa. Utilitza emojis per fer-ho acollidor.
6. Si dones xifres, arrodoneix a 2 decimals i afegeix el símbol €.
7. Si l'usuari no especifica un mes concret i pregunta sobre hàbits, fes una mitjana dels cicles disponibles.
8. El to ha de ser empàtic, motivador i còmplice. Mai renyis per gastar massa.
'''),
    );

    // Construir historial de conversa per a Gemini
    final contents = <Content>[];
    for (final msg in conversationHistory) {
      if (msg.isUser) {
        contents.add(Content.text(msg.text));
      } else {
        contents.add(Content.model([TextPart(msg.text)]));
      }
    }
    // Afegir la pregunta actual
    contents.add(Content.text(question));

    final response = await model.generateContent(contents);

    return response.text?.trim() ??
        "Ho sento, no he pogut processar la teva pregunta. Prova-ho de nou! 🤔";
  }

  /// Genera el veredicte IA per a un informe de cicle tancat.
  /// Manté el comportament original dels CycleReports.
  Future<String> generateCycleVerdict({
    required String userName,
    required FinancialSummary summary,
    required BillingCycle activeCycle,
    required Map<String, double> categoryExpenses,
    required Map<String, double> categoryBudgets,
    required int zeroExpenseDays,
    required List<Map<String, dynamic>> unexpectedExpenses,
    bool isHistorical = false,
  }) async {
    final apiKey = _getApiKey();

    final model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      systemInstruction: Content.system('''
Ets el 'Cèntim Coach', l'assistent financer personal de $userName. Saps que estan enmig de la gran aventura de reformar una Masia del 1768 a la Floresta 🏡.

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

    final contextJson = _prepareCycleContextJson(
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

  String _getApiKey() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'posa_la_teva_clau_aqui') {
      throw Exception(
          'API Key no configurada. Si us plau, afegeix-la al fitxer .env.');
    }
    return apiKey;
  }

  String _prepareCycleContextJson({
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

      if (budget > 0) {
        deviations[category] = spent - budget;
      }
    }

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
      'estalvi_previst': summary.availableToSpend,
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
