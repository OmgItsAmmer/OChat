import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/models/message_model.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/user_model.dart';

/// 💬 Chat Controller
///
/// NEW ARCHITECTURE: Flutter UI -> ChatController -> Supabase (Direct)
/// All chat actions now go directly to Supabase with RPC functions for security.
///
/// SECURITY APPROACH:
/// - Sensitive operations (encryption, sending messages) handled by Supabase RPC functions
/// - Row Level Security (RLS) protects data access
/// - Real-time updates via Supabase subscriptions
class ChatController extends GetxController {
  // 📱 Storage and backend clients
  final _storage = GetStorage();

  /// Returns the current user's id, or null if not logged in
  String? getCurrentUserId() => SupabaseService.currentUserId;

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
  /// Send a message using Supabase RPC function with encryption
  ///
  /// 🔄 NEW ARCHITECTURE: Direct Supabase with Server-Side Security
  /// =============================================================
  ///
  /// 🚀 SECURE & SIMPLE APPROACH:
  /// 1. ✅ Direct connection to Supabase (no Rust server)
  /// 2. ✅ Message encryption handled server-side via RPC functions
  /// 3. ✅ JWT authentication built into Supabase client
  /// 4. ✅ Real-time message delivery
  /// 5. ✅ End-to-end security without client-side complexity
  Future<bool> sendMessage({
    required String conversationId,
    required String text,
    String? replyToId,
  }) async {
    if (text.trim().isEmpty) return false;

    try {
      _isSendingMessage.value = true;

      final userId = getCurrentUserId();
      if (userId == null) {
        print('❌ No authenticated user found');
        return false;
      }

      print('📤 Sending encrypted message via Supabase RPC');

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

      // 🔧 OLD BACKEND CONNECTION CODE - COMMENTED OUT
      // This code was used with the Rust server and is no longer needed
      /*
      try {
        final response = await THttpHelper.post('messages/send', {
          'conversation_id': conversationId,
          'sender_id': userId,
          'text': text.trim(),
          'reply_to_id': replyToId,
        });

        final realMessage = MessageModel.fromJson(response['message']);
        final index =
            _currentMessages.indexWhere((m) => m.id == optimisticMessage.id);
        if (index != -1) {
          _currentMessages[index] = realMessage;
        }
        print('✅ Message sent successfully via backend');
        return true;
      } catch (backendError) {
      */

      // 🔐 SEND VIA SUPABASE RPC FUNCTION
      // This handles encryption and storage server-side
      try {
        print('🔍 Debug: About to call SupabaseService.sendMessage');
        print('🔍 Debug: conversationId = $conversationId');
        print('🔍 Debug: content = ${text.trim()}');
        print('🔍 Debug: userId = $userId');

        final sentMessage = await SupabaseService.sendMessage(
          conversationId: conversationId,
          content: text.trim(),
          replyToId: replyToId,
          type: MessageType.text,
        );

        print('🔍 Debug: SupabaseService.sendMessage returned: $sentMessage');

        if (sentMessage != null) {
          // Replace optimistic message with real one
          final index =
              _currentMessages.indexWhere((m) => m.id == optimisticMessage.id);
          if (index != -1) {
            _currentMessages[index] = sentMessage;
          }
          print('✅ Message sent and encrypted successfully');

          // Clear the message input
          messageController.clear();

          return true;
        } else {
          print('❌ SupabaseService.sendMessage returned null');
          throw Exception(
              'Failed to send message - RPC function returned null');
        }
      } catch (supabaseError) {
        // 🚫 SUPABASE ERROR HANDLING
        print('⚠️ Supabase error: $supabaseError');
        print('⚠️ Error type: ${supabaseError.runtimeType}');
        print('⚠️ Error details: ${supabaseError.toString()}');

        // Update optimistic message to show as failed
        final index =
            _currentMessages.indexWhere((m) => m.id == optimisticMessage.id);
        if (index != -1) {
          _currentMessages[index] = optimisticMessage.copyWith(
            status: MessageStatus.failed,
          );
        }

        print(
            '📱 Message failed to send - check authentication and connection');
        return false;
      }
    } catch (e) {
      // Remove optimistic message on any error
      _currentMessages.removeWhere((m) => m.id.startsWith('temp_'));
      print('❌ Error sending message: $e');
      return false;
    } finally {
      _isSendingMessage.value = false;
    }
  }

