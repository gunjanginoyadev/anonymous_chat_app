import 'package:flutter/material.dart';
import '../core/router/router_refresh_notifier.dart';
import '../services/chat_websocket_service.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/endpoints.dart';

enum ChatStatus { idle, waiting, chatting }

class ChatMessage {
  final String id;
  final String text;
  final String? senderId;
  final bool isMe;
  final DateTime timestamp;
  final Map<String, Set<String>> reactions;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.isMe,
    required this.timestamp,
    Map<String, Set<String>>? reactions,
  }) : reactions = reactions ?? {};
}

Map<String, Set<String>> _parseReactions(dynamic raw) {
  final parsed = <String, Set<String>>{};
  if (raw is! Map) return parsed;

  raw.forEach((key, value) {
    if (key is! String || value is! List) return;
    parsed[key] = value.map((e) => e.toString()).toSet();
  });
  return parsed;
}

class ChatProvider extends ChangeNotifier {
  ChatProvider({RouterRefreshNotifier? routerRefresh})
      : _routerRefresh = routerRefresh;

  final ChatWebSocketService _wsService = ChatWebSocketService();
  final RouterRefreshNotifier? _routerRefresh;

  void _notify() {
    notifyListeners();
    _routerRefresh?.refresh();
  }

  ChatStatus status = ChatStatus.idle;
  List<ChatMessage> messages = [];
  String? chatId;
  String? partnerUsername;
  String? partnerProfilePicture;
  String? errorMessage;
  bool partnerIsTyping = false;

  /// The username of the connected partner (exposed for UI).
  String? get username => partnerUsername;

  void startChat(String token) {
    if (token.trim().isEmpty) {
      errorMessage = 'Missing auth token. Please login again.';
      _notify();
      return;
    }
    print('Starting Chat flow...');
    status = ChatStatus.waiting;
    messages = [];
    chatId = null;
    partnerUsername = null;
    partnerProfilePicture = null;
    partnerIsTyping = false;
    errorMessage = null;
    _notify();

    _wsService.onMessage = _handleMessage;

    // Only emit enter-waiting-room AFTER the socket connection is established.
    _wsService.onReady = () {
      print('Socket ready — emitting enter-waiting-room');
      _wsService.emit(Endpoints.enterWaitingRoom, {});
    };

    _wsService.connect(ApiConstants.wsUrl, token);
  }

  void _handleMessage(Map<String, dynamic> message) {
    final event = (message['event'] ?? message['type']) as String?;
    final data = message['data'] as Map<String, dynamic>? ?? {};
    final eventName = event?.toString().trim().toLowerCase();

    switch (eventName) {
      case Endpoints.inWaitingRoom:
        status = ChatStatus.waiting;
        _notify();
        break;

      case Endpoints.inChat:
        chatId = data['chatId'] as String?;
        final partner = data['partner'] as Map<String, dynamic>?;
        partnerUsername = partner?['username'] as String?;
        partnerProfilePicture = partner?['profilePicture'] as String?;
        status = ChatStatus.chatting;
        _notify();
        break;

      // The backend echoes the sender's own message back with event 'send-message'.
      // We do NOT add it here because the sender already added it optimistically
      // in sendMessage(). Handling it would cause duplicates.
      // case Endpoints.sendMessage: intentionally omitted.

      case Endpoints.messageReceived:
        _upsertMessageFromPayload(data, isMe: false);
        break;
      case Endpoints.sendMessage:
        _upsertMessageFromPayload(data, isMe: true);
        break;

      case Endpoints.messageReactionUpdated:
        _applyReactionUpdate(data);
        break;

      case Endpoints.partnerLeft:
        _addMessage('🔌 Partner disconnected', false);
        Future.delayed(const Duration(seconds: 2), () {
          status = ChatStatus.idle;
          messages = [];
          chatId = null;
          partnerUsername = null;
          partnerProfilePicture = null;
          partnerIsTyping = false;
          _notify();
        });
        break;

      case Endpoints.error:
        errorMessage = (message['message'] as String?) ??
            (data['message'] as String?) ??
            'An error occurred';
        _notify();
        break;

      case 'connection_closed':
        if (status != ChatStatus.idle) {
          status = ChatStatus.idle;
          messages = [];
          chatId = null;
          partnerUsername = null;
          partnerProfilePicture = null;
          partnerIsTyping = false;
          _notify();
        }
        break;

      case Endpoints.typing: {
        final payloadChatId =
            (data['chatId'] ?? message['chatId'])?.toString();
        final isTyping = data['isTyping'] == true ||
            message['isTyping'] == true;
        if (payloadChatId != null &&
            chatId != null &&
            payloadChatId == chatId) {
          partnerIsTyping = isTyping;
          _notify();
        }
        break;
      }
    }
  }

  /// Notify the server that the user is typing or stopped typing.
  void setTyping(bool typing) {
    if (chatId == null) return;
    _wsService.emit(Endpoints.typing, {
      'chatId': chatId,
      'isTyping': typing,
    });
  }

  void _upsertMessageFromPayload(Map<String, dynamic> data, {required bool isMe}) {
    final messageId = data['messageId']?.toString();
    final text = data['message']?.toString() ?? '';
    if (text.trim().isEmpty) return;

    // Backward compatibility: if backend payload does not include messageId yet,
    // still show the message instead of dropping it.
    if (messageId == null || messageId.isEmpty) {
      _addMessage(text, isMe);
      return;
    }

    final existingIndex = messages.indexWhere((m) => m.id == messageId);
    final senderId = data['senderId']?.toString();
    final timestampRaw = data['timestamp'];
    final timestamp = timestampRaw is int
        ? DateTime.fromMillisecondsSinceEpoch(timestampRaw)
        : DateTime.now();

    final newMessage = ChatMessage(
      id: messageId,
      text: text,
      senderId: senderId,
      isMe: isMe,
      timestamp: timestamp,
      reactions: _parseReactions(data['reactions']),
    );

    if (existingIndex >= 0) {
      messages[existingIndex] = newMessage;
    } else {
      messages.add(newMessage);
    }
    _notify();
  }

  void _addMessage(String text, bool isMe) {
    messages.add(
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: text,
        senderId: null,
        isMe: isMe,
        timestamp: DateTime.now(),
      ),
    );
    _notify();
  }

  void sendMessage(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || chatId == null) return;

    _wsService.emit(Endpoints.sendMessage, {
      'chatId': chatId,
      'message': trimmedText,
    });
  }

  void toggleReaction(String messageId, String emoji) {
    if (chatId == null || messageId.isEmpty || emoji.trim().isEmpty) return;
    _wsService.emit(Endpoints.toggleReaction, {
      'chatId': chatId,
      'messageId': messageId,
      'emoji': emoji,
    });
  }

  void _applyReactionUpdate(Map<String, dynamic> data) {
    final messageId = data['messageId']?.toString();
    if (messageId == null) return;
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index < 0) return;

    final existing = messages[index];
    final reactions = _parseReactions(data['reactions']);

    messages[index] = ChatMessage(
      id: existing.id,
      text: existing.text,
      senderId: existing.senderId,
      isMe: existing.isMe,
      timestamp: existing.timestamp,
      reactions: reactions,
    );
    _notify();
  }

  void leaveChat() {
    _wsService.leave();
    status = ChatStatus.idle;
    messages = [];
    chatId = null;
    partnerUsername = null;
    partnerProfilePicture = null;
    partnerIsTyping = false;
    _notify();
  }

  void clearError() {
    errorMessage = null;
    _notify();
  }

  @override
  void dispose() {
    _wsService.disconnect();
    super.dispose();
  }
}
