const SocketEvents = require("../config/socket_events");

const eventSchemas = {
  [SocketEvents.EnterWaitingRoom]: {
    required: ["userId"],
  },

  [SocketEvents.SendMessage]: {
    required: ["chatId", "userId", "message"],
  },

  [SocketEvents.LeaveRoom]: {
    required: ["chatId", "userId"],
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

  if (!data.data || typeof data.data !== "object") {
    return { valid: false, error: "Missing data payload" };
  }

  const { required } = eventSchemas[data.event];

  for (const field of required) {
    if (!(field in data.data)) {
      return {
        valid: false,
        error: `Missing required field: ${field}`,
      };
    }
  }

  return { valid: true };
}

module.exports = { validateSocketMessage };
