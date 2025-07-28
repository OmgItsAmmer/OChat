// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:get_storage/get_storage.dart';

// import '../../../core/utils/constants/api_constants.dart';
// import '../../../core/utils/constants/storage_keys.dart';
// import '../data/models/user_model.dart';
// import '../data/models/message_model.dart';
// import '../data/models/conversation_model.dart';

// /// API Service for communicating with the Rust backend
// /// This service handles all HTTP requests and provides a clean interface
// /// for the controllers to interact with the backend
// class ApiService {
//   // Singleton pattern - ensures only one instance of ApiService exists
//   // This is a common pattern for services that manage external resources
//   static final ApiService _instance = ApiService._internal();
//   factory ApiService() => _instance;
//   ApiService._internal();

//   // GetStorage instance for accessing stored tokens
//   final _storage = GetStorage();

//   /// Get the authorization headers with the current JWT token
//   /// This is used for authenticated requests to the backend
//   Map<String, String> get _authHeaders {
//     final token = _storage.read(StorageKeys.authToken);
//     return {
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       if (token != null) 'Authorization': 'Bearer $token',
//     };
//   }

//   /// Generic method to handle HTTP requests with error handling
//   /// This centralizes error handling and response parsing
//   Future<Map<String, dynamic>> _makeRequest(
//     String method,
//     String endpoint, {
//     Map<String, dynamic>? body,
//     Map<String, String>? additionalHeaders,
//   }) async {
//     try {
//       final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
//       final headers = {..._authHeaders, ...?additionalHeaders};

//       http.Response response;

//       // Choose HTTP method based on parameter
//       switch (method.toUpperCase()) {
//         case 'GET':
//           response = await http.get(url, headers: headers);
//           break;
//         case 'POST':
//           response = await http.post(
//             url,
//             headers: headers,
//             body: body != null ? jsonEncode(body) : null,
//           );
//           break;
//         case 'PUT':
//           response = await http.put(
//             url,
//             headers: headers,
//             body: body != null ? jsonEncode(body) : null,
//           );
//           break;
//         case 'DELETE':
//           response = await http.delete(url, headers: headers);
//           break;
//         default:
//           throw Exception('Unsupported HTTP method: $method');
//       }

//       // Parse response based on status code
//       final responseData = response.body.isNotEmpty
//           ? jsonDecode(response.body) as Map<String, dynamic>
//           : <String, dynamic>{};

//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         return responseData;
//       } else {
//         // Handle error responses from the backend
//         final errorMessage = responseData['error'] ??
//             responseData['message'] ??
//             'Request failed with status ${response.statusCode}';
//         throw ApiException(errorMessage, response.statusCode);
//       }
//     } on SocketException {
//       throw ApiException('No internet connection', 0);
//     } on FormatException {
//       throw ApiException('Invalid response format', 0);
//     } catch (e) {
//       if (e is ApiException) rethrow;
//       throw ApiException('Request failed: $e', 0);
//     }
//   }

//   // Authentication Methods

//   /// Login with email and password
//   /// Returns user data and tokens on success
//   Future<Map<String, dynamic>> login(String email, String password) async {
//     final response =
//         await _makeRequest('POST', ApiConstants.loginEndpoint, body: {
//       'email': email,
//       'password': password,
//     });

//     // Store tokens for future requests
//     if (response['access_token'] != null) {
//       await _storage.write(StorageKeys.authToken, response['access_token']);
//     }
//     if (response['refresh_token'] != null) {
//       await _storage.write(StorageKeys.refreshToken, response['refresh_token']);
//     }

//     return response;
//   }

//   /// Register a new user account
//   /// Returns user data and tokens on success
//   Future<Map<String, dynamic>> signup(
//       String email, String password, String? name) async {
//     final response =
//         await _makeRequest('POST', ApiConstants.signupEndpoint, body: {
//       'email': email,
//       'password': password,
//       if (name != null) 'name': name,
//     });

//     // Store tokens for future requests
//     if (response['access_token'] != null) {
//       await _storage.write(StorageKeys.authToken, response['access_token']);
//     }
//     if (response['refresh_token'] != null) {
//       await _storage.write(StorageKeys.refreshToken, response['refresh_token']);
//     }

//     return response;
//   }

//   /// Refresh the access token using the refresh token
//   Future<Map<String, dynamic>> refreshToken() async {
//     final refreshToken = _storage.read(StorageKeys.refreshToken);
//     if (refreshToken == null) {
//       throw ApiException('No refresh token available', 401);
//     }

//     final response =
//         await _makeRequest('POST', ApiConstants.refreshTokenEndpoint, body: {
//       'refresh_token': refreshToken,
//     });

//     // Update stored access token
//     if (response['access_token'] != null) {
//       await _storage.write(StorageKeys.authToken, response['access_token']);
//     }

//     return response;
//   }

