const SocketEvents = require("../../config/socket_events");
const ChatRoom = require("../../model/chat_room");
const { sendEvent, sendError } = require("../socket_response");

function handleTyping(ws, data) {
  const { chatId, isTyping } = data || {};
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
  const receiver = isUser1 ? chat.user2 : chat.user1;
  if (!receiver) return;

  sendEvent(receiver.socket, SocketEvents.Typing, {
    chatId,
    isTyping: Boolean(isTyping),
  });
}

module.exports = handleTyping;
