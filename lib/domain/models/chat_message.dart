/// Model senzill per a missatges del chat del coach.
/// No es persisteix ni es serialitza — viu només en memòria.
class ChatMessage {
  final String text;
  final bool isUser; // true = usuari, false = IA
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
