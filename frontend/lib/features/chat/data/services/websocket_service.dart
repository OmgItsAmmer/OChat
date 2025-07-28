// import 'dart:async';
// import 'dart:convert';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/status.dart' as status;
// import 'package:get_storage/get_storage.dart';
// import 'package:get/get.dart';

// import '../../../core/utils/constants/api_constants.dart';
// import '../../../core/utils/constants/storage_keys.dart';
// import '../data/models/message_model.dart';
// import '../data/models/user_model.dart';

// /// WebSocket Service for real-time messaging
// /// This service manages the WebSocket connection to the Rust backend
// /// and handles real-time message sending/receiving
// class WebSocketService extends GetxService {
//   // Singleton pattern for consistent WebSocket connection
//   static final WebSocketService _instance = WebSocketService._internal();
//   factory WebSocketService() => _instance;
//   WebSocketService._internal();

//   // WebSocket connection and state management
//   WebSocketChannel? _channel;
//   StreamSubscription? _subscription;
//   Timer? _heartbeatTimer;
//   Timer? _reconnectTimer;

//   // Connection state tracking
//   final _connectionStatus = ConnectionStatus.disconnected.obs;
//   final _isReconnecting = false.obs;
//   int _reconnectAttempts = 0;

//   // GetStorage for accessing authentication tokens
//   final _storage = GetStorage();

//   // Stream controllers for broadcasting events to listeners
//   final _messageController = StreamController<MessageModel>.broadcast();
//   final _userStatusController = StreamController<UserStatusUpdate>.broadcast();
//   final _typingController = StreamController<TypingIndicator>.broadcast();

//   // Public streams that other parts of the app can listen to
//   Stream<MessageModel> get messageStream => _messageController.stream;
//   Stream<UserStatusUpdate> get userStatusStream => _userStatusController.stream;
//   Stream<TypingIndicator> get typingStream => _typingController.stream;

//   // Getters for connection state
//   ConnectionStatus get connectionStatus => _connectionStatus.value;
//   bool get isConnected => _connectionStatus.value == ConnectionStatus.connected;
//   bool get isReconnecting => _isReconnecting.value;

//   /// Initialize the WebSocket service
//   /// This is called when the service is first created
//   @override
//   void onInit() {
//     super.onInit();
//     print('WebSocketService initialized');
//   }

//   /// Connect to the WebSocket server
//   /// This establishes the real-time connection with authentication
//   Future<void> connect() async {
//     try {
//       // Check if already connected
//       if (_connectionStatus.value == ConnectionStatus.connected) {
//         print('WebSocket already connected');
//         return;
//       }

//       _connectionStatus.value = ConnectionStatus.connecting;
//       print('Connecting to WebSocket...');

//       // Get authentication token for WebSocket connection
//       final token = _storage.read(StorageKeys.authToken);
//       if (token == null) {
//         throw Exception('No authentication token available');
//       }

//       // Create WebSocket URL with authentication
//       final wsUrl = Uri.parse('${ApiConstants.wsUrl}?token=$token');

//       // Establish WebSocket connection
//       _channel = WebSocketChannel.connect(wsUrl);

//       // Listen to WebSocket messages
//       _subscription = _channel!.stream.listen(
//         _handleMessage,
//         onDone: _handleDisconnection,
//         onError: _handleError,
//       );

//       // Send initial connection message
//       _sendMessage({
//         'type': 'authenticate',
//         'token': token,
//       });

//       // Start heartbeat to keep connection alive
//       _startHeartbeat();

//       _connectionStatus.value = ConnectionStatus.connected;
//       _reconnectAttempts = 0;
//       _isReconnecting.value = false;

//       print('WebSocket connected successfully');
//     } catch (e) {
//       print('WebSocket connection failed: $e');
//       _connectionStatus.value = ConnectionStatus.disconnected;
//       _scheduleReconnect();
//     }
//   }

//   /// Disconnect from the WebSocket server
//   /// This cleanly closes the connection and stops all timers
//   Future<void> disconnect() async {
//     print('Disconnecting WebSocket...');

//     _connectionStatus.value = ConnectionStatus.disconnecting;

//     // Cancel timers
//     _heartbeatTimer?.cancel();
//     _reconnectTimer?.cancel();

//     // Close subscription and channel
//     await _subscription?.cancel();
//     await _channel?.sink.close(status.normalClosure);

//     _subscription = null;
//     _channel = null;
//     _connectionStatus.value = ConnectionStatus.disconnected;

//     print('WebSocket disconnected');
//   }

//   /// Send a text message through WebSocket
//   /// This is the main method for sending real-time messages
//   Future<void> sendMessage(String receiverId, String content) async {
//     if (!isConnected) {
//       throw Exception('WebSocket not connected');
//     }

//     final message = {
//       'type': 'send_message',
//       'data': {
//         'receiver_id': receiverId,
//         'content': content,
//         'message_type': 'text',
//         'timestamp': DateTime.now().toIso8601String(),
//       }
//     };

//     _sendMessage(message);
//     print('Message sent via WebSocket to $receiverId');
//   }

//   /// Send typing indicator to show the user is typing
//   void sendTypingIndicator(String receiverId, bool isTyping) {
//     if (!isConnected) return;

//     final message = {
//       'type': 'typing_indicator',
//       'data': {
//         'receiver_id': receiverId,
//         'is_typing': isTyping,
//       }
//     };

//     _sendMessage(message);
//   }

//   /// Mark messages as read
//   void markMessagesAsRead(String conversationId) {
//     if (!isConnected) return;

//     final message = {
//       'type': 'mark_read',
//       'data': {
//         'conversation_id': conversationId,
//       }
//     };

