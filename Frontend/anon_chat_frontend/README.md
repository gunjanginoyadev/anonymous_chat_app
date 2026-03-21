# Anon Chat — Flutter App 🚀

The official Flutter client for **Anon Chat**. This application provides a seamless, real-time anonymous chatting experience with a focus on high-performance and a premium user interface.

---

## ✨ Key Features

- **🌓 Dynamic UI** — Beautiful dark-themed interface with smooth transitions.
- **🛡️ Secure Auth** — Integrated JWT authentication flow with automatic token refresh.
- **⚡ WebSocket Chat** — Low-latency, real-time messaging using `web_socket_channel`.
- **🛠️ Robust Networking** — Powered by `Dio` for structured API requests.
- **🔄 State Management** — Clean and predictable state handling with `Provider`.

---

## 🚀 Getting Started

### 📋 Prerequisites

- **Flutter SDK:** [Install Flutter](https://docs.flutter.dev/get-started/install) (Stable channel recommended).
- **Backend Service:** Ensure the project backend is running (Refer to `Backend/README.md`).

### ⚙️ Configuration

Before running the app, you must configure the backend connection settings.

1. Locate **`lib/core/constants/api_constants.dart`**.
2. Update the following values:

| Environment | Base URL (REST API) | WS URL (WebSocket) |
| :--- | :--- | :--- |
| **Local (Emulator)** | `http://10.0.2.2:3000` | `ws://10.0.2.2:3000` |
| **Local (Physical)** | `http://<YOUR_LAN_IP>:3000` | `ws://<YOUR_LAN_IP>:3000` |
| **Production** | Your deployed API URL | Your deployed WSS URL |

---

## 🛠️ Development

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Run the App

```bash
# General run
flutter run

# Run specifically on Chrome
flutter run -d chrome
```

### 3. Build Patterns

- **Build Web:** `flutter build web --release`

---

## 📂 Architecture Overview

| Directory | Responsibility |
| :--- | :--- |
| `lib/main.dart` | Application entry point, theme configuration, and routing. |
| `lib/core/` | Global constants, theme definitions, and API endpoints. |
| `lib/providers/` | State management (e.g., `AuthProvider`, `ChatProvider`). |
| `lib/screens/` | Feature-specific views (Auth, Matching, Chat). |
| `lib/services/` | Core business logic and external service integrations. |
| `lib/widgets/` | Reusable UI components and layout helpers. |

---

## 📦 Main Dependencies

- **[provider](https://pub.dev/packages/provider)** — State management.
- **[dio](https://pub.dev/packages/dio)** — HTTP client for REST API.
- **[web_socket_channel](https://pub.dev/packages/web_socket_channel)** — Real-time communication.
- **[google_fonts](https://pub.dev/packages/google_fonts)** — High-quality typography.
- **[uuid](https://pub.dev/packages/uuid)** — Unique identifier generation.

---

## 📚 Resources

- [Official Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Codelabs: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
