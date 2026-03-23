class Endpoints {
  // Auth Endpoints
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String refreshToken = '/api/auth/refresh-token';
  static const String verifyEmail = '/api/auth/email/verify';
  static const String resendVerificationEmail = '/api/auth/email/resend-verification';
  static const String forgetPassword = '/api/auth/forget-password';
  static const String verifyResetToken = '/api/auth/forget-password/verify';
  static const String changePassword = '/api/auth/change-password';

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
