const WebSocket = require("ws");
const eventHandler = require("./event_handler");

function initSocketServer(server) {
  const wss = new WebSocket.Server({ server });

  wss.on("connection", (ws, req) => {
    eventHandler(ws, req);
  });
}

module.exports = initSocketServer;
