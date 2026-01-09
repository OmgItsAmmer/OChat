import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../core/routes/o_routes.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../chat/data/models/user_model.dart';

/// 🏠 Home Controller
///
/// This controller manages the home screen state and functionality.
/// It handles fetching users from the backend and managing the chat list.
///
/// FLUTTER + RUST INTEGRATION:
/// 1. Gets JWT token from AuthController (Supabase auth)
/// 2. Sends request to Rust backend with JWT token
/// 3. Rust backend verifies JWT and fetches users from Supabase
/// 4. Flutter receives user list and displays in UI
///
/// GETX PATTERN:
/// - Reactive state management with .obs variables
/// - Automatic UI updates when state changes
/// - Dependency injection for easy access across app
class HomeController extends GetxController {
  // 📱 Storage for caching data
  final _storage = GetStorage();

  // 🔗 Dependencies - GetX will inject these automatically
  // Note: AuthController dependency removed as we now use SupabaseService directly

  // 🎯 Reactive State Variables

  /// List of all users (potential chat partners)
  final RxList<UserModel> _users = <UserModel>[].obs;
  List<UserModel> get users => _users;

  /// Loading state for fetching users
  final _isLoadingUsers = false.obs;
  bool get isLoadingUsers => _isLoadingUsers.value;

  /// Error message if fetching users fails
  final _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  /// Search query for filtering users
  final _searchQuery = ''.obs;
  String get searchQuery => _searchQuery.value;

  /// Filtered users based on search query
  List<UserModel> get filteredUsers {
    if (_searchQuery.value.isEmpty) {
      return _users;
    }

    return _users.where((user) {
      final query = _searchQuery.value.toLowerCase();
      return user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList();
  }

  // 🎬 Lifecycle Methods

  @override
  void onInit() {
    super.onInit();

    // 🔗 DEPENDENCIES SIMPLIFIED
    // Using SupabaseService directly - no need for AuthController injection

    // 📊 LOAD INITIAL DATA
    // Fetch users when controller is initialized
    fetchUsers();

    // 🔍 TEST RPC FUNCTIONS (for debugging)
    if (kDebugMode) {
      SupabaseService.testRpcFunctions();
    }
  }

  @override
  void onReady() {
    super.onReady();

    // 🔄 SETUP REFRESH TIMER
    // Optionally refresh user list periodically
    // _setupPeriodicRefresh();
  }

  @override
  void onClose() {
    // 🧹 CLEANUP
    // Cancel any timers or subscriptions
    super.onClose();
  }

  // 👥 USER MANAGEMENT METHODS

  /// Fetch all users directly from Supabase
  ///
  /// 🔄 NEW ARCHITECTURE: Direct Supabase Connection
  /// ===============================================
  ///
  /// 🚀 SIMPLIFIED & SECURE APPROACH:
  /// 1. ✅ Direct connection to Supabase (no Rust server needed)
  /// 2. ✅ JWT authentication handled automatically by Supabase
  /// 3. ✅ Row Level Security (RLS) protects data access
  /// 4. ✅ Real-time capabilities built-in
  /// 5. ✅ Reduced latency (fewer network hops)
  Future<void> fetchUsers() async {
    try {
      _isLoadingUsers.value = true;
      _errorMessage.value = '';

      if (kDebugMode) {
        print('🌐 Fetching users directly from Supabase');
        print('🔑 Using authenticated session');
      }

      // 🌐 DIRECT SUPABASE CALL
      // Using new SupabaseService with automatic authentication
      final usersList = await SupabaseService.fetchUsers();

      // 📊 UPDATE STATE
      _users.assignAll(usersList);

      // 💾 CACHE DATA
      await _cacheUsers(usersList);

      if (kDebugMode) {
        print('✅ Successfully fetched ${usersList.length} users from Supabase');
        print('🎯 Direct Supabase connection working perfectly!');
      }
    } catch (e) {
      // 🚫 HANDLE ERRORS
      _errorMessage.value = 'Failed to load users: ${e.toString()}';

      // 📱 TRY TO LOAD CACHED DATA
      await _loadCachedUsers();

      if (kDebugMode) {
        print('❌ Error fetching users from Supabase: $e');
        print('🔧 Check:');
        print('   1. Is the user authenticated?');
        print('   2. Are RLS policies configured correctly?');
        print('   3. Is the Supabase connection working?');
      }
    } finally {
      _isLoadingUsers.value = false;
    }
  }

  /// Cache users locally for offline access
  Future<void> _cacheUsers(List<UserModel> users) async {
    try {
      final usersJson = users.map((user) => user.toJson()).toList();
      await _storage.write('cached_users', usersJson);
      await _storage.write(
          'users_cache_timestamp', DateTime.now().toIso8601String());

      if (kDebugMode) {
        print('💾 Cached ${users.length} users locally');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error caching users: $e');
      }
    }
  }

  /// Load cached users from local storage
  Future<void> _loadCachedUsers() async {
    try {
      final cachedData = _storage.read('cached_users');
      if (cachedData != null) {
        final usersList = (cachedData as List<dynamic>)
            .map((userData) =>
                UserModel.fromJson(userData as Map<String, dynamic>))
            .toList();

        _users.assignAll(usersList);

        if (kDebugMode) {
          print('📱 Loaded ${usersList.length} cached users');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading cached users: $e');
      }
    }
  }

  // 🔍 SEARCH AND FILTER METHODS

  /// Update search query and filter users
  void updateSearchQuery(String query) {
    _searchQuery.value = query;
  }

  /// Clear search and show all users
  void clearSearch() {
    _searchQuery.value = '';
  }

  // 💬 CHAT ACTIONS

  /// Start a chat with a specific user using Supabase
  ///
  /// NAVIGATION: Create/get conversation and navigate to chat screen
  Future<void> startChatWithUser(UserModel user) async {
    try {
      if (kDebugMode) {
        print('💬 Starting chat with user: ${user.displayName}');
      }

      // 🔐 CREATE OR GET CONVERSATION VIA SUPABASE
      final conversationId =
          await SupabaseService.createOrGetConversation(user.id);

      if (conversationId != null) {
        if (kDebugMode) {
          print('✅ Conversation ready: $conversationId');
        }

        // 🚀 NAVIGATE TO CHAT SCREEN
        // Pass the conversation ID and user data to the chat screen
        Get.toNamed(ORoutes.chatScreen, arguments: {
          'conversationId': conversationId,
          'otherUser': user,
        });

        // Show success feedback
        // Get.snackbar(
        //   'Chat Started',
        //   'Opening chat with ${user.displayName}',
        //   snackPosition: SnackPosition.BOTTOM,
        //   duration: const Duration(seconds: 2),
        // );
      } else {
        throw Exception('Failed to create conversation');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting chat: $e');
      }

      Get.snackbar(
        'Error',
        'Failed to start chat with ${user.displayName}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // 🔄 REFRESH METHODS

  /// Refresh user list
  Future<void> refreshUsers() async {
    await fetchUsers();
  }
}
