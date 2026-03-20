const SocketEvents = require("../config/socket_events");

const eventSchemas = {
  [SocketEvents.EnterWaitingRoom]: {
    required: [],
  },

  [SocketEvents.SendMessage]: {
    required: ["chatId", "message"],
  },

  [SocketEvents.Typing]: {
    required: ["chatId", "isTyping"],
  },

  [SocketEvents.ToggleReaction]: {
    required: ["chatId", "messageId", "emoji"],
  },
};

function validateSocketMessage(data) {
  if (!data || typeof data !== "object") {
    return { valid: false, error: "Invalid data format" };
  }

  if (!data.event || typeof data.event !== "string") {
    return { valid: false, error: "Missing or invalid event field" };
  }

  if (!eventSchemas[data.event]) {
    return { valid: false, error: "Invalid event type" };
  }

  const payload = data.data ?? {};
  if (typeof payload !== "object" || Array.isArray(payload)) {
    return { valid: false, error: "Missing data payload" };
  }

  const { required } = eventSchemas[data.event];

  for (const field of required) {
    if (!(field in payload)) {
      return {
        valid: false,
        error: `Missing required field: ${field}`,
      };
    }
  }

  if (
    data.event === SocketEvents.SendMessage &&
    typeof payload.message !== "string"
  ) {
    return { valid: false, error: "message must be a string" };
  }

  if (
    data.event === SocketEvents.Typing &&
    typeof payload.isTyping !== "boolean"
  ) {
    return { valid: false, error: "isTyping must be a boolean" };
  }

  if (
    data.event === SocketEvents.ToggleReaction &&
    (typeof payload.emoji !== "string" || payload.emoji.trim().length === 0)
  ) {
    return { valid: false, error: "emoji must be a non-empty string" };
  }

  return { valid: true };
}

module.exports = { validateSocketMessage };
