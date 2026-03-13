# Anon Chat — Frontend

Flutter client for the Anon Chat app. Supports mobile and web; uses the backend REST API for auth and WebSockets for real-time matching and chat.

## Repository layout

The Flutter app lives in **`anon_chat_frontend/`**. All setup and run commands below are from that directory.

```
Frontend/
├── README.md              # This file
└── anon_chat_frontend/    # Flutter app
    ├── lib/
    │   ├── core/          # Theme, colors, endpoints, API constants
    │   ├── providers/     # Auth & chat state (Provider)
    │   ├── screens/       # Login, Register, Home, Waiting, Chat
    │   ├── services/      # API client, WebSocket chat service
    │   └── widgets/       # Shared UI (e.g. auth forms)
    ├── pubspec.yaml
    └── README.md          # App-level setup & run
```

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Backend running and reachable (local or deployed)

## Quick start

```bash
cd anon_chat_frontend
flutter pub get
flutter run
```

Pick a device (Chrome, Android, iOS, etc.) when prompted. For local backend, set the base URL and WebSocket URL in the app (see **Config** below).

## Config (backend URL)

The app talks to the backend via:

- **REST:** `ApiConstants.baseUrl`  
- **WebSocket:** `ApiConstants.wsUrl`

Edit **`lib/core/constants/api_constants.dart`**:

- **Local backend:**  
  `baseUrl = 'http://<your-ip>:3000'`  
  `wsUrl = 'ws://<your-ip>:3000'`  
  (Use your machine’s LAN IP for a physical device.)

- **Deployed backend:**  
  Set `baseUrl` and `wsUrl` to your backend’s HTTPS and WSS URLs.

## Features

- **Auth:** Register, login, JWT refresh
- **Home:** Navigate to waiting room or logout
- **Waiting room:** Join queue and get matched with a random user
- **Chat:** Real-time one-on-one messaging; partner leave notification

## Tech stack

- Flutter 3.x
- **State:** Provider
- **HTTP:** Dio
- **WebSocket:** web_socket_channel
- **Fonts:** google_fonts

For detailed setup, run options, and project structure, see **[anon_chat_frontend/README.md](anon_chat_frontend/README.md)**.
