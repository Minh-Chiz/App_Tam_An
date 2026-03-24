import 'package:flutter/material.dart';
import 'package:tam_an/services/ai_service.dart';

class AICompanionProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  final AIService _aiService = AIService();

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;

  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void setTyping(bool typing) {
    _isTyping = typing;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    // Add user message
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    addMessage(userMessage);

    // Show typing indicator
    setTyping(true);

    try {
      // Get AI response using Gemini
      final aiResponse = await _aiService.chat(text);

      // Add AI response
      final aiMessage = ChatMessage(
        text: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );
      addMessage(aiMessage);
    } catch (e) {
      // Fallback to simple response on error
      final aiMessage = ChatMessage(
        text: 'Xin lỗi, tôi đang gặp sự cố. Bạn có thể thử lại không?',
        isUser: false,
        timestamp: DateTime.now(),
      );
      addMessage(aiMessage);
    }

    setTyping(false);
  }

  Future<void> getGuidedQuestion(String emotion) async {
    setTyping(true);
    
    try {
      final question = await _aiService.getGuidedQuestion(emotion);
      final aiMessage = ChatMessage(
        text: question,
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.suggestion,
      );
      addMessage(aiMessage);
    } catch (e) {
      final aiMessage = ChatMessage(
        text: 'Bạn muốn chia sẻ gì về cảm xúc này?',
        isUser: false,
        timestamp: DateTime.now(),
      );
      addMessage(aiMessage);
    }
    
    setTyping(false);
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
  });
}

enum MessageType {
  text,
  suggestion,
  exercise,
  affirmation,
}
