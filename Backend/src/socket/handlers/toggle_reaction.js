const SocketEvents = require("../../config/socket_events");
const ChatRoom = require("../../model/chat_room");
const { sendEvent, sendError } = require("../socket_response");

function handleToggleReaction(ws, data) {
  const { chatId, messageId, emoji } = data || {};
  const userId = ws.userId;

  if (!userId) {
    sendError(ws, "Unauthorized socket");
    return;
  }

  const chat = ChatRoom.getChat(chatId);
  if (!chat) {
    sendError(ws, "Invalid chatId");
    return;
  }

  const isUser1 = chat.user1.user.id.toString() === userId.toString();
  const sender = isUser1 ? chat.user1 : chat.user2;
  const receiver = isUser1 ? chat.user2 : chat.user1;
  if (!sender || !receiver) return;

  const update = ChatRoom.toggleReaction(chatId, messageId, userId, emoji);
  if (!update) {
    sendError(ws, "Invalid messageId");
    return;
  }

  const payload = {
    chatId,
    messageId: update.messageId,
    emoji: update.emoji,
    userId: update.userId,
    action: update.action,
    reactions: update.reactions,
  };

  sendEvent(sender.socket, SocketEvents.MessageReactionUpdated, payload);
  sendEvent(receiver.socket, SocketEvents.MessageReactionUpdated, payload);
}

module.exports = handleToggleReaction;
