const { verifyToken } = require("../helper/token_generator");
const WaitingQueue = require("../model/waiting_queue");
const eventRouter = require("./event_router");
const ChatRoom = require("../model/chat_room");

function eventHandler(ws, req) {
  console.log("Socket Client connected");

  console.log("Socket Client connected");
  // 1. Try to get token from Header (Mobile/Native)
  let authHeader = req.headers.authorization;

  // 2. If no header, try to get token from Query String (Web/Chrome)
  if (!authHeader) {
    const url = new URL(req.url, "http://localhost"); // 'req.url' is just the path + query
    const tokenFromQuery = url.searchParams.get("token");
    if (tokenFromQuery) {
      authHeader = `Bearer ${tokenFromQuery}`;
    }
  }
  if (!authHeader) {
    console.log("Unauthorized: No token found in header or query");
    ws.close(1008, "Unauthorized");
    return;
  }
  if (!authHeader) {
    ws.close(1008, "Unauthorized"); 
    return;
  }

  const token = authHeader.split(" ")[1];

  if (!token) {
    ws.close(1008, "Invalid token");
    return;
  }

  try {
    const decoded = verifyToken(token);

    ws.userId = decoded.id;
  } catch (err) {
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
