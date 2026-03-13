import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();
  static String apiBaseUrl =
      dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.50:3000';
  static String wsUrl = dotenv.env['WS_URL'] ?? 'ws://192.168.1.50:3000';
}
