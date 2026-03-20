class Endpoints {
  // Auth Endpoints
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String refreshToken = '/api/auth/refresh-token';
  
  // Chat Sockets Events (For reference if needed, though they are emitted events)
  static const String enterWaitingRoom = 'enter-waiting-room';
  static const String inWaitingRoom = 'in-waiting-room';
  static const String inChat = 'in-chat';
  static const String sendMessage = 'send-message';
  static const String messageReceived = 'message-received';
  static const String toggleReaction = 'toggle-reaction';
  static const String messageReactionUpdated = 'message-reaction-updated';
  static const String partnerLeft = 'partner-left';
  static const String error = 'error';
  static const String typing = 'typing';
}
