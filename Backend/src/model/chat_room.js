const { v4: uuidv4 } = require("uuid");

class ChatRoom {
  constructor() {
    this.rooms = new Map();
  }

  createChat(user1, user2) {
    const chatId = uuidv4();

    this.rooms.set(chatId, {
      user1,
      user2,
    });

    return chatId;
  }

  getChat(chatId) {
    return this.rooms.get(chatId);
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
              event: "partner-left",
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
