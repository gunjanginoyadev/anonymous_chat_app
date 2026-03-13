# Anon Chat

A real-time anonymous chat application that pairs users in one-on-one conversations. Users register and log in, then join a waiting room to be matched with a random stranger for a private chat over WebSockets.

## Features

- **User authentication** — Register and login with JWT (access + refresh tokens)
- **Waiting room** — Join a queue and get matched with another user automatically
- **Real-time chat** — One-on-one messaging over WebSockets
- **Anonymous pairing** — Chat with a partner identified only by username (no personal data shared)
- **Partner leave handling** — Notified when the other user leaves; can re-join the waiting room

## Tech Stack

| Layer    | Technology        |
| -------- | ------------------ |
| Frontend | Flutter (mobile & web) |
| Backend  | Node.js, Express   |
| Realtime | WebSocket (ws)     |
| Database | MongoDB (Mongoose) |
| Auth     | JWT (access + refresh) |

## Project Structure

```
Anon Chat/
├── Backend/                 # Node.js API + WebSocket server
│   ├── src/
│   │   ├── config/          # DB, env, socket events
│   │   ├── controllers/     # Auth controller
│   │   ├── model/           # User, ChatRoom, WaitingQueue
│   │   ├── routes/          # REST API routes
│   │   ├── socket/          # WebSocket server & event handling
│   │   └── ...
│   └── README.md
├── Frontend/
│   └── anon_chat_frontend/  # Flutter app
│       ├── lib/
│       │   ├── core/        # Theme, constants, endpoints
│       │   ├── providers/   # Auth & chat state
│       │   ├── screens/    # Login, Register, Home, Waiting, Chat
│       │   ├── services/   # WebSocket & API client
│       │   └── widgets/
│       └── README.md
└── README.md                # This file
```

## Getting Started

### Prerequisites

- **Node.js** (v18+ recommended) and **npm**
- **MongoDB** (local or Atlas)
- **Flutter** SDK (for the frontend)

### 1. Backend

```bash
cd Backend
cp .env.sample .env
# Edit .env with your PORT, JWT secrets, and MONGODB_URI
npm install
npm run dev
```

Server runs at `http://localhost:3000` (or your `PORT`). See [Backend/README.md](Backend/README.md) for API and WebSocket details.

### 2. Frontend

```bash
cd Frontend/anon_chat_frontend
flutter pub get
flutter run
```

Configure the backend base URL in the app (e.g. in `lib/core/constants/` or environment) to point to your backend. See [Frontend/anon_chat_frontend/README.md](Frontend/anon_chat_frontend/README.md) for setup and run options.

### 3. Environment

Backend needs a `.env` (use `.env.sample` as template):

- `PORT` — Server port (e.g. 3000)
- `JET_SECRET` — JWT access token secret
- `JET_REFRESH_TOKEN_SECRET` — JWT refresh token secret  
- `MONGODB_URI` — MongoDB connection string (e.g. `mongodb://localhost:27017/anon_chat`)

## API Overview

- `POST /api/auth/register` — Register
- `POST /api/auth/login` — Login
- `POST /api/auth/refresh-token` — Refresh access token

Chat and matching are handled over **WebSocket** (same host/port as the HTTP server). Events include: enter waiting room, in-chat, send-message, message-received, partner-left.

## License

ISC
