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
  String? partnerUsername;
  String? errorMessage;

  /// The username of the connected partner (exposed for UI).
  String? get username => partnerUsername;

  void startChat(String token) {
    print('Starting Chat flow...');
    status = ChatStatus.waiting;
    messages = [];
    chatId = null;
    partnerUsername = null;
    errorMessage = null;
    notifyListeners();

    _wsService.onMessage = _handleMessage;

    // Only emit enter-waiting-room AFTER the socket connection is established.
    _wsService.onReady = () {
      print('Socket ready — emitting enter-waiting-room');
      _wsService.emit(Endpoints.enterWaitingRoom, {});
    };

    _wsService.connect(ApiConstants.wsUrl, token);
  }

  void _handleMessage(Map<String, dynamic> message) {
    final event = message['event'] as String?;
    final data = message['data'] as Map<String, dynamic>? ?? {};

    switch (event) {
      case Endpoints.inWaitingRoom:
        // Already set to waiting — no change needed, but refresh just in case.
        status = ChatStatus.waiting;
        notifyListeners();
        break;

      case Endpoints.inChat:
        chatId = data['chatId'] as String?;
        partnerUsername = data['partner']?['username'] as String?;
        status = ChatStatus.chatting;
        notifyListeners();
        break;

      // The backend echoes the sender's own message back with event 'send-message'.
      // We do NOT add it here because the sender already added it optimistically
      // in sendMessage(). Handling it would cause duplicates.
      // case Endpoints.sendMessage: intentionally omitted.

      case Endpoints.messageReceived:
        // This is the event the RECEIVER gets when the sender sends a message.
        _addMessage(data['message'] as String? ?? '', false);
        break;

      case Endpoints.partnerLeft:
        _addMessage('🔌 Partner disconnected', false);
        // Give the user a moment to read it, then return to home.
        Future.delayed(const Duration(seconds: 2), () {
          status = ChatStatus.idle;
          messages = [];
          chatId = null;
          partnerUsername = null;
          notifyListeners();
        });
        break;

      case Endpoints.error:
        errorMessage = (message['message'] as String?) ??
            (data['message'] as String?) ??
            'An error occurred';
        notifyListeners();
        break;

      case 'connection_closed':
        if (status != ChatStatus.idle) {
          status = ChatStatus.idle;
          messages = [];
          chatId = null;
          partnerUsername = null;
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

    // Optimistically add to local list so the sender sees it immediately.
    _addMessage(trimmedText, true);

    // Send to server — the backend will forward to the receiver.
    _wsService.emit(Endpoints.sendMessage, {
      'chatId': chatId,
      'message': trimmedText,
    });
  }

  void leaveChat() {
    _wsService.leave();
    status = ChatStatus.idle;
    messages = [];
    chatId = null;
    partnerUsername = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _wsService.disconnect();
    super.dispose();
  }
}
