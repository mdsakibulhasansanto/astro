enum ChatRole { user, assistant }

/// One message in the AI chat.
class ChatMessageModel {
  const ChatMessageModel({required this.role, required this.text, this.failed = false});

  final ChatRole role;
  final String text;

  /// A user message whose reply could not be fetched.
  final bool failed;

  Map<String, dynamic> toJson() => {'role': role.name, 'content': text};
}
