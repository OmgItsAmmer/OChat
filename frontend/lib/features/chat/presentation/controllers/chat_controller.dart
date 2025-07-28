import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../../core/utils/http/http_client.dart';
import '../../data/models/message_model.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/user_model.dart';

/// 💬 Chat Controller
///
/// App flow: Flutter UI -> ChatController -> Rust server (HTTP) -> Supabase
/// All chat actions go through the Rust backend, not directly to Supabase.
///
/// This makes the app more secure and allows custom business logic in Rust.
class ChatController extends GetxController {
  // 📱 Storage and backend clients
  final _storage = GetStorage();

  /// Returns the current user's id, or null if not logged in
  String? getCurrentUserId() => null; // TODO: Get from auth/session

  final TextEditingController messageController = TextEditingController();

  // 🎯 Reactive State Variables
  final RxList<ConversationModel> _conversations = <ConversationModel>[].obs;
  List<ConversationModel> get conversations => _conversations;

  final RxList<MessageModel> _currentMessages = <MessageModel>[].obs;
  List<MessageModel> get currentMessages => _currentMessages;

  final Rx<ConversationModel?> _activeConversation =
      Rx<ConversationModel?>(null);
  ConversationModel? get activeConversation => _activeConversation.value;

  final _isLoadingConversations = false.obs;
  final _isLoadingMessages = false.obs;
  final _isSendingMessage = false.obs;

  bool get isLoadingConversations => _isLoadingConversations.value;
  bool get isLoadingMessages => _isLoadingMessages.value;
  bool get isSendingMessage => _isSendingMessage.value;

  final RxMap<String, UserModel> _typingUsers = <String, UserModel>{}.obs;
  Map<String, UserModel> get typingUsers => _typingUsers;

  final RxList<UserModel> _onlineUsers = <UserModel>[].obs;
  List<UserModel> get onlineUsers => _onlineUsers;

  final _searchQuery = ''.obs;
  final _isSearching = false.obs;

  String get searchQuery => _searchQuery.value;
  bool get isSearching => _isSearching.value;

  final _messageText = ''.obs;
  final _isTyping = false.obs;

  String get messageText => _messageText.value;
  bool get isTyping => _isTyping.value;

  // Typing indicator timer
  Timer? _typingTimer;

  // @override
  // void onInit() {
  //   super.onInit();
  //   // Optionally: load cached conversations
  // }

  @override
  void onClose() {
    messageController.dispose();
    _typingTimer?.cancel();
    super.onClose();
  }

