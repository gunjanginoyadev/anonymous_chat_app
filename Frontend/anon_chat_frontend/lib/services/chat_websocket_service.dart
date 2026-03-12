import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatWebSocketService {
  WebSocketChannel? _channel;
  Function(Map<String, dynamic>)? onMessage;

  void connect(String url, String token) {
    print('Attempting to connect to WebSocket: $url');
    try {
      final uri = Uri.parse(url);
      // Browsers DO NOT support custom headers (Authorization) for WebSockets.
      // We MUST pass the token as a query parameter for the backend to read.
      final webUri = uri.replace(
        queryParameters: {...uri.queryParameters, 'token': token},
      );
      print('Running on WEB: Connecting via query param: $webUri');
      _channel = WebSocketChannel.connect(webUri);

      _channel!.stream.listen(
        (data) {
          print('WebSocket Received raw: $data');
          try {
            final decoded = jsonDecode(data.toString()) as Map<String, dynamic>;
            onMessage?.call(decoded);
          } catch (e) {
            print('WebSocket Parse Error: $e');
          }
        },
        onDone: () {
          print('WebSocket Connection Closed');
          onMessage?.call({'event': 'connection_closed'});
        },
        onError: (error) {
          print('WebSocket Error: $error');
          onMessage?.call({
            'event': 'error',
            'data': {'message': error.toString()},
          });
        },
      );
    } catch (e) {
      onMessage?.call({
        'event': 'error',
        'data': {'message': 'Connection failed: $e'},
      });
    }
  }

  void emit(String event, Map<String, dynamic> data) {
    if (_channel != null) {
      final payload = jsonEncode({'event': event, 'data': data});
      print('WebSocket Emitting: $payload');
      _channel!.sink.add(payload);
    }
  }

  void leave() {
    disconnect();
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
