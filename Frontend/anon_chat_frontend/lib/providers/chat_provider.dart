import 'package:flutter/foundation.dart';
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
    final k = key?.toString();
    if (k == null || k.isEmpty) return;

    if (value is List) {
      final set = value.map((e) => e.toString()).toSet();
      if (set.isNotEmpty) parsed[k] = set;
    } else if (value is String) {
      if (value.isNotEmpty) parsed[k] = {value};
    } else if (value != null) {
      parsed[k] = {value.toString()};
    }
  });
  return parsed;
}

/// Merge server [emoji] / [userId] / [action] when full reactions map is missing.
Map<String, Set<String>> _mergeReactionDelta(
  Map<String, Set<String>> existing, {
  required String? emoji,
  required String? userId,
  required String? action,
}) {
  final next = <String, Set<String>>{};
  for (final e in existing.entries) {
    next[e.key] = Set<String>.from(e.value);
  }
  final em = emoji?.trim();
  final uid = userId?.trim();
  if (em == null || em.isEmpty || uid == null || uid.isEmpty) return next;

  final set = Set<String>.from(next[em] ?? {});
  if (action == 'removed') {
    set.remove(uid);
    if (set.isEmpty) {
      next.remove(em);
    } else {
      next[em] = set;
    }
  } else {
    // Default: treat as added (matches server toggle_reaction.js)
    set.add(uid);
    next[em] = set;
  }
  return next;
}

Map<String, dynamic> _asStringKeyedMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return Map<String, dynamic>.from(
      raw.map((k, v) => MapEntry(k.toString(), v)),
    );
  }
  return <String, dynamic>{};
}

/// Debug: copy/paste lines starting with `[Reaction]` when reporting issues.
void _reactionLog(String message) {
  debugPrint('[Reaction] $message');
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
    final data = _asStringKeyedMap(message['data']);
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

      // Sender gets 'send-message' (no local optimistic row); partner gets 'message-received'.
      // Both upsert by server messageId so reactions use the same id.

      case Endpoints.messageReceived:
        _upsertMessageFromPayload(data, isMe: false);
        break;
      case Endpoints.sendMessage:
        _upsertMessageFromPayload(data, isMe: true);
        break;

      case Endpoints.messageReactionUpdated:
      case 'messagereactionupdated': // alias if server strips hyphens
        _reactionLog(
          'WS received message-reaction-updated: rawEvent=$event '
          'dataKeys=${data.keys.toList()} data=$data',
        );
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
        _reactionLog(
          'WS error event: message="$errorMessage" full=$message',
        );
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

  void toggleReaction(
    String messageId,
    String emoji, {
    String? currentUserId,
  }) {
    final mid = messageId.trim();
    final em = emoji.trim();
    if (chatId == null) {
      _reactionLog('toggleReaction ABORT: chatId is null');
      return;
    }
    if (mid.isEmpty || em.isEmpty) {
      _reactionLog(
        'toggleReaction ABORT: empty messageId or emoji '
        '(mid="$mid" em="$em")',
      );
      return;
    }

    final uid = currentUserId?.trim();
    _reactionLog(
      'toggleReaction: chatId=$chatId messageId=$mid emoji="$em" '
      'currentUserId=${uid == null || uid.isEmpty ? "(missing)" : "set(len=${uid.length})"} '
      'messageCount=${messages.length} '
      'knownIds=${messages.map((m) => m.id).take(8).toList()}',
    );

    if (uid != null && uid.isNotEmpty) {
      _optimisticToggleReaction(mid, em, uid);
    } else {
      _reactionLog(
        'toggleReaction: skipping optimistic (no user id) — '
        'waiting for server message-reaction-updated',
      );
    }

    _wsService.emit(Endpoints.toggleReaction, {
      'chatId': chatId,
      'messageId': mid,
      'emoji': em,
    });
    _reactionLog(
      'toggleReaction: emitted ${Endpoints.toggleReaction} '
      '(see WebSocket Emitting line in console)',
    );
  }

  void _optimisticToggleReaction(
    String messageId,
    String emoji,
    String userId,
  ) {
    final index = messages.indexWhere((m) => m.id.trim() == messageId.trim());
    if (index < 0) {
      _reactionLog(
        'optimistic FAIL: no message row for messageId="$messageId" '
        '(ids=${messages.map((m) => '"${m.id}"').join(", ")})',
      );
      return;
    }

    final existing = messages[index];
    final nextReactions = <String, Set<String>>{};
    for (final e in existing.reactions.entries) {
      nextReactions[e.key] = Set<String>.from(e.value);
    }

    final set = nextReactions[emoji] ?? <String>{};
    if (set.contains(userId)) {
      set.remove(userId);
      if (set.isEmpty) {
        nextReactions.remove(emoji);
      } else {
        nextReactions[emoji] = set;
      }
    } else {
      nextReactions[emoji] = {...set, userId};
    }

    messages[index] = ChatMessage(
      id: existing.id,
      text: existing.text,
      senderId: existing.senderId,
      isMe: existing.isMe,
      timestamp: existing.timestamp,
      reactions: nextReactions,
    );
    _reactionLog(
      'optimistic OK: index=$index nextReactions=${nextReactions.entries.map((e) => '${e.key}:${e.value.length}').join(", ")}',
    );
    _notify();
  }

  void _applyReactionUpdate(Map<String, dynamic> data) {
    final messageId = data['messageId']?.toString().trim();
    if (messageId == null || messageId.isEmpty) {
      _reactionLog('applyReactionUpdate ABORT: missing messageId');
      return;
    }
    final index = messages.indexWhere((m) => m.id.trim() == messageId);
    if (index < 0) {
      _reactionLog(
        'applyReactionUpdate FAIL: no local message for messageId="$messageId" '
        'localIds=${messages.map((m) => m.id).take(12).toList()}',
      );
      return;
    }

    final existing = messages[index];
    final rawReactions = data['reactions'];
    _reactionLog(
      'applyReactionUpdate: messageId=$messageId rawReactionsType=${rawReactions.runtimeType} '
      'rawReactions=$rawReactions',
    );
    Map<String, Set<String>> reactions;

    if (rawReactions is Map && rawReactions.isNotEmpty) {
      reactions = _parseReactions(rawReactions);
      // If shape was unexpected, fall back to emoji / userId / action from the server.
      if (reactions.isEmpty) {
        reactions = _mergeReactionDelta(
          existing.reactions,
          emoji: data['emoji']?.toString(),
          userId: data['userId']?.toString(),
          action: data['action']?.toString(),
        );
      }
    } else if (rawReactions is Map && rawReactions.isEmpty) {
      reactions = {};
    } else {
      // Server sent emoji/action/userId but reactions missing or wrong shape — merge.
      reactions = _mergeReactionDelta(
        existing.reactions,
        emoji: data['emoji']?.toString(),
        userId: data['userId']?.toString(),
        action: data['action']?.toString(),
      );
    }

    messages[index] = ChatMessage(
      id: existing.id,
      text: existing.text,
      senderId: existing.senderId,
      isMe: existing.isMe,
      timestamp: existing.timestamp,
      reactions: reactions,
    );
    _reactionLog(
      'applyReactionUpdate OK: reactions=${reactions.entries.map((e) => '${e.key}:${e.value.length}').join(", ")}',
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