  /// Send a text message via Rust backend
  ///
  /// This method sends the message to the Rust server, which then writes to Supabase.
  /// Shows optimistic UI update and handles errors.
  Future<bool> sendMessage({
    required String conversationId,
    required String text,
    String? replyToId,
  }) async {
    if (text.trim().isEmpty) return false;
    try {
      _isSendingMessage.value = true;
      // TODO: Replace with actual user id from auth/session
      final userId = getCurrentUserId() ?? 'user1';
      // Optimistic UI update
      final optimisticMessage = MessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conversationId,
        senderId: userId,
        text: text.trim(),
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
        type: MessageType.text,
      );
      _currentMessages.insert(0, optimisticMessage);
      // Call Rust backend
      final response = await THttpHelper.post('messages/send', {
        'conversation_id': conversationId,
        'sender_id': userId,
        'text': text.trim(),
        'reply_to_id': replyToId,
      });
      // Parse real message from response
      final realMessage = MessageModel.fromJson(response['message']);
      final index =
          _currentMessages.indexWhere((m) => m.id == optimisticMessage.id);
      if (index != -1) {
        _currentMessages[index] = realMessage;
      }
      return true;
    } catch (e) {
      _currentMessages.removeWhere((m) => m.id.startsWith('temp_'));
      // Optionally: show error to user
      print('❌ Error sending message: $e');
      return false;
    } finally {
      _isSendingMessage.value = false;
    }
  }

  /// Load messages for a specific conversation from Rust backend
  Future<void> loadMessages(String conversationId) async {
    try {
      _isLoadingMessages.value = true;
      _activeConversation.value =
          _conversations.firstWhereOrNull((c) => c.id == conversationId);
      // Call Rust backend
      final response = await THttpHelper.get('messages/$conversationId');
      final messages = (response['messages'] as List)
          .map<MessageModel>((data) => MessageModel.fromJson(data))
          .toList();
      _currentMessages.assignAll(messages);
      print(
          '📨 Loaded ${messages.length} messages for conversation $conversationId');
    } catch (e) {
      print('❌ Error loading messages: $e');
    } finally {
      _isLoadingMessages.value = false;
    }
  }

  /// Start typing indicator
  ///
  /// Broadcasts typing status to other users in the conversation.
  /// Automatically stops after a timeout.
  void startTyping(String conversationId) {
    if (_isTyping.value) return;

    _isTyping.value = true;

    // Broadcast typing status
    // TODO: Implement actual typing indicator logic via Rust backend
    // For now, we'll just broadcast to the typing channel
    // This requires a real-time channel subscription to be set up
    // and the Rust backend to handle presence and typing updates.
    // For simplicity, we'll just broadcast a dummy message for now.
    // In a real app, this would involve a WebSocket connection.
    // For this example, we'll simulate a dummy typing indicator.
    // This part needs to be coordinated with the Rust backend's typing logic.
    // For now, we'll just broadcast a dummy message.
    // The actual typing status will be managed by the Rust backend.
    // This method is primarily for UI feedback.

    // Auto-stop typing after 3 seconds
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _stopTyping();
    });
  }

  /// Stop typing indicator
  void _stopTyping() {
    if (!_isTyping.value) return;

    _isTyping.value = false;
    _typingTimer?.cancel();

    // Broadcast stop typing
    // TODO: Implement actual stop typing logic via Rust backend
    // This requires a real-time channel subscription to be set up
    // and the Rust backend to handle presence and typing updates.
    // For simplicity, we'll just broadcast a dummy message.
    // In a real app, this would involve a WebSocket connection.
    // For this example, we'll simulate a dummy stop typing message.
    // This part needs to be coordinated with the Rust backend's typing logic.
    // For now, we'll just broadcast a dummy message.
  }

  // 📁 Conversation Management

  /// Load all conversations for the current user from Rust backend
  Future<void> _loadConversations() async {
    try {
      _isLoadingConversations.value = true;
      // TODO: Replace with actual user id from auth/session
      final userId = getCurrentUserId() ?? 'user1';

      // Call Rust backend
      final response = await THttpHelper.get('conversations/$userId');
      final conversations = (response['conversations'] as List)
          .map<ConversationModel>((data) => ConversationModel.fromJson(data))
          .toList();
      _conversations.assignAll(conversations);

      // Cache conversations locally
      _storage.write('cached_conversations',
          conversations.map((c) => c.toJson()).toList());

      print('📁 Loaded ${conversations.length} conversations');
    } catch (e) {
      print('❌ Error loading conversations: $e');
    } finally {
      _isLoadingConversations.value = false;
    }
  }

  /// Create a new conversation via Rust backend
  Future<ConversationModel?> createConversation({
    required List<String> participantIds,
    String? name,
    bool isGroup = false,
  }) async {
    try {
      // TODO: Replace with actual user id from auth/session
      final userId = getCurrentUserId() ?? 'user1';
      // Add current user to participants
      final allParticipants = [...participantIds, userId];

      // Call Rust backend
      final response = await THttpHelper.post('conversations/create', {
        'name': name,
        'is_group': isGroup,
        'participants': allParticipants,
        'created_by': userId,
      });

      final conversation = ConversationModel.fromJson(response['conversation']);
      _conversations.insert(0, conversation);

      return conversation;
    } catch (e) {
      print('❌ Error creating conversation: $e');
      return null;
    }
  }

  // 🔍 Search and Utility Methods

  /// Search messages in current conversation
  void searchMessages(String query) {
    _searchQuery.value = query;
    _isSearching.value = query.isNotEmpty;

    // TODO: Implement actual search functionality
    // This would filter _currentMessages based on the query
  }

  /// Clear search and show all messages
  void clearSearch() {
    _searchQuery.value = '';
    _isSearching.value = false;
  }

  // 🔧 Helper Methods

  /// Mark a specific message as read
  Future<void> _markMessageAsRead(String messageId) async {
    try {
      // TODO: Replace with actual user id from auth/session
      final userId = getCurrentUserId() ?? 'user1';
      await THttpHelper.post('messages/read', {
        'message_id': messageId,
        'user_id': userId,
      });
    } catch (e) {
      print('❌ Error marking message as read: $e');
    }
  }

  /// Mark entire conversation as read
  Future<void> _markConversationAsRead(String conversationId) async {
    try {
      final userId = getCurrentUserId() ?? 'user1';
      // Mark all unread messages in this conversation as read
      final unreadMessages = _currentMessages
          .where((m) => m.senderId != userId)
          .where((m) => m.status != MessageStatus.read);

      for (final message in unreadMessages) {
        await _markMessageAsRead(message.id);
      }
    } catch (e) {
      print('❌ Error marking conversation as read: $e');
    }
  }

  /// Update conversation with new last message
  void _updateConversationLastMessage(MessageModel message) {
    final index = _conversations.indexWhere(
      (c) => c.id == message.conversationId,
    );

    if (index != -1) {
      final conversation = _conversations[index];
      _conversations[index] = conversation.copyWith(
        lastMessage: message,
        updatedAt: message.timestamp,
      );

      _sortConversations();
    }
  }

  /// Sort conversations by last message timestamp
  void _sortConversations() {
    _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Show notification for new message
  void _showMessageNotification(MessageModel message) {
    // Only show if message is not from current user
    if (message.senderId == getCurrentUserId()) return;

    // Only show if conversation is not currently active
    if (message.conversationId == _activeConversation.value?.id) return;

    // TODO: Implement actual notification logic
    // For now, we'll just print to console
    print('New message: ${message.text} from ${message.senderId}');
  }

  /// Cache current data to local storage
  void _cacheCurrentData() {
    try {
      _storage.write('cached_conversations',
          _conversations.map((c) => c.toJson()).toList());
    } catch (e) {
      print('❌ Error caching data: $e');
    }
  }

  /// Cleanup realtime subscriptions
  // TODO: Implement real-time channel cleanup
  void _cleanupSubscriptions() {
    // _messagesChannel?.unsubscribe();
    // _conversationsChannel?.unsubscribe();
    // _typingChannel?.unsubscribe();
  }
}
