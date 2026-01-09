import 'dart:convert';
import 'package:http/http.dart' as http;

/// 🌐 HTTP CLIENT FOR RUST BACKEND COMMUNICATION
/// =============================================
///
/// ARCHITECTURE EXPLANATION (for beginners):
/// ==========================================
///
/// 🔄 **REQUEST FLOW:**
/// Flutter App → HTTP Client → Rust Backend → Supabase Database
///
/// 🛤️ **API PATH STRUCTURE:**
/// Base URL: https://your-ngrok-domain.ngrok-free.app
/// API Version: /api/v1
/// Feature Scope: /auth, /messages, /conversations
/// Endpoint: /ping, /login, /send, etc.
///
/// **COMPLETE PATH EXAMPLE:**
/// https://your-ngrok-domain.ngrok-free.app/api/v1/auth/ping
///
/// 🚨 **COMMON MISTAKE:** Forgetting the '/api/v1' prefix!
/// ❌ Wrong: https://domain.com/auth/ping (404 error)
/// ✅ Correct: https://domain.com/api/v1/auth/ping
class THttpHelper {
  // 🌐 BACKEND API CONFIGURATION
  // This points to the Rust backend server running through ngrok
  // The '/api/v1' prefix is REQUIRED for all endpoints!
  static const String _baseUrl = 'https://6a24ed62f72f.ngrok-free.app';
  static const String _apiVersion =
      '/api/v1'; // 🚨 CRITICAL: Don't forget this!

  /// 🔧 HELPER: Build complete API URL
  /// This ensures all requests include the correct /api/v1 prefix
  static String _buildUrl(String endpoint) {
    // Remove leading slash from endpoint if present to avoid double slashes
    final cleanEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$_baseUrl$_apiVersion/$cleanEndpoint';
  }

  // 📥 GET REQUEST - For fetching data
  // RUST CONCEPT: This corresponds to GET routes in your Rust backend
  // Examples: GET /api/v1/auth/ping, GET /api/v1/messages/conversation123
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final url = _buildUrl(endpoint);
    print('🌐 Making GET request to: $url'); // Debug logging for beginners

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        // 🔧 NGROK HEADERS: These headers are sometimes needed for ngrok
        'ngrok-skip-browser-warning': 'true', // Skip ngrok browser warning
      },
    );
    return _handleResponse(response, 'GET', url);
  }

  // 📥 AUTHENTICATED GET REQUEST - For fetching protected data
  // RUST CONCEPT: This hits endpoints protected by JWT middleware
  static Future<Map<String, dynamic>> getWithAuth(
      String endpoint, String accessToken) async {
    final url = _buildUrl(endpoint);
    print('🔐 Making authenticated GET request to: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer $accessToken', // JWT token for Rust auth middleware
        'ngrok-skip-browser-warning': 'true',
      },
    );
    return _handleResponse(response, 'GET (Auth)', url);
  }

  // 📤 POST REQUEST - For sending data
  // RUST CONCEPT: This corresponds to POST routes in your Rust backend
  // Examples: POST /api/v1/auth/login, POST /api/v1/messages/send
  static Future<Map<String, dynamic>> post(
      String endpoint, dynamic data) async {
    final url = _buildUrl(endpoint);
    print('📤 Making POST request to: $url');
    print('📦 Request data: ${json.encode(data)}'); // Debug logging

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: json.encode(data),
    );
    return _handleResponse(response, 'POST', url);
  }

  // 📤 AUTHENTICATED POST REQUEST - For sending data with JWT token
  // RUST CONCEPT: This hits endpoints protected by JWT middleware
  static Future<Map<String, dynamic>> postWithAuth(
      String endpoint, dynamic data, String accessToken) async {
    final url = _buildUrl(endpoint);
    print('🔐 Making authenticated POST request to: $url');
    print('📦 Request data: ${json.encode(data)}'); // Debug logging

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer $accessToken', // JWT token for Rust auth middleware
        'ngrok-skip-browser-warning': 'true',
      },
      body: json.encode(data),
    );
    return _handleResponse(response, 'POST (Auth)', url);
  }

  // 🔄 PUT REQUEST - For updating data
  static Future<Map<String, dynamic>> put(String endpoint, dynamic data) async {
    final url = _buildUrl(endpoint);
    print('🔄 Making PUT request to: $url');

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: json.encode(data),
    );
    return _handleResponse(response, 'PUT', url);
  }

  // 🗑️ DELETE REQUEST - For removing data
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final url = _buildUrl(endpoint);
    print('🗑️ Making DELETE request to: $url');

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    );
    return _handleResponse(response, 'DELETE', url);
  }

  // 🔍 RESPONSE HANDLER - Processes all HTTP responses
  // BEGINNER EXPLANATION: This function handles both success and error responses
  // It provides detailed error information to help with debugging
  static Map<String, dynamic> _handleResponse(
      http.Response response, String method, String url) {
    // 📊 LOG RESPONSE DETAILS (helpful for debugging)
    print('📊 $method Response from $url:');
    print('   Status: ${response.statusCode}');
    print('   Headers: ${response.headers}');
    print('   Body length: ${response.body.length} characters');

    // ✅ SUCCESS RESPONSES (200-299)
    // HTTP status codes in 200s mean the request was successful
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final jsonResponse = json.decode(response.body);
        print('✅ Success! Response: $jsonResponse');
        return jsonResponse;
      } catch (e) {
        print('❌ JSON parsing error: $e');
        throw Exception(
            '❌ Failed to parse JSON response: $e\nResponse body: ${response.body}');
      }
    }

    // 🚫 ERROR RESPONSES (400+)
    // HTTP status codes 400+ mean there was an error
    else {
      // 🔍 DETAILED ERROR REPORTING FOR BEGINNERS
      // This helps you understand what went wrong and how to fix it

      String errorMessage = '''
❌ HTTP Error ${response.statusCode} - $method Request Failed
=============================================================

🌐 REQUEST DETAILS:
   URL: $url
   Method: $method
   
📊 RESPONSE DETAILS:
   Status Code: ${response.statusCode}
   Headers: ${response.headers}
   Body: ${response.body}

🔧 COMMON FIXES:
''';

      // Add specific error guidance based on status code
      switch (response.statusCode) {
        case 404:
          errorMessage += '''
   🚨 404 NOT FOUND - The endpoint doesn't exist
   ✅ Check if the URL path is correct
   ✅ Make sure your Rust server is running
   ✅ Verify the endpoint is registered in main.rs
   ✅ Check if you're missing the /api/v1 prefix
''';
          break;
        case 500:
          errorMessage += '''
   💥 500 INTERNAL SERVER ERROR - The Rust backend crashed
   ✅ Check your Rust server logs
   ✅ Look for compilation errors
   ✅ Verify your database connection
''';
          break;
        case 401:
          errorMessage += '''
   🔐 401 UNAUTHORIZED - Authentication failed
   ✅ Check your JWT token
   ✅ Make sure you're logged in
   ✅ Verify the Authorization header
''';
          break;
        case 403:
          errorMessage += '''
   🚫 403 FORBIDDEN - You don't have permission
   ✅ Check your user permissions
   ✅ Verify your JWT token is valid
''';
          break;
        default:
          errorMessage += '''
   🔍 Check your Rust server logs for more details
   🔍 Verify your request data format
   🔍 Make sure the endpoint exists
''';
      }

      print(errorMessage);
      throw Exception(errorMessage);
    }
  }
}
