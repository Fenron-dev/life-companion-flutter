enum MessageRole { user, ai }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final int timestamp;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });
}
