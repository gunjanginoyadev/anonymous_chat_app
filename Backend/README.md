# Anon Chat — Backend

Node.js backend for the Anon Chat app: REST API for auth and a WebSocket server for real-time matching and chat.

## Tech Stack

- **Runtime:** Node.js
- **Framework:** Express 5
- **Database:** MongoDB (Mongoose)
- **Auth:** JWT (access + refresh tokens)
- **Realtime:** WebSocket (`ws`)

## Setup

### Prerequisites

- Node.js (v18+ recommended)
- MongoDB (local or [MongoDB Atlas](https://www.mongodb.com/cloud/atlas))

### Install & run

```bash
npm install
cp .env.sample .env
# Edit .env with your values (see below)
npm run dev    # development (nodemon)
npm start      # production
```

Server listens on `PORT` from `.env` (default 3000). HTTP and WebSocket use the same port.

## Environment Variables

Create a `.env` file (see `.env.sample`):

| Variable | Description |
| -------- | ----------- |
| `PORT` | Server port (e.g. `3000`) |
| `JET_SECRET` | Secret for signing JWT access tokens |
| `JET_REFRESH_TOKEN_SECRET` | Secret for signing JWT refresh tokens |
| `MONGODB_URI` | MongoDB connection string (e.g. `mongodb://localhost:27017/anon_chat`) |

## REST API

Base path: `/api`.

### Auth — `/api/auth`

| Method | Endpoint | Description |
| ------ | -------- | ----------- |
| POST | `/register` | Register (body: username, password, etc. as defined in controller) |
| POST | `/login` | Login (returns access + refresh tokens) |
| POST | `/refresh-token` | Get new access token using refresh token |

Requests/responses are JSON. Include access token in `Authorization: Bearer <token>` where required.

## WebSocket

Connect to the same host and port as the HTTP server (e.g. `ws://localhost:3000`).

### Connection

- For protected events (e.g. entering waiting room), the client must authenticate (e.g. send token in first message or query). The server associates the connection with a user (`userId`, `username`).

### Events (client → server)

Send JSON messages with an `event` field (and optional `data`).

| Event | Description |
| ----- | ----------- |
| `enter-waiting-room` | Join the matching queue (requires authenticated user) |
| `send-message` | Send a chat message (when in a chat room; include message content in `data`) |

### Events (server → client)

Server sends JSON with `event` and optional `data` / `message`.

| Event | Description |
| ----- | ----------- |
| `in-waiting-room` | Confirmed in waiting room, waiting for a partner |
| `in-chat` | Matched; `data` includes `chatId` and `partner` (userId, username) |
| `message-received` | Incoming message from partner |
| `partner-left` | Partner left the chat |
| `error` | Error; `message` contains description |

## Project Structure

```
Backend/
├── src/
│   ├── config/       # env, db, socket_events
│   ├── controllers/  # auth_controller
│   ├── helper/       # token_generator, api_response
│   ├── model/        # user_model, chat_room, waiting_queue
│   ├── repository/   # user_repository
│   ├── routes/       # apis, auth_routes
│   ├── services/     # auth_service
│   ├── socket/       # socket_server, event_router, event_handler
│   ├── validator/    # socket_validator
│   ├── app.js        # Express app
│   └── server.js     # HTTP server + WebSocket attach
├── .env.sample
├── package.json
└── README.md
```

## Scripts

- `npm run dev` — Start with nodemon (auto-restart on file changes)
- `npm start` — Start with `node src/server.js`
- `npm test` — Placeholder (no tests defined yet)
