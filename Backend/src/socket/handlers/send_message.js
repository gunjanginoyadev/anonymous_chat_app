const SocketEvents = require("../../config/socket_events");
const ChatRoom = require("../../model/chat_room");
const { sendEvent, sendError } = require("../socket_response");

function handleSendMessage(ws, data) {
  const { chatId, message } = data || {};
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

  sendEvent(sender.socket, SocketEvents.SendMessage, { chatId, message });
  sendEvent(receiver.socket, SocketEvents.MessageReceived, { chatId, message });
}

module.exports = handleSendMessage;
