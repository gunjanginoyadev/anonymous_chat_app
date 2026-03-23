# Anon Chat — Frontend 📱

The user-facing mobile and web application for Anon Chat, built with Flutter. This project delivers a premium, dark-themed experience for real-time anonymous conversations.

---

## 📂 Repository Structure

The actual Flutter project is contained within the `anon_chat_frontend/` directory.

```text
Frontend/
├── README.md               # This overview
└── anon_chat_frontend/     # Core Flutter Application
    ├── lib/
    │   ├── core/           # Design system tokens and API config
    │   ├── providers/      # Application state management (Provider)
    │   ├── screens/        # UI Views (Login, Chat, etc.)
    │   ├── services/       # Network logic (Dio & WebSockets)
    │   └── widgets/        # Reusable UI components
    └── README.md           # Detailed App Setup & Run guides
```

## 🛠️ Tech Stack & Features

- **Framework:** Flutter 3.x (Stable)
- **State Management:** Provider for scalable state handling.
- **Network Layer:** Dio for robust REST API interaction.
- **Real-time:** `web_socket_channel` for low-latency chat.
- **Styling:** Premium Dark Theme with `google_fonts` (Outfit/Inter).

## 🚀 Quick Start

To get the app running on your device or emulator:

1. **Navigate to the app directory:**
   ```bash
   cd anon_chat_frontend
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Run the application:**
   ```bash
   flutter run
   ```

*For detailed configuration, including how to point the app to your backend server, please refer to the **[App-level README](anon_chat_frontend/README.md)**.*
