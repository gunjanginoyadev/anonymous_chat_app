const SocketEvents = require("../../config/socket_events");
const WaitingQueue = require("../../model/waiting_queue");
const ChatRoom = require("../../model/chat_room");
const { sendEvent, sendError } = require("../socket_response");

function handleEnterWaitingRoom(ws) {
  const userId = ws.userId;

  if (!userId) {
    sendError(ws, "User ID required");
    return;
  }

  if (WaitingQueue.hasUser(userId)) {
    sendError(ws, "User already in waiting room");
    return;
  }

  if (ChatRoom.hasUser(userId)) {
    sendError(ws, "User is already in an active chat");
    return;
  }

  WaitingQueue.enqueue(
    { id: userId, username: ws.username, profilePicture: ws.profilePicture },
    ws,
  );

  if (WaitingQueue.size() >= 2) {
    const user1 = WaitingQueue.dequeue();
    const user2 = WaitingQueue.dequeue();

    const chatId = ChatRoom.createChat(user1, user2);

    sendEvent(user1.socket, SocketEvents.InTheChat, {
      chatId,
      partner: {
        userId: user2.user.id,
        username: user2.user.username,
        profilePicture: user2.user.profilePicture,
      },
    });

    sendEvent(user2.socket, SocketEvents.InTheChat, {
      chatId,
      partner: {
        userId: user1.user.id,
        username: user1.user.username,
        profilePicture: user1.user.profilePicture,
      },
    });
    return;
  }

  sendEvent(ws, SocketEvents.InTheWaitingRoom, {
    message: "Waiting for partner...",
  });
}

module.exports = handleEnterWaitingRoom;
