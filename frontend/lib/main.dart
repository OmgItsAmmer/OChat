import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import our custom theme and constants
import 'core/utils/constants/text_strings.dart';

import 'app.dart';
import 'features/authentication/presentation/controllers/auth_controller.dart';
import 'features/chat/presentation/controllers/chat_controller.dart';


/// Global Supabase client instance for easy access throughout the app
/// This provides a singleton pattern for the Supabase client
/// Best Practice: Global variables should be used sparingly and only for truly global services
final supabase = Supabase.instance.client;

/// Main entry point of the OChat messenger application
/// This app is designed for OMGx (AI startup) with real-time messaging capabilities
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage for local data persistence
  // GetStorage is used to store user preferences, auth tokens, and offline data
  await GetStorage.init();

  // Initialize Supabase for authentication and database operations

  await Supabase.initialize(
    url: TTexts.supabaseUrl,
    anonKey: TTexts.supabaseAnonKey,
  );

  // Initialize global controllers that need to be available throughout the app
  // These controllers manage core app functionality using GetX state management
  _initializeControllers();

  runApp(const OChatApp());
}

/// Initialize global controllers for dependency injection
/// This follows the GetX pattern of putting controllers that are used across
/// multiple screens into global scope for easy access
void _initializeControllers() {
  // Auth controller manages user authentication state, login/logout
  Get.put(AuthController(), permanent: true);

  // Chat controller manages real-time messaging, conversations, WebSocket connections
 // Get.put(ChatController(), permanent: true);

  // Note: UserController removed as it doesn't exist yet
  // You can add it back when you create the UserController class
}
