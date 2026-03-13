# Anon Chat — Flutter App

Flutter application for **Anon Chat**: anonymous one-on-one real-time chat. Uses the project backend for auth (REST) and chat/matching (WebSocket).

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and on your `PATH`
- Backend server running (see repo root or `Backend/README.md`)

### Install dependencies

```bash
flutter pub get
```

### Configure backend URL

Edit **`lib/core/constants/api_constants.dart`**:

- **Local backend (e.g. emulator/device on same network):**  
  - `baseUrl` = `http://<YOUR_IP>:3000`  
  - `wsUrl` = `ws://<YOUR_IP>:3000`  
  Use your computer’s local IP (e.g. `192.168.1.40`) so the device can reach the server.

- **Deployed backend:**  
  Set `baseUrl` and `wsUrl` to your server’s base URL and WebSocket URL (e.g. `https://...` and `wss://...`).

### Run the app

```bash
flutter run
```

Choose a target (Chrome, Android, iOS, etc.). For web:

```bash
flutter run -d chrome
```

## Project structure

| Path | Description |
|------|-------------|
| `lib/main.dart` | App entry, theme, routes |
| `lib/core/` | Theme, colors, `api_constants.dart`, `endpoints.dart` |
| `lib/providers/` | `AuthProvider`, `ChatProvider` (state) |
| `lib/screens/` | Login, Register, Home, Waiting, Chat |
| `lib/services/` | API calls, `ChatWebSocketService` |
| `lib/widgets/` | Shared UI (e.g. auth forms) |

## Main dependencies

- **provider** — State management
- **dio** — HTTP client for auth API
- **web_socket_channel** — WebSocket for chat
- **google_fonts** — Typography
- **uuid** — Identifiers

## Flutter resources

- [Flutter documentation](https://docs.flutter.dev/)
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
