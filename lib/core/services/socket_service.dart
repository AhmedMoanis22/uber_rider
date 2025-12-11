import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../network/api_constant.dart';

class SocketService {
  IO.Socket? socket;
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  void connect({String? token}) {
    // Extract base URL without /api/ for socket connection
    final baseUrl = ApiConstance.baseUrl.replaceAll('/api/', '');

    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'authorization': 'Bearer $token'})
          .build(),
    );

    socket?.connect();

    socket?.connect();

    socket?.onConnect((_) {
      print('========================================');
      print('✅ Socket connected successfully!');
      print('========================================');
    });

    socket?.onDisconnect((_) {
      print('❌ Socket disconnected');
    });

    socket?.onError((error) {
      print('⚠️ Socket error: $error');
    });

    // Debug: Log ALL incoming socket events
    socket?.onAny((event, data) {
      print('📨 SOCKET EVENT RECEIVED:');
      print('   Event: $event');
      print('   Data: $data');
    });
  }

  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
  }

  void emit(String event, dynamic data) {
    socket?.emit(event, data);
  }

  void on(String event, Function(dynamic) handler) {
    socket?.on(event, handler);
  }

  void off(String event) {
    socket?.off(event);
  }

  bool get isConnected => socket?.connected ?? false;
}