//     _sendMessage(message);
//   }

//   /// Handle incoming WebSocket messages
//   /// This processes different types of messages from the server
//   void _handleMessage(dynamic data) {
//     try {
//       final message = jsonDecode(data as String) as Map<String, dynamic>;
//       final messageType = message['type'] as String;

//       print('Received WebSocket message: $messageType');

//       switch (messageType) {
//         case 'message':
//           // New message received
//           final messageData = message['data'] as Map<String, dynamic>;
//           final messageModel = MessageModel.fromJson(messageData);
//           _messageController.add(messageModel);
//           break;

//         case 'user_status':
//           // User online/offline status update
//           final statusData = message['data'] as Map<String, dynamic>;
//           final statusUpdate = UserStatusUpdate.fromJson(statusData);
//           _userStatusController.add(statusUpdate);
//           break;

//         case 'typing_indicator':
//           // Typing indicator from another user
//           final typingData = message['data'] as Map<String, dynamic>;
//           final typingIndicator = TypingIndicator.fromJson(typingData);
//           _typingController.add(typingIndicator);
//           break;

//         case 'message_status':
//           // Message delivery/read status update
//           final statusData = message['data'] as Map<String, dynamic>;
//           print('Message status update: $statusData');
//           break;

//         case 'auth_success':
//           print('WebSocket authentication successful');
//           break;

//         case 'auth_failed':
//           print('WebSocket authentication failed');
//           disconnect();
//           break;

//         case 'error':
//           final error = message['error'] as String;
//           print('WebSocket error: $error');
//           break;

//         case 'pong':
//           // Heartbeat response - connection is alive
//           break;

//         default:
//           print('Unknown WebSocket message type: $messageType');
//       }
//     } catch (e) {
//       print('Error handling WebSocket message: $e');
//     }
//   }

//   /// Handle WebSocket disconnection
//   /// This triggers reconnection logic if appropriate
//   void _handleDisconnection() {
//     print('WebSocket disconnected');
//     _connectionStatus.value = ConnectionStatus.disconnected;

//     // Stop heartbeat
//     _heartbeatTimer?.cancel();

//     // Attempt to reconnect if not intentionally disconnected
//     if (_connectionStatus.value != ConnectionStatus.disconnecting) {
//       _scheduleReconnect();
//     }
//   }

//   /// Handle WebSocket errors
//   /// This logs errors and triggers reconnection
//   void _handleError(dynamic error) {
//     print('WebSocket error: $error');
//     _connectionStatus.value = ConnectionStatus.disconnected;
//     _scheduleReconnect();
//   }

//   /// Send a message through the WebSocket channel
//   /// This is a low-level method for sending JSON data
//   void _sendMessage(Map<String, dynamic> message) {
//     if (_channel?.sink != null) {
//       _channel!.sink.add(jsonEncode(message));
//     }
//   }

//   /// Start heartbeat timer to keep connection alive
//   /// This sends periodic ping messages to prevent timeout
//   void _startHeartbeat() {
//     _heartbeatTimer?.cancel();
//     _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
//       if (isConnected) {
//         _sendMessage({'type': 'ping'});
//       } else {
//         timer.cancel();
//       }
//     });
//   }

//   /// Schedule automatic reconnection with exponential backoff
//   /// This implements smart reconnection logic to avoid overwhelming the server
//   void _scheduleReconnect() {
//     if (_reconnectAttempts >= ApiConstants.reconnectAttempts) {
//       print('Max reconnection attempts reached');
//       return;
//     }

//     _isReconnecting.value = true;
//     _reconnectAttempts++;

//     // Exponential backoff: 3s, 6s, 12s, 24s, 48s
//     final delay = ApiConstants.reconnectDelay * _reconnectAttempts;

//     print('Scheduling reconnection attempt $_reconnectAttempts in ${delay}s');

//     _reconnectTimer?.cancel();
//     _reconnectTimer = Timer(Duration(seconds: delay), () {
//       if (_connectionStatus.value == ConnectionStatus.disconnected) {
//         connect();
//       }
//     });
//   }

//   /// Clean up resources when the service is disposed
//   @override
//   void onClose() {
//     disconnect();
//     _messageController.close();
//     _userStatusController.close();
//     _typingController.close();
//     super.onClose();
//   }
// }

// /// Enum representing WebSocket connection status
// /// This helps track the current state of the connection
// enum ConnectionStatus {
//   disconnected,
//   connecting,
//   connected,
//   disconnecting,
// }

// /// Model for user status updates (online/offline)
// /// This represents when users come online or go offline
// class UserStatusUpdate {
//   final String userId;
//   final bool isOnline;
//   final DateTime? lastSeen;

//   const UserStatusUpdate({
//     required this.userId,
//     required this.isOnline,
//     this.lastSeen,
//   });

//   factory UserStatusUpdate.fromJson(Map<String, dynamic> json) {
//     return UserStatusUpdate(
//       userId: json['user_id'] as String,
//       isOnline: json['is_online'] as bool,
//       lastSeen: json['last_seen'] != null
//           ? DateTime.parse(json['last_seen'] as String)
//           : null,
//     );
//   }
// }

// /// Model for typing indicators
// /// This represents when someone is typing a message
// class TypingIndicator {
//   final String userId;
//   final String conversationId;
//   final bool isTyping;

//   const TypingIndicator({
//     required this.userId,
//     required this.conversationId,
//     required this.isTyping,
//   });

//   factory TypingIndicator.fromJson(Map<String, dynamic> json) {
//     return TypingIndicator(
//       userId: json['user_id'] as String,
//       conversationId: json['conversation_id'] as String,
//       isTyping: json['is_typing'] as bool,
//     );
//   }
// }
