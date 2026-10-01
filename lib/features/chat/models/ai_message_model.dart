class AiMessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  AiMessageModel({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, String> toApiMap() {
    return {'role': isUser ? 'user' : 'assistant', 'content': text};
  }
}
