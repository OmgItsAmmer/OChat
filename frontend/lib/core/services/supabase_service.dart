import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/chat/data/models/user_model.dart';
import '../../features/chat/data/models/message_model.dart';
import '../../features/chat/data/models/conversation_model.dart';

/// 🔐 Supabase Service - Direct Connection
///
/// This service handles all direct communication with Supabase,
/// replacing the previous Rust server architecture.
///
/// SECURITY APPROACH:
/// - All sensitive operations go through Supabase RPC functions
/// - RLS (Row Level Security) policies protect data access
/// - JWT tokens authenticate all requests
///
/// ARCHITECTURE CHANGE:
/// OLD: Flutter -> Rust Server -> Supabase
/// NEW: Flutter -> Supabase (with RPC functions for security)
class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Get current authenticated user ID
  static String? get currentUserId => _client.auth.currentUser?.id;

  /// Check if user is authenticated
  static bool get isAuthenticated => _client.auth.currentUser != null;

  // ================================
  // 👥 USER OPERATIONS
  // ================================

  /// Fetch all users from the users table
  ///
  /// SECURITY: Uses RLS to ensure only authenticated users can see user list
  /// DIRECT SUPABASE: No longer goes through Rust server
  static Future<List<UserModel>> fetchUsers() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print('🌐 Fetching users directly from Supabase');
        print('🔑 User ID: $currentUserId');
      }

      // Direct query to Supabase users table
      final response = await _client
          .from('users')
          .select('*')
          .order('created_at', ascending: false);

      final usersList = (response as List<dynamic>)
          .map((userData) => UserModel.fromSupabaseJson(userData))
          .toList();

      if (kDebugMode) {
        print('✅ Successfully fetched ${usersList.length} users from Supabase');
      }

      return usersList;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching users from Supabase: $e');
      }
      rethrow;
    }
  }

  /// Get user by ID
  static Future<UserModel?> getUserById(String userId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('users')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      return UserModel.fromSupabaseJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching user by ID: $e');
      }
      return null;
    }
  }

  /// Update user online status
  static Future<void> updateUserOnlineStatus(bool isOnline) async {
    try {
      if (!isAuthenticated || currentUserId == null) return;

      await _client.from('users').update({
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', currentUserId!);

      if (kDebugMode) {
        print('✅ Updated online status: $isOnline');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating online status: $e');
      }
    }
  }

  // ================================
  // 💬 CONVERSATION OPERATIONS
  // ================================

  /// Get user conversations
  ///
  /// SECURITY: Uses Supabase view with RLS to ensure users only see their conversations
  static Future<List<ConversationModel>> getUserConversations() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Use the user_conversations view from your schema
      final response = await _client
          .from('user_conversations')
          .select('*')
          .order('last_message_at', ascending: false);

      final conversations = (response as List<dynamic>)
          .map((data) => ConversationModel.fromSupabaseJson(data))
          .toList();

      if (kDebugMode) {
        print('✅ Fetched ${conversations.length} conversations');
      }

      return conversations;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching conversations: $e');
      }
      rethrow;
    }
  }

  /// Create or get existing conversation between two users
  ///
  /// SECURITY: Uses RPC function to handle conversation creation securely
  static Future<String?> createOrGetConversation(String otherUserId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Call RPC function to handle conversation creation/retrieval
      final response = await _client.rpc('create_or_get_conversation', params: {
        'other_user_id': otherUserId,
      });

      if (response != null && response['conversation_id'] != null) {
        return response['conversation_id'] as String;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating/getting conversation: $e');
      }
      return null;
    }
  }

  // ================================
  // 📨 MESSAGE OPERATIONS
  // ================================

  /// Get decrypted messages for a conversation using RPC function
  ///
  /// SECURITY: RPC function handles decryption server-side
  static Future<List<MessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print(
            '📨 Fetching decrypted messages for conversation: $conversationId');
      }

      // Call RPC function to get decrypted messages
      final response = await _client.rpc('get_conversation_messages', params: {
        'p_conversation_id': conversationId,
        'p_limit': limit,
        'p_offset': offset,
      });

      if (kDebugMode) {
        print('🔍 RPC response: $response');
      }

      if (response != null && response is List) {
        final messages = (response as List<dynamic>)
            .map((data) => MessageModel.fromSupabaseJson(data))
            .toList();

        if (kDebugMode) {
          print(
              '✅ Fetched ${messages.length} decrypted messages for conversation $conversationId');
        }

        return messages;
      } else {
        if (kDebugMode) {
          print('❌ RPC function returned invalid response: $response');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching decrypted messages: $e');
        print('❌ Error type: ${e.runtimeType}');
        print('❌ Error details: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Send encrypted message using Supabase RPC function
  ///
  /// SECURITY: All message encryption and storage handled server-side
  /// This ensures message content is never exposed in client-side code
  static Future<MessageModel?> sendMessage({
    required String conversationId,
    required String content,
    String? replyToId,
    MessageType type = MessageType.text,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print('📤 Sending message via Supabase RPC function');
        print('🔐 Content will be encrypted server-side');
        print('🔍 Debug: conversationId = $conversationId');
        print('🔍 Debug: content = $content');
        print('🔍 Debug: type = ${type.toString().split('.').last}');
        print('🔍 Debug: currentUserId = $currentUserId');
      }

      // Call secure RPC function that handles encryption and storage
      final response = await _client.rpc('send_encrypted_message', params: {
        'p_conversation_id': conversationId,
        'p_content': content,
        'p_message_type': type.toString().split('.').last,
        'p_reply_to_id': replyToId,
      });

      if (kDebugMode) {
        print('🔍 Debug: RPC response = $response');
      }

      if (response != null && response['success'] == true) {
        // Return the created message
        final message = MessageModel.fromSupabaseJson(response['message']);
        if (kDebugMode) {
          print('✅ Message created successfully: ${message.id}');
        }
        return message;
      }

      if (kDebugMode) {
        print('❌ RPC function returned null or success=false');
        print('❌ Response: $response');
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending message: $e');
        print('❌ Error type: ${e.runtimeType}');
        print('❌ Error details: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Mark messages as read
  ///
  /// SECURITY: Uses RPC function to ensure proper access control
  static Future<void> markMessagesAsRead(String conversationId) async {
    try {
      if (!isAuthenticated || currentUserId == null) return;

      await _client.rpc('mark_messages_as_read', params: {
        'p_conversation_id': conversationId,
      });

      if (kDebugMode) {
        print('✅ Marked messages as read for conversation: $conversationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking messages as read: $e');
      }
    }
  }

  // ================================
  // 🔐 ENCRYPTION OPERATIONS
  // ================================

  /// Initialize encryption keys for the current user
  ///
  /// SECURITY: Called once per user to set up end-to-end encryption
  static Future<bool> initializeUserEncryption() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final response = await _client.rpc('initialize_user_encryption');

      if (response != null && response['success'] == true) {
        if (kDebugMode) {
          print('✅ User encryption initialized successfully');
        }
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing user encryption: $e');
      }
      return false;
    }
  }

  // ================================
  // 🔄 REALTIME SUBSCRIPTIONS
  // ================================

  /// Subscribe to real-time message updates
  static RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(MessageModel) onNewMessage,
  ) {
    return _client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_key_id',
            value: conversationId,
          ),
          callback: (payload) {
            try {
              final messageData = payload.newRecord;
              if (messageData != null) {
                final message = MessageModel.fromSupabaseJson(messageData);
                onNewMessage(message);
              }
            } catch (e) {
              if (kDebugMode) {
                print('❌ Error processing real-time message: $e');
              }
            }
          },
        )
        .subscribe();
  }

  /// Subscribe to user online status updates
  static RealtimeChannel subscribeToUserStatus(
    void Function(UserModel) onUserStatusChange,
  ) {
    return _client
        .channel('user_status')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          callback: (payload) {
            try {
              final userData = payload.newRecord;
              if (userData != null) {
                final user = UserModel.fromSupabaseJson(userData);
                onUserStatusChange(user);
              }
            } catch (e) {
              if (kDebugMode) {
                print('❌ Error processing user status update: $e');
              }
            }
          },
        )
        .subscribe();
  }

  // ================================
  // 🧹 CLEANUP
  // ================================

  /// Unsubscribe from a realtime channel
  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }

  /// Clean up all subscriptions
  static Future<void> cleanup() async {
    await _client.removeAllChannels();
  }

  /// Test if RPC functions are available
  static Future<bool> testRpcFunctions() async {
    try {
      if (!isAuthenticated) {
        print('❌ User not authenticated for RPC test');
        return false;
      }

      print('🔍 Testing RPC function availability...');

      // Test a simple RPC call
      final response = await _client.rpc('initialize_user_encryption');

      print('✅ RPC functions are available');
      print('🔍 Test response: $response');

      return true;
    } catch (e) {
      print('❌ RPC functions test failed: $e');
      print('💡 Make sure to deploy the RPC functions to Supabase first!');
      print(
          '📋 Copy lib/supabase/functions/rpc_functions.sql to Supabase Dashboard → SQL Editor');
      return false;
    }
  }

  /// Test message functionality
  static Future<bool> testMessageFunctions() async {
    try {
      if (!isAuthenticated) {
        print('❌ User not authenticated for message test');
        return false;
      }

      print('📨 Testing message functionality...');

      // Create a test conversation
      final testUserId = 'test-user-id'; // Replace with actual test user ID
      final conversationResponse =
          await _client.rpc('create_or_get_conversation', params: {
        'other_user_id': testUserId,
      });

      if (conversationResponse != null &&
          conversationResponse['success'] == true) {
        final conversationId = conversationResponse['conversation_id'];
        print('✅ Test conversation created: $conversationId');

        // Send a test message
        final testMessage = 'Hello, this is a test message!';
        final sendResponse =
            await _client.rpc('send_encrypted_message', params: {
          'p_conversation_id': conversationId,
          'p_content': testMessage,
          'p_message_type': 'text',
        });

        if (sendResponse != null && sendResponse['success'] == true) {
          print('✅ Test message sent successfully');

          // Try to retrieve the message
          final messagesResponse =
              await _client.rpc('get_conversation_messages', params: {
            'p_conversation_id': conversationId,
            'p_limit': 1,
            'p_offset': 0,
          });

          if (messagesResponse != null &&
              messagesResponse is List &&
              messagesResponse.isNotEmpty) {
            final retrievedMessage = messagesResponse[0]['encrypted_content'];
            print('🔍 Retrieved message: "$retrievedMessage"');
            print('🔍 Original message: "$testMessage"');

            if (retrievedMessage == testMessage) {
              print('✅ Message test PASSED!');
              return true;
            } else {
              print('❌ Message test FAILED - messages don\'t match');
              return false;
            }
          } else {
            print('❌ Failed to retrieve messages');
            return false;
          }
        } else {
          print('❌ Failed to send test message');
          return false;
        }
      } else {
        print('❌ Failed to create test conversation');
        return false;
      }
    } catch (e) {
      print('❌ Message test failed: $e');
      return false;
    }
  }
}
