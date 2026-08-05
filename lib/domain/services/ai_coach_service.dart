import 'package:firebase_ai/firebase_ai.dart';
import 'dart:convert';

import '../models/financial_summary.dart';
import '../models/billing_cycle.dart';
import '../models/chat_message.dart';
import 'ai_coach_config.dart';

class AiCoachService {
  /// Chat conversacional: envia una pregunta amb context financer complet.
  Future<String> askQuestion({
    required String question,
    required String financialContext,
    required List<ChatMessage> conversationHistory,
    required String userName,
  }) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: AiCoachConfig.modelName,
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
      generationConfig: GenerationConfig(
        // Els tokens interns de raonament també consumeixen aquest límit.
        // 1.024 podia deixar la resposta visible a mitges amb Gemini 3.6.
        maxOutputTokens: 4096,
        temperature: 0.3,
        thinkingConfig: ThinkingConfig.withThinkingLevel(ThinkingLevel.low),
      ),
    );

    final response = await model.generateContent(
      buildCoachConversationContents(
        conversationHistory: conversationHistory,
        question: question,
      ),
    );

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
    required int totalDays,
    required List<Map<String, dynamic>> unexpectedExpenses,
    required double savedThisCycle,
    required double withdrawnThisCycle,
    required double personalTransferIncome,
    bool isHistorical = false,
  }) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: AiCoachConfig.modelName,
      systemInstruction: Content.system('''
Ets el 'Cèntim Coach', l'assistent financer personal de $userName. Saps que estan enmig de la gran aventura de reformar una Masia del 1768 a la Floresta 🏡.

To i actitud:
Sigues directe, neutral, empàtic i concret. No renyis, però tampoc felicitis per defecte ni maquillis una situació ajustada.

Comportament davant les dades:
1. Analitza el JSON en un sol paràgraf de màxim 4 frases.
2. Comença pel resultat del cicle i digues si el marge ha estat positiu o negatiu.
3. Compara el marge total amb el marge sense Bizums/transferències de particulars. Aquesta segona xifra és una aproximació temporal, no una classificació definitiva d'ajuda familiar.
4. Valora els dies a zero com una proporció sobre els dies totals; no presentis una xifra baixa com un èxit.
5. Explica riscos i encerts amb el mateix pes i acaba amb una acció concreta.
6. Utilitza com a màxim un emoji en tota la resposta.

Regla d'Or (Última frase):
La teva última frase ha de ser SEMPRE un repte assequible i positiu que comenci exactament per: "🎯 Objectiu pel cicle vinent:".
'''),
      generationConfig: GenerationConfig(
        // Reserva prou espai per al raonament i el veredicte final complet.
        maxOutputTokens: 2048,
        temperature: 0.35,
        thinkingConfig: ThinkingConfig.withThinkingLevel(ThinkingLevel.low),
      ),
    );

    final contextJson = buildCycleVerdictContextJson(
      summary: summary,
      activeCycle: activeCycle,
      categoryExpenses: categoryExpenses,
      categoryBudgets: categoryBudgets,
      zeroExpenseDays: zeroExpenseDays,
      totalDays: totalDays,
      unexpectedExpenses: unexpectedExpenses,
      savedThisCycle: savedThisCycle,
      withdrawnThisCycle: withdrawnThisCycle,
      personalTransferIncome: personalTransferIncome,
      isHistorical: isHistorical,
    );

    final response = await model.generateContent(
        [Content.text('Analitza aquestes dades financeres:\n$contextJson')]);

    return response.text?.trim() ?? "Ho sento, m'he quedat sense paraules!";
  }

  String buildCycleVerdictContextJson({
    required FinancialSummary summary,
    required BillingCycle activeCycle,
    required Map<String, double> categoryExpenses,
    required Map<String, double> categoryBudgets,
    required int zeroExpenseDays,
    required int totalDays,
    required List<Map<String, dynamic>> unexpectedExpenses,
    required double savedThisCycle,
    required double withdrawnThisCycle,
    required double personalTransferIncome,
    required bool isHistorical,
  }) {
    // Calculate month elapsed percentage
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

    final netSaved = savedThisCycle - withdrawnThisCycle;
    final marginWithoutPersonalTransfers =
        summary.netOfCycle - personalTransferIncome;
    return jsonEncode({
      'cicle_tancat': isHistorical,
      'cicle_transcorregut_percent': monthElapsedPercentage,
      'ingressos_totals': summary.monthlyIncome,
      'ingressos_bizum_transferencies_particulars_estimats':
          personalTransferIncome,
      'ingressos_sense_bizum_transferencies_particulars':
          summary.monthlyIncome - personalTransferIncome,
      'despeses_totals': summary.monthlyExpenses,
      'marge_amb_tots_els_ingressos': summary.netOfCycle,
      'marge_sense_bizum_transferencies_particulars':
          marginWithoutPersonalTransfers,
      'tancament_positiu_depen_de_particulars':
          summary.netOfCycle >= 0 && marginWithoutPersonalTransfers < 0,
      'despeses_sobre_ingressos_percent': spentPercentage,
      'top_3_categories_desviades': top3Deviations,
      'estalvi': {
        'aportat': savedThisCycle,
        'rescatat': withdrawnThisCycle,
        'net': netSaved,
        'percentatge_net_sobre_ingressos': summary.savingsPercentage,
      },
      'masia_o_obres_moviments': masiaMoviments,
      'masia_cost_actual': masiaCost,
      'dies_totals_cicle': safeTotalDays,
      'dies_restants_cicle': safeTotalDays - elapsedDays,
      'dies_a_zero_despeses': zeroExpenseDays,
      'dies_a_zero_percent': zeroExpenseDays / safeTotalDays * 100,
      'despeses_fora_de_pressupost': unexpectedExpenses,
    });
  }
}

/// Construeix el torn conversacional una sola vegada.
///
/// El notifier passa només l'historial anterior a la pregunta actual. A més,
/// limitem la conversa als darrers 12 missatges perquè el context financer,
/// que és la font de veritat, tingui prioritat i el cost no creixi sense límit.
List<Content> buildCoachConversationContents({
  required List<ChatMessage> conversationHistory,
  required String question,
}) {
  final recentHistory = conversationHistory.length <= 12
      ? conversationHistory
      : conversationHistory.sublist(conversationHistory.length - 12);
  return [
    for (final message in recentHistory)
      if (message.isUser)
        Content.text(message.text)
      else
        Content.model([TextPart(message.text)]),
    Content.text(question.trim()),
  ];
}
