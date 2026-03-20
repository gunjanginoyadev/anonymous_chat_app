const SocketEvents = require("../config/socket_events");

function isSocketOpen(socket) {
  return socket && socket.readyState === 1;
}

function sendEvent(socket, event, data = {}) {
  if (!isSocketOpen(socket)) return;
  socket.send(JSON.stringify({ event, data }));
}

function sendError(socket, message) {
  if (!isSocketOpen(socket)) return;
  socket.send(
    JSON.stringify({
      event: SocketEvents.Error,
      message,
    }),
  );
}

module.exports = {
  isSocketOpen,
  sendEvent,
  sendError,
};
