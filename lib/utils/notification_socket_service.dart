import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../config/constants.dart';

/// Service that connects to Laravel Reverb WebSocket server
/// Protocol: Pusher-compatible (Reverb/Soketi use same protocol)
class NotificationSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  final String? userId;
  final String? authToken;
  final Set<String> _channels = {};
  
  final void Function(Map<String, dynamic> notification)? onNotification;
  final void Function(Map<String, dynamic> prices)? onGoldPriceUpdate;
  final void Function(Map<String, dynamic> syncData)? onSyncData;
  final void Function()? onConnected;
  final void Function()? onDisconnected;

  bool _isConnected = false;
  bool _shouldReconnect = true;
  String? _socketId;

  // ── Socket URL (ws:// for local, wss:// for production) ─────
  static String get _wsUrl {
    final host = AppConstants.reverbHost.trim();
    final key = AppConstants.reverbAppKey.trim();
    final isSecure = AppConstants.reverbPort == '443' || host.contains('onrender.com');
    final scheme = isSecure ? 'wss' : 'ws';
    final port = int.tryParse(AppConstants.reverbPort) ?? (isSecure ? 443 : 80);

    // بناء الرابط بشكل رسمي عبر كلاس Uri لضمان عدم وجود أخطاء في التشكيلة أو حروف زائدة
    final uri = Uri(
      scheme: scheme,
      host: host,
      port: (port == 443 || port == 80) ? null : port,
      path: '/app/$key',
      queryParameters: {
        'protocol': '7',
        'client': 'js',
        'version': '8.4.0-rc2',
        'flash': 'false',
      },
    );

    // التحقق النهائي من خلو الرابط من أي حروف زائدة أو "Fragments" قد تضاف تلقائياً
    return uri.toString().split('#').first.trim();
  }

  NotificationSocketService({
    this.userId,
    this.authToken,
    this.onNotification,
    this.onGoldPriceUpdate,
    this.onSyncData,
    this.onConnected,
    this.onDisconnected,
  });

  // ── Connect ──────────────────────────────────────────────────
  void connect() {
    _shouldReconnect = true;
    _connectInternal();
  }

  void _connectInternal() {
    try {
      debugPrint('[WS] Connecting to $_wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _listenToChannel();
    } catch (e) {
      debugPrint('[WS] Connection error: $e');
      _scheduleReconnect();
    }
  }

  void _listenToChannel() {
    _subscription = _channel!.stream.listen(
      _handleMessage,
      onError: (err) {
        debugPrint('[WS] Stream error: $err');
        _handleDisconnect();
      },
      onDone: () {
        debugPrint('[WS] Connection closed');
        _handleDisconnect();
      },
    );
  }

  void subscribe(String channelName) {
    _channels.add(channelName);
    if (_isConnected) {
      _processSubscription(channelName);
    }
  }

  Future<void> _processSubscription(String channelName) async {
    String auth = '';
    
    // Private channels require a signature from the backend
    if (channelName.startsWith('private-')) {
      auth = await _getAuthSignature(channelName);
      if (auth.isEmpty) {
        debugPrint('[WS] Auth failed for $channelName, skipping subscribe');
        return;
      }
    }

    _send({
      'event': 'pusher:subscribe',
      'data': {
        'channel': channelName,
        'auth': auth,
      }
    });
  }

  Future<String> _getAuthSignature(String channelName) async {
    if (authToken == null || _socketId == null) return '';

    try {
      final dio = Dio();
      final response = await dio.post(
        '${AppConstants.apiBaseUrl}/broadcasting/auth',
        data: {
          'socket_id': _socketId,
          'channel_name': channelName,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['auth']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('[WS] Private channel auth error: $e');
    }
    return '';
  }

  // ── Message Handler ──────────────────────────────────────────
  void _handleMessage(dynamic raw) {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = msg['event'] as String?;
      final channel = msg['channel'] as String?;
      
      // Pusher 'data' field is almost always a JSON string.
      // We perform a recursive check to ensure we get a Map.
      dynamic data = msg['data'];
      if (data is String && data.isNotEmpty) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            data = Map<String, dynamic>.from(decoded);
          }
        } catch (e) {
          debugPrint('[WS] JSON decode error for data: $e');
        }
      }

      switch (event) {
        case 'pusher:connection_established':
          _isConnected = true;
          // التحقق من أن البيانات بصيغة Map قبل القراءة لتجنب خطأ "String is not a subtype of int"
          if (data is Map<String, dynamic>) {
            _socketId = data['socket_id']?.toString();
          }
          debugPrint('[WS] Connected! socket_id=$_socketId');
          
          // Re-subscribe to all active channels
          for (final ch in _channels) {
            _processSubscription(ch);
          }
          
          _startPing();
          onConnected?.call();
          break;

        case 'notification.new':
        case 'new.global.notification':
          debugPrint('[WS] New Notification: $data');
          onNotification?.call(Map<String, dynamic>.from(data));
          break;

        case 'gold.updated':
          onGoldPriceUpdate?.call(Map<String, dynamic>.from(data));
          break;

        case 'app.sync':
          debugPrint('[WS] App Sync Event: $data');
          onSyncData?.call(Map<String, dynamic>.from(data));
          break;

        case 'pusher:pong':
          break; // heartbeat

        case 'pusher:error':
          debugPrint('[WS] Pusher Error: $data');
          break;

        default:
          // Handle other custom events if they arrive per-channel
          if (event != null && !event.startsWith('pusher:')) {
             debugPrint('[WS] Event received: $event on $channel');
          }
          break;
      }
    } catch (e) {
      debugPrint('[WS] Parse error: $e');
    }
  }

  // ── Ping / Keepalive ─────────────────────────────────────────
  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _send({'event': 'pusher:ping', 'data': {}});
    });
  }

  // ── Disconnect Handling ──────────────────────────────────────
  void _handleDisconnect() {
    _isConnected = false;
    _pingTimer?.cancel();
    onDisconnected?.call();
    if (_shouldReconnect) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('[WS] Reconnecting...');
      _connectInternal();
    });
  }

  // ── Send ─────────────────────────────────────────────────────
  void _send(Map<String, dynamic> msg) {
    try {
      _channel?.sink.add(jsonEncode(msg));
    } catch (e) {
      debugPrint('[WS] Send error: $e');
    }
  }

  // ── Disconnect ───────────────────────────────────────────────
  void disconnect() {
    _shouldReconnect = false;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
}
