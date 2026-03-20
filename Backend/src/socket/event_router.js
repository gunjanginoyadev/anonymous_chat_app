const SocketEvents = require("../config/socket_events");
const { validateSocketMessage } = require("../validator/socket_validator");
const { sendError } = require("./socket_response");
const handleEnterWaitingRoom = require("./handlers/enter_waiting_room");
const handleSendMessage = require("./handlers/send_message");
const handleTyping = require("./handlers/typing");
const handleToggleReaction = require("./handlers/toggle_reaction");

const eventHandlers = {
  [SocketEvents.EnterWaitingRoom]: (ws) => handleEnterWaitingRoom(ws),
  [SocketEvents.SendMessage]: (ws, data) => handleSendMessage(ws, data),
  [SocketEvents.Typing]: (ws, data) => handleTyping(ws, data),
  [SocketEvents.ToggleReaction]: (ws, data) => handleToggleReaction(ws, data),
};

function eventRouter(ws, message) {
  let body;

  try {
    body = JSON.parse(message);
  } catch {
    sendError(ws, "Invalid JSON");
    return;
  }

  // Normalize event aliases for better client compatibility.
  if (typeof body.event === "string") {
    const raw = body.event.trim();
    const aliases = {
      toggleReaction: SocketEvents.ToggleReaction,
      messageReactionUpdated: SocketEvents.MessageReactionUpdated,
    };
    body.event = aliases[raw] || raw.toLowerCase();
  }

  const validation = validateSocketMessage(body);
  if (!validation.valid) {
    sendError(ws, validation.error);
    return;
  }

  const handler = eventHandlers[body.event];
  if (!handler) {
    sendError(ws, "Unknown event");
    return;
  }

  handler(ws, body.data || {});
}

module.exports = eventRouter;
