const { verifyToken } = require("../helper/token_generator");
const WaitingQueue = require("../model/waiting_queue");
const eventRouter = require("./event_router");
const ChatRoom = require("../model/chat_room");
const User = require("../model/user_model");

async function eventHandler(ws, req) {
  console.log("Socket Client connected");

  let token;

  // 1. Try to get token from Header (Mobile/Native)
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith("Bearer ")) {
    token = authHeader.split(" ")[1];
  }

  // 2. If no header, try to get token from Query String (Web/Chrome)
  if (!token) {
    const url = new URL(req.url, `http://${req.headers.host || "localhost"}`);
    token = url.searchParams.get("token");
  }

  if (!token) {
    console.log("Unauthorized: No token found");
    ws.close(1008, "Unauthorized");
    return;
  }

  try {
    const decoded = verifyToken(token);
    ws.userId = decoded.id;
    const user = await User.findById(decoded.id);
    if (!user) {
      ws.close(1008, "User not found");
      return;
    }

    ws.username = user.name;
    ws.profilePicture = user.profilePicture;

  } catch (err) {
    console.error("Token verification failed:", err.message);
    ws.close(1008, "Token verification failed");
    return;
  }

  ws.on("message", (message) => {
    eventRouter(ws, message);
  });

  ws.on("close", () => {
    WaitingQueue.removeBySocket(ws);
    ChatRoom.removeUser(ws);
  });
}

module.exports = eventHandler;
