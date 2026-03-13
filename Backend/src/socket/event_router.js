// sockets/event_router.js

const SocketEvents = require("../config/socket_events");
const WaitingQueue = require("../model/waiting_queue");
const ChatRoom = require("../model/chat_room");

function eventRouter(ws, message) {
  let body;

  try {
    body = JSON.parse(message);
  } catch {
    return ws.send(
      JSON.stringify({
        event: SocketEvents.Error,
        message: "Invalid JSON",
      }),
    );
  }

  switch (body.event) {
    // ===============================
    // ENTER WAITING ROOM
    // ===============================
    case SocketEvents.EnterWaitingRoom: {
      const userId = ws.userId;

      if (!userId) {
        return ws.send(
          JSON.stringify({
            event: SocketEvents.Error,
            message: "User ID required",
          }),
        );
      }

      if (WaitingQueue.hasUser(userId)) {
        return ws.send(
          JSON.stringify({
            event: SocketEvents.Error,
            message: "User already in waiting room",
          }),
        );
      }

      WaitingQueue.enqueue({ id: userId, username: ws.username, profilePicture: ws.profilePicture }, ws);

      if (WaitingQueue.size() >= 2) {
        const user1 = WaitingQueue.dequeue();
        const user2 = WaitingQueue.dequeue();

        const chatId = ChatRoom.createChat(user1, user2);

        const payload1 = JSON.stringify({
          event: SocketEvents.InTheChat,
          data: {
            chatId,
            partner: {
              userId: user2.user.id,
              username: user2.user.username,
              profilePicture: user2.user.profilePicture,
            },
          },
        });

        const payload2 = JSON.stringify({
          event: SocketEvents.InTheChat,
          data: {
            chatId,
            partner: {
              userId: user1.user.id,
              username: user1.user.username,
              profilePicture: user1.user.profilePicture,
            },
          },
        });

        if (user1.socket.readyState === 1) {
          user1.socket.send(payload1);
        }

        if (user2.socket.readyState === 1) {
          user2.socket.send(payload2);
        }
      } else {
        ws.send(
          JSON.stringify({
            event: SocketEvents.InTheWaitingRoom,
            message: "Waiting for partner...",
          }),
        );
      }

      break;
    }

    // ===============================
    // SEND MESSAGE
    // ===============================
    case SocketEvents.SendMessage: {
      const { chatId, message } = body.data || {};
      const userId = ws.userId;

      if (!userId) {
        return ws.send(
          JSON.stringify({
            event: SocketEvents.Error,
            message: "Unauthorized socket",
          }),
        );
      }

      const chat = ChatRoom.getChat(chatId);

      if (!chat) {
        return ws.send(
          JSON.stringify({
            event: SocketEvents.Error,
            message: "Invalid chatId",
          }),
        );
      }

      const isUser1 = chat.user1.user.id.toString() === userId.toString();

      const sender = isUser1 ? chat.user1 : chat.user2;
      const receiver = isUser1 ? chat.user2 : chat.user1;

      if (!sender || !receiver) {
        return;
      }

      if (sender.socket.readyState === 1) {
        sender.socket.send(
          JSON.stringify({
            event: SocketEvents.SendMessage,
            data: { chatId, message },
          }),
        );
      }

      if (receiver.socket.readyState === 1) {
        receiver.socket.send(
          JSON.stringify({
            event: SocketEvents.MessageReceived,
            data: { chatId, message },
          }),
        );
      }

      break;
    }

    case SocketEvents.Typing: {
      const { chatId, isTyping } = body.data || {};
      const userId = ws.userId;

      if (!userId) {
        return ws.send(
          JSON.stringify({
            event: SocketEvents.Error,
            message: "Unauthorized socket",
          }),
        );
      }

      const chat = ChatRoom.getChat(chatId);

      if (!chat) {
        return ws.send(
          JSON.stringify({
            event: SocketEvents.Error,
            message: "Invalid chatId",
          }),
        );
      }

      const isUser1 = chat.user1.user.id.toString() === userId.toString();

      const receiver = isUser1 ? chat.user2 : chat.user1;

      if (!receiver) {
        return;
      }

      if (receiver.socket.readyState === 1) {
        receiver.socket.send(
          JSON.stringify({
            event: SocketEvents.Typing,
            data: { chatId, isTyping },
          }),
        );
      }

      break;
    }

    default:
      ws.send(
        JSON.stringify({
          event: SocketEvents.Error,
          message: "Unknown event",
        }),
      );
  }
}

module.exports = eventRouter;
