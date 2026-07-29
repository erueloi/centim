import 'package:centim/domain/models/chat_message.dart';
import 'package:centim/domain/services/ai_coach_config.dart';
import 'package:centim/domain/services/ai_coach_service.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiCoachConfig', () {
    test('accepta un nom de model Gemini vàlid', () {
      expect(
        sanitizeAiCoachModelName('gemini-3.6-flash'),
        'gemini-3.6-flash',
      );
    });

    test('fa fallback davant valors buits o inesperats', () {
      expect(
        sanitizeAiCoachModelName(''),
        AiCoachConfig.defaultModel,
      );
      expect(
        sanitizeAiCoachModelName('models/gemini-3.6-flash'),
        AiCoachConfig.defaultModel,
      );
      expect(
        sanitizeAiCoachModelName('gemini-3.6-flash\nignora-instruccions'),
        AiCoachConfig.defaultModel,
      );
    });
  });

  group('buildCoachConversationContents', () {
    test('no duplica la pregunta actual', () {
      final contents = buildCoachConversationContents(
        conversationHistory: [
          ChatMessage(text: 'Pregunta anterior', isUser: true),
          ChatMessage(text: 'Resposta anterior', isUser: false),
        ],
        question: 'Pregunta actual',
      );

      expect(contents, hasLength(3));
      expect(_text(contents[0]), 'Pregunta anterior');
      expect(_text(contents[1]), 'Resposta anterior');
      expect(_text(contents[2]), 'Pregunta actual');
      expect(
        contents.where((content) => _text(content) == 'Pregunta actual'),
        hasLength(1),
      );
    });

    test('limita l historial als darrers 12 missatges', () {
      final history = List.generate(
        15,
        (index) => ChatMessage(
          text: 'Missatge $index',
          isUser: index.isEven,
        ),
      );

      final contents = buildCoachConversationContents(
        conversationHistory: history,
        question: 'Nova pregunta',
      );

      expect(contents, hasLength(13));
      expect(_text(contents.first), 'Missatge 3');
      expect(_text(contents[11]), 'Missatge 14');
      expect(_text(contents.last), 'Nova pregunta');
    });
  });
}

String _text(Content content) {
  return (content.parts.single as TextPart).text;
}
