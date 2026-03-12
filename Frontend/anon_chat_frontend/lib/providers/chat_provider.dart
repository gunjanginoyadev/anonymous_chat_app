import 'package:flutter/material.dart';
import '../services/chat_websocket_service.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/endpoints.dart';

enum ChatStatus { idle, waiting, chatting }

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}

class ChatProvider extends ChangeNotifier {
  final ChatWebSocketService _wsService = ChatWebSocketService();

  ChatStatus status = ChatStatus.idle;
  List<ChatMessage> messages = [];
  String? chatId;
  String? username;
  String? errorMessage;

  // Change this to your server URL
  static const String wsUrl = 'ws://192.168.1.40:3000';

  void startChat(String token) {
    print('Starting Chat flow...');
    status = ChatStatus.waiting;
    messages = [];
    chatId = null;
    username = null;
    errorMessage = null;
    notifyListeners();  

    _wsService.onMessage = _handleMessage;
    _wsService.connect(ApiConstants.wsUrl, token);

    // Initial event to enter waiting room
    _wsService.emit(Endpoints.enterWaitingRoom, {});
  }

  void _handleMessage(Map<String, dynamic> message) {
    final event = message['event'] as String?;
    final data = message['data'] as Map<String, dynamic>? ?? {};

    switch (event) {
      case Endpoints.inWaitingRoom:
        status = ChatStatus.waiting;
        notifyListeners();
        break;

      case Endpoints.inChat:
        chatId = data['chatId'] as String?;
        username = data['partner']['username'] as String?;
        status = ChatStatus.chatting;
        notifyListeners();
        break;

      case Endpoints.sendMessage:
        // This is usually the echo back to the sender
        _addMessage(data['message'] as String? ?? '', true);
        break;

      case Endpoints.messageReceived:
        _addMessage(data['message'] as String? ?? '', false);
        break;

      case Endpoints.error:
        errorMessage = data['message'] as String? ?? 'An error occurred';
        notifyListeners();
        break;

      case 'connection_closed':
        if (status != ChatStatus.idle) {
          _addMessage('🔌 Disconnected from chat', false);
          status = ChatStatus.idle;
          notifyListeners();
        }
        break;
    }
  }

  void _addMessage(String text, bool isMe) {
    messages.add(
      ChatMessage(text: text, isMe: isMe, timestamp: DateTime.now()),
    );
    notifyListeners();
  }

  void sendMessage(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || chatId == null) return;

    _wsService.emit(Endpoints.sendMessage, {'chatId': chatId, 'message': trimmedText});
  }

  void leaveChat() {
    _wsService.leave();
    status = ChatStatus.idle;
    messages = [];
    chatId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _wsService.disconnect();
    super.dispose();
  }
}