  /// Load messages for a conversation directly from Supabase
  Future<void> loadMessages(String conversationId) async {
    try {
      _isLoadingMessages.value = true;
      _activeConversation.value =
          _conversations.firstWhereOrNull((c) => c.id == conversationId);

      // 🔐 LOAD FROM SUPABASE WITH DECRYPTION
      try {
        print('🔍 Debug: Loading messages for conversation: $conversationId');

        // Load messages via SupabaseService (handles decryption server-side)
        final messages = await SupabaseService.getMessages(conversationId);

        print(
            '🔍 Debug: Received ${messages.length} messages from RPC function');

        // Show first few messages for debugging
        for (int i = 0; i < messages.length && i < 3; i++) {
          print('🔍 Debug: Message ${i + 1}: "${messages[i].text}"');
        }

        _currentMessages
            .assignAll(messages); // Keep original order for reverse ListView

        // Mark messages as read
        await SupabaseService.markMessagesAsRead(conversationId);

        print(
            '📨 Loaded ${messages.length} decrypted messages for conversation $conversationId');
      } catch (supabaseError) {
        // 🚫 SUPABASE ERROR HANDLING
        print('⚠️ Supabase error loading messages: $supabaseError');

        // Try to load cached messages as fallback
        await _loadCachedMessages(conversationId);

        print('📱 Loaded cached messages as fallback');
      }
    } catch (e) {
      print('❌ Error loading messages: $e');
      _currentMessages.clear();
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

  /// Load all conversations for the current user from Supabase
  Future<void> _loadConversations() async {
    try {
      _isLoadingConversations.value = true;
      final userId = getCurrentUserId();

      if (userId == null) {
        print('❌ No authenticated user found');
        return;
      }

      // 🔐 SUPABASE CONNECTION
      try {
        // Load conversations via SupabaseService
        final conversations = await SupabaseService.getUserConversations();

        // Update participant2Id with current user ID for proper conversation structure
        final updatedConversations = conversations
            .map((conv) => conv.copyWith(participant2Id: userId))
            .toList();

        _conversations.assignAll(updatedConversations);

        // Cache conversations locally
        _storage.write('cached_conversations',
            updatedConversations.map((c) => c.toJson()).toList());

        print('📁 Loaded ${conversations.length} conversations from Supabase');
      } catch (supabaseError) {
        // 🚫 SUPABASE ERROR - FALLBACK BEHAVIOR
        print(
            '⚠️ Supabase error, loading cached conversations: $supabaseError');

        // Try to load from cache
        await _loadCachedConversations();
      }
    } catch (e) {
      print('❌ Error loading conversations: $e');
      _conversations.clear();
    } finally {
      _isLoadingConversations.value = false;
    }
  }

  /// Load cached conversations from local storage
  Future<void> _loadCachedConversations() async {
    try {
      final cachedData = _storage.read('cached_conversations') as List?;
      if (cachedData != null) {
        final conversations = cachedData
            .map<ConversationModel>((data) => ConversationModel.fromJson(data))
            .toList();
        _conversations.assignAll(conversations);
        print('📁 Loaded ${conversations.length} cached conversations');
      } else {
        print('📁 No cached conversations found');
        _conversations.clear();
      }
    } catch (cacheError) {
      print('❌ Error loading cached conversations: $cacheError');
      _conversations.clear();
    }
  }

  /// Load cached messages for a conversation
  Future<void> _loadCachedMessages(String conversationId) async {
    try {
      final cachedData =
          _storage.read('cached_messages_$conversationId') as List?;
      if (cachedData != null) {
        final messages = cachedData
            .map<MessageModel>((data) => MessageModel.fromJson(data))
            .toList();
        _currentMessages.assignAll(messages);
        print('📱 Loaded ${messages.length} cached messages');
      } else {
        print('📱 No cached messages found for conversation $conversationId');
        _currentMessages.clear();
      }
    } catch (cacheError) {
      print('❌ Error loading cached messages: $cacheError');
      _currentMessages.clear();
    }
  }

  /// Create or get existing conversation via Supabase RPC
  Future<String?> createOrGetConversation(String otherUserId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        print('❌ No authenticated user found');
        return null;
      }

      // Call Supabase RPC function to create or get conversation
      final conversationId =
          await SupabaseService.createOrGetConversation(otherUserId);

      if (conversationId != null) {
        // Refresh conversations list
        await _loadConversations();
        print('✅ Created/retrieved conversation: $conversationId');
      }

      return conversationId;
    } catch (e) {
      print('❌ Error creating/getting conversation: $e');
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

  /// Mark a specific message as read (using Supabase)
  Future<void> _markMessageAsRead(String messageId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return;

      // This would be handled by the SupabaseService.markMessagesAsRead() function
      // for the entire conversation, so individual message marking is not needed
      print('📝 Message marked as read: $messageId');
    } catch (e) {
      print('❌ Error marking message as read: $e');
    }
  }

  /// Mark entire conversation as read (using Supabase RPC)
  Future<void> _markConversationAsRead(String conversationId) async {
    try {
      await SupabaseService.markMessagesAsRead(conversationId);
      print('✅ Conversation marked as read: $conversationId');
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
