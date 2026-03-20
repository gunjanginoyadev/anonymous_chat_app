const { v4: uuidv4 } = require("uuid");
const SocketEvents = require("../config/socket_events");

class ChatRoom {
  constructor() {
    this.rooms = new Map();
  }

  createChat(user1, user2) {
    const chatId = uuidv4();

    this.rooms.set(chatId, {
      user1,
      user2,
      messages: [],
    });

    return chatId;
  }

  getChat(chatId) {
    return this.rooms.get(chatId);
  }

  addMessage(chatId, { senderId, message }) {
    const chat = this.rooms.get(chatId);
    if (!chat) return null;

    const entry = {
      id: uuidv4(),
      senderId: senderId.toString(),
      message,
      timestamp: Date.now(),
      reactions: {}, // { "🔥": ["userId1", "userId2"] }
    };

    chat.messages.push(entry);
    return entry;
  }

  toggleReaction(chatId, messageId, userId, emoji) {
    const chat = this.rooms.get(chatId);
    if (!chat) return null;

    const target = chat.messages.find(
      (m) => String(m.id) === String(messageId),
    );
    if (!target) return null;

    const users = new Set(target.reactions[emoji] || []);
    const normalizedUserId = userId.toString();
    let action = "added";

    if (users.has(normalizedUserId)) {
      users.delete(normalizedUserId);
      action = "removed";
    } else {
      users.add(normalizedUserId);
    }

    if (users.size === 0) {
      delete target.reactions[emoji];
    } else {
      target.reactions[emoji] = Array.from(users);
    }

    return {
      messageId: target.id,
      emoji,
      action,
      userId: normalizedUserId,
      reactions: target.reactions,
    };
  }

  hasUser(userId) {
    if (!userId) return false;
    const target = userId.toString();

    for (const [chatId, chat] of this.rooms.entries()) {
      const user1Id = chat.user1?.user?.id?.toString();
      const user2Id = chat.user2?.user?.id?.toString();
      const user1SocketOpen = chat.user1?.socket?.readyState === 1;
      const user2SocketOpen = chat.user2?.socket?.readyState === 1;

      // Self-heal stale rooms so users are not blocked from rejoining queue.
      if (!user1SocketOpen && !user2SocketOpen) {
        this.rooms.delete(chatId);
        continue;
      }

      if (user1Id === target) {
        if (!user1SocketOpen) {
          this.rooms.delete(chatId);
          continue;
        }
        return true;
      }

      if (user2Id === target) {
        if (!user2SocketOpen) {
          this.rooms.delete(chatId);
          continue;
        }
        return true;
      }
    }

    return false;
  }

  removeChat(chatId) {
    this.rooms.delete(chatId);
  }

  removeUser(socket) {
    for (const [chatId, chat] of this.rooms.entries()) {
      if (chat.user1.socket === socket || chat.user2.socket === socket) {
        const otherUser =
          chat.user1.socket === socket ? chat.user2 : chat.user1;

        if (otherUser.socket.readyState === 1) {
          otherUser.socket.send(
            JSON.stringify({
              event: SocketEvents.PartnerLeft,
              message: "Partner disconnected",
            }),
          );
        }

        this.rooms.delete(chatId);
        break;
      }
    }
  }
}

module.exports = new ChatRoom();
