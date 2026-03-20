import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatWebSocketService {
  WebSocketChannel? _channel;
  Function(Map<String, dynamic>)? onMessage;
  VoidCallback? onReady;

  void connect(String url, String token) {
    print('Attempting to connect to WebSocket: $url');
    if (token.trim().isEmpty) {
      onMessage?.call({
        'event': 'error',
        'data': {'message': 'Socket token is empty'},
      });
      return;
    }
    try {
      final uri = Uri.parse(url);
      // Browsers DO NOT support custom headers (Authorization) for WebSockets.
      // We MUST pass the token as a query parameter for the backend to read.
      final webUri = uri.replace(
        queryParameters: {...uri.queryParameters, 'token': token},
      );
      print('Connecting via query param: $webUri');
      _channel = WebSocketChannel.connect(webUri);

      // Wait for the connection to be ready before firing onReady.
      _channel!.ready.then((_) {
        print('WebSocket connection is ready.');
        onReady?.call();
      }).catchError((error) {
        print('WebSocket ready error: $error');
        onMessage?.call({
          'event': 'error',
          'data': {'message': 'Connection failed: $error'},
        });
      });

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
          print(
            'WebSocket Connection Closed. code=${_channel?.closeCode}, reason=${_channel?.closeReason}',
          );
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
    } else {
      print('WebSocket: Cannot emit, channel is null.');
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