//   /// Logout the current user
//   Future<void> logout() async {
//     try {
//       await _makeRequest('POST', ApiConstants.logoutEndpoint);
//     } catch (e) {
//       // Even if logout fails on server, clear local tokens
//       print('Logout request failed: $e');
//     } finally {
//       // Clear all stored auth data
//       await _storage.remove(StorageKeys.authToken);
//       await _storage.remove(StorageKeys.refreshToken);
//       await _storage.remove(StorageKeys.userId);
//       await _storage.remove(StorageKeys.userEmail);
//       await _storage.remove(StorageKeys.userName);
//     }
//   }

//   // Message Methods

//   /// Send a new message
//   /// Returns the created message
//   Future<MessageModel> sendMessage(
//       String receiverId, String content, MessageType type) async {
//     final response =
//         await _makeRequest('POST', ApiConstants.messagesEndpoint, body: {
//       'receiver_id': receiverId,
//       'content': content,
//       'message_type': _messageTypeToString(type),
//     });

//     return MessageModel.fromJson(response);
//   }

//   /// Get conversation history between current user and another user
//   /// Returns list of messages with pagination
//   Future<List<MessageModel>> getConversationHistory(String otherUserId,
//       {int page = 1}) async {
//     final response = await _makeRequest('GET',
//         '${ApiConstants.messagesEndpoint}/conversation/$otherUserId?page=$page&limit=${ApiConstants.messagesPerPage}');

//     final messagesJson = response['messages'] as List<dynamic>;
//     return messagesJson
//         .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
//         .toList();
//   }

//   /// Mark messages as read
//   Future<void> markMessagesAsRead(String conversationId) async {
//     await _makeRequest(
//         'POST', '${ApiConstants.markReadEndpoint}/$conversationId');
//   }

//   /// Search messages
//   Future<List<MessageModel>> searchMessages(String query,
//       {int page = 1}) async {
//     final response = await _makeRequest('GET',
//         '${ApiConstants.searchMessagesEndpoint}?q=$query&page=$page&limit=${ApiConstants.messagesPerPage}');

//     final messagesJson = response['messages'] as List<dynamic>;
//     return messagesJson
//         .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
//         .toList();
//   }

//   // Conversation Methods

//   /// Get all conversations for the current user
//   Future<List<ConversationModel>> getConversations() async {
//     final response =
//         await _makeRequest('GET', ApiConstants.conversationsEndpoint);

//     final conversationsJson = response['conversations'] as List<dynamic>;
//     return conversationsJson
//         .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
//         .toList();
//   }

//   /// Create a new conversation or get existing one
//   Future<ConversationModel> createOrGetConversation(String otherUserId) async {
//     final response =
//         await _makeRequest('POST', ApiConstants.conversationsEndpoint, body: {
//       'other_user_id': otherUserId,
//     });

//     return ConversationModel.fromJson(response);
//   }

//   // User Methods

//   /// Get current user profile
//   Future<UserModel> getCurrentUser() async {
//     final response =
//         await _makeRequest('GET', ApiConstants.userProfileEndpoint);
//     return UserModel.fromJson(response);
//   }

//   /// Update user profile
//   Future<UserModel> updateProfile(Map<String, dynamic> updates) async {
//     final response = await _makeRequest(
//         'PUT', ApiConstants.updateProfileEndpoint,
//         body: updates);
//     return UserModel.fromJson(response);
//   }

//   /// Get user statistics (message count, conversation count, etc.)
//   Future<Map<String, dynamic>> getUserStats() async {
//     return await _makeRequest('GET', ApiConstants.userStatsEndpoint);
//   }

//   /// Search for users (for starting new conversations)
//   Future<List<UserModel>> searchUsers(String query) async {
//     final response = await _makeRequest('GET', '/users/search?q=$query');

//     final usersJson = response['users'] as List<dynamic>;
//     return usersJson
//         .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
//         .toList();
//   }

//   // Utility Methods

//   /// Check if the backend is healthy
//   Future<bool> checkHealth() async {
//     try {
//       await _makeRequest('GET', ApiConstants.healthEndpoint);
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }

//   /// Helper method to convert MessageType enum to string
//   String _messageTypeToString(MessageType type) {
//     switch (type) {
//       case MessageType.text:
//         return 'text';
//       case MessageType.image:
//         return 'image';
//       case MessageType.file:
//         return 'file';
//       case MessageType.system:
//         return 'system';
//       default:
//         return 'text';
//     }
//   }
// }

// /// Custom exception class for API errors
// /// This provides structured error handling throughout the app
// class ApiException implements Exception {
//   final String message;
//   final int statusCode;

//   const ApiException(this.message, this.statusCode);

//   @override
//   String toString() => 'ApiException: $message (Status: $statusCode)';

//   /// Check if this is an authentication error
//   bool get isAuthError => statusCode == 401 || statusCode == 403;

//   /// Check if this is a network error
//   bool get isNetworkError => statusCode == 0;

//   /// Check if this is a server error
//   bool get isServerError => statusCode >= 500;

//   /// Check if this is a client error (bad request, validation, etc.)
//   bool get isClientError => statusCode >= 400 && statusCode < 500;
// }
