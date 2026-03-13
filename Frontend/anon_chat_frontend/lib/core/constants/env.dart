import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();
  static String apiBaseUrl =
      dotenv.env['API_BASE_URL'] ?? 'https://anonymous-chat-app-rvcy.onrender.com';
  static String wsUrl = dotenv.env['WS_URL'] ?? 'wss://anonymous-chat-app-rvcy.onrender.com';
}
