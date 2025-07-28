import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/features/authentication/data/repositories/auth_repo_impl.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/common/widgets/loaders/tloaders.dart';
import '../../../../core/routes/o_routes.dart';
import '../../../../main.dart';

/// 🔐 Authentication Controller
///
/// Manages all authentication-related state and operations using GetX state management.
/// This controller handles login, logout, registration, password reset, and user session management.
///
/// GetX Benefits:
/// - Reactive state management (automatically updates UI when state changes)
/// - Dependency injection (available throughout the app)
/// - Memory management (automatically disposed when not needed)
///
/// Best Practice: Controllers should only handle business logic and state,
/// not UI concerns. UI widgets observe controller state and react accordingly.
class AuthController extends GetxController {
  // 📱 GetStorage instance for local data persistence
  // This stores auth tokens, user preferences, and offline data
  final _storage = GetStorage();

  // 🎯 Reactive State Variables (Observable)
  // These automatically update UI when their values change

  /// Current authentication status
  /// true = user is logged in, false = user is logged out
  final _isAuthenticated = false.obs;
  bool get isAuthenticated => _isAuthenticated.value;

  /// Loading state for authentication operations
  /// Shows loading indicators during login, registration, etc.
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  /// Current user information
  /// Contains user profile data, email, display name, etc.
  final Rx<User?> _currentUser = Rx<User?>(null);
  User? get currentUser => _currentUser.value;

  /// User's display name for UI purposes
  final _userName = ''.obs;
  String get userName => _userName.value;

  /// User's email address
  final _userEmail = ''.obs;
  String get userEmail => _userEmail.value;

  /// Remember me preference for login
  /// Determines if user wants to stay logged in
  final _rememberMe = false.obs;
  bool get rememberMe => _rememberMe.value;
  set rememberMe(bool value) => _rememberMe.value = value;

  ///Hide password
  final hidePassword = true.obs;

  ///Text editing controllers
  final email = TextEditingController();
  final password = TextEditingController();

  ///Form keys
  final loginFormKey = GlobalKey<FormState>();
  final signupFormKey = GlobalKey<FormState>();
  final forgotPasswordFormKey = GlobalKey<FormState>();


  //Signup form fields
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final username = TextEditingController();
  final phoneNumber = TextEditingController();
  final privacyPolicy = false.obs;


  // 🎬 Lifecycle Methods

  @override
  void onInit() {
    super.onInit();

    // Initialize authentication state when controller is created
    // This runs when the app starts
    _initializeAuth();

    // Listen to Supabase auth state changes
    // This automatically updates our state when auth status changes
    supabase.auth.onAuthStateChange.listen((data) {
      _handleAuthStateChange(data);
    });
  }

  @override
  void onReady() {
    super.onReady();
    // Check if user has a valid session when app becomes ready
    _checkExistingSession();
  }

  // 🔧 Private Helper Methods

  /// Initialize authentication state from stored data
  /// Loads saved user preferences and session information
  void _initializeAuth() {
    try {
      // Load remember me preference
      _rememberMe.value = _storage.read('remember_me') ?? false;

      // Load saved user data if available
      final savedUser = _storage.read('user_data');
      if (savedUser != null) {
        _userName.value = savedUser['name'] ?? '';
        _userEmail.value = savedUser['email'] ?? '';
      }

      if (kDebugMode) {
        print('📱 Auth initialized - Remember me: ${_rememberMe.value}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing auth: $e');
      }
    }
  }

  /// Handle Supabase authentication state changes
  /// This method is called whenever the user's auth state changes
  void _handleAuthStateChange(AuthState authState) {
    final user = authState.session?.user;

    if (user != null) {
      // User is authenticated
      _setAuthenticatedUser(user);
      if (kDebugMode) {
        print('✅ User authenticated: ${user.email}');
      }
    } else {
      // User is not authenticated
      _clearUserData();
      if (kDebugMode) {
        print('🚫 User not authenticated');
      }
    }
  }

  /// Set authenticated user data
  /// Updates all user-related reactive variables
  void _setAuthenticatedUser(User user) {
    _currentUser.value = user;
    _isAuthenticated.value = true;
    _userName.value = user.userMetadata?['display_name'] ??
        user.email?.split('@')[0] ??
        'User';
    _userEmail.value = user.email ?? '';

    // Save user data locally for offline access
    _storage.write('user_data', {
      'id': user.id,
      'email': user.email,
      'name': _userName.value,
    });
  }

  /// Clear user data and authentication state
  /// Called when user logs out or session expires
  void _clearUserData() {
    _currentUser.value = null;
    _isAuthenticated.value = false;
    _userName.value = '';
    _userEmail.value = '';

    // Keep remember me preference but clear sensitive data
    _storage.remove('user_data');
  }

  /// Check for existing valid session
  /// Called when app starts to see if user is already logged in
  Future<void> _checkExistingSession() async {
    try {
      final session = supabase.auth.currentSession;
      if (session != null) {
        _setAuthenticatedUser(session.user);

        // Navigate to home if user is already authenticated
        // We'll create these routes later
        Get.offAllNamed('/home');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking session: $e');
      }
    }
  }

  // 🔑 Public Authentication Methods

  /// Login with email and password
  ///
  /// This method handles user authentication and provides feedback.
  /// Shows loading states and error messages automatically.
  Future<bool> login({
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) _isLoading.value = true;

      // Input validation
      if (email.text.isEmpty || password.text.isEmpty) {
        TLoader.errorSnackBar(
          title: 'Validation Error',
          message: 'Please enter both email and password',
        );
        return false;
      }

      // Attempt login via AuthRepo
      final result = await AuthRepoImpl().login(email.text, password.text);

      return result.fold(
        // Failure case
        (failure) {
          TLoader.errorSnackBar(
            title: 'Login Failed',
            message: failure.message,
          );
          return false;
        },
        // Success case
        (_) {
          // Optional: Fetch user from Supabase client
          final user = supabase.auth.currentUser;
          if (user != null) {
            _setAuthenticatedUser(user);
          }

          _storage.write('remember_me', _rememberMe.value);

          TLoader.successSnackBar(
            title: 'Welcome back!',
            message: 'Successfully logged in to OChat',
          );

          Get.offAllNamed('/home');
          return true;
        },
      );
    } catch (e) {
      TLoader.errorSnackBar(
        title: 'Login Error',
        message: 'An unexpected error occurred. Please try again.',
      );
      if (kDebugMode) {
        print('❌ Login error: $e');
      }
      return false;
    } finally {
      if (showLoading) _isLoading.value = false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) _isLoading.value = true;

      // Input validation
      if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
        TLoader.errorSnackBar(
          title: 'Validation Error',
          message: 'Please fill in all required fields',
        );
        return false;
      }

      if (password.length < 6) {
        TLoader.errorSnackBar(
          title: 'Weak Password',
          message: 'Password must be at least 6 characters long',
        );
        return false;
      }

      // Signup via repository
      final result = await AuthRepoImpl().signup(email, password);

      return result.fold(
        // On failure
        (failure) {
          TLoader.errorSnackBar(
            title: 'Registration Failed',
            message: failure.message,
          );
          return false;
        },
        // On success
        (_) {
          TLoader.successSnackBar(
            title: 'Account Created!',
            message:
                'Welcome to OChat! Please check your email to verify your account.',
          );

          final user = Supabase.instance.client.auth.currentUser;
          final session = Supabase.instance.client.auth.currentSession;

          if (session != null && user != null) {
            // Email confirmation disabled — user already logged in
            _setAuthenticatedUser(user);
            Get.offAllNamed(ORoutes.home);
          } else {
            // Email confirmation required
            Get.offAllNamed(ORoutes.verifyEmail);
          }

          return true;
        },
      );
    } catch (e) {
      TLoader.errorSnackBar(
        title: 'Registration Error',
        message: 'An unexpected error occurred. Please try again.',
      );
      if (kDebugMode) {
        print('❌ Registration error: $e');
      }
      return false;
    } finally {
      if (showLoading) _isLoading.value = false;
    }
  }

  /// Logout current user
  ///
  /// Signs out the user and clears all local data.
  /// Returns to login screen after successful logout.
  Future<bool> logout({bool showLoading = true}) async {
    try {
      if (showLoading) {
        _isLoading.value = true;
      }

      // Sign out from Supabase
      await supabase.auth.signOut();

      // Clear local data
      _clearUserData();

      // Show success message
      TLoader.successSnackBar(
        title: 'Logged Out',
        message: 'You have been successfully logged out',
      );

      // Navigate to login screen
      Get.offAllNamed('/login');
      return true;
    } catch (e) {
      TLoader.errorSnackBar(
        title: 'Logout Error',
        message: 'Failed to logout. Please try again.',
      );
      if (kDebugMode) {
        print('❌ Logout error: $e');
      }
      return false;
    } finally {
      if (showLoading) {
        _isLoading.value = false;
      }
    }
  }

/// Sends a password reset email to the specified address.
/// User will receive a link to reset their password.
// Future<bool> resetPassword({required String email}) async {
//   try {
//     _isLoading.value = true;

//     // Input validation
//     if (email.isEmpty) {
//       TLoader.errorSnackBar(
//         title: 'Validation Error',
//         message: 'Please enter your email address',
//       );
//       return false;
//     }

//     // Call forgotPassword() from repository
//     final result = await AuthRepoImpl().forgotPassword(email);

//     return result.fold(
//       // Failure case
//       (failure) {
//         TLoader.errorSnackBar(
//           title: 'Reset Password Failed',
//           message: failure.message,
//         );
//         return false;
//       },
//       // Success case
//       (_) {
//         TLoader.successSnackBar(
//           title: 'Reset Email Sent',
//           message: 'Check your email for password reset instructions',
//         );
//         return true;
//       },
//     );
//   } catch (e) {
//     TLoader.errorSnackBar(
//       title: 'Reset Password Error',
//       message: 'An unexpected error occurred. Please try again.',
//     );
//     print('❌ Password reset error: $e');
//     return false;
//   } finally {
//     _isLoading.value = false;
//   }
// }


  /// Check if user email is verified
  ///
  /// Returns true if the current user's email has been verified.
  bool get isEmailVerified {
    return _currentUser.value?.emailConfirmedAt != null;
  }

  /// Resend verification email
  ///
  /// Sends another verification email to the current user.
  Future<bool> resendVerificationEmail() async {
    try {
      if (_currentUser.value?.email == null) {
        TLoader.errorSnackBar(
          title: 'Error',
          message: 'No user email found',
        );
        return false;
      }

      await supabase.auth.resend(
        type: OtpType.signup,
        email: _currentUser.value!.email!,
      );

      TLoader.successSnackBar(
        title: 'Verification Email Sent',
        message: 'Check your email for verification instructions',
      );
      return true;
    } catch (e) {
      TLoader.errorSnackBar(
        title: 'Error',
        message: 'Failed to send verification email',
      );
      return false;
    }
  }


  /// Sets a new password after the user has clicked the reset link
/// and returned to the app (deep link or browser redirect).
Future<bool> forgotPassword({
  required String email,
}) async {
  try {
    _isLoading.value = true;

    // Input validation
    if (email.isEmpty) {
      TLoader.errorSnackBar(
        title: 'Validation Error',
        message: 'Please enter your email address',
      );
      return false;
    }

    // Call reset logic from the repository
   final result = await AuthRepoImpl().forgotPassword(email);

    return result.fold(
      // Failure case
      (failure) {
        TLoader.errorSnackBar(
          title: 'Password Reset Failed',
          message: failure.message,
        );
        return false;
      },
      // Success case
      (_) {
        TLoader.successSnackBar(
          title: 'Password Reset Email Sent',
          message: 'Check your email for password reset instructions',
        );
        Get.offAllNamed(ORoutes.login);
        return true;
      },
    );
  } catch (e) {
    TLoader.errorSnackBar(
      title: 'Password Reset Error',
      message: 'An unexpected error occurred. Please try again.',
    );
    if (kDebugMode) {
      print('❌ ForgotPassword error: $e');
    }
    return false;
  } finally {
    _isLoading.value = false;
  }
}

  Future<bool> signUp() async {
    try {
      _isLoading.value = true;
      if(!signupFormKey.currentState!.validate() || !privacyPolicy.value){
        return false;
      }

      final result = await AuthRepoImpl().signup(email.text, password.text);

      return result.fold(
        (failure) {
          TLoader.errorSnackBar(
            title: 'Signup Failed',
            message: failure.message,
          );
          return false;
        },  
        (_) {
          TLoader.successSnackBar(
            title: 'Signup Successful',
            message: 'Please check your email for verification',
          );
          Get.offAllNamed(ORoutes.verifyEmail);
          return true;
        },
      );


    } catch (e) {
      TLoader.errorSnackBar(
        title: 'Signup Error',
        message: 'An unexpected error occurred. Please try again.',
      );
      if (kDebugMode) {
        print('❌ Signup error: $e');
      }
      return false;
    }finally{
      _isLoading.value = false;
    }
  }

  Future<bool> logOut() async {
    try {
      _isLoading.value = true;
     final response =  await AuthRepoImpl().logout();
     return response.fold(
      (failure) {
        TLoader.errorSnackBar(
          title: 'Logout Failed',
          message: failure.message,
        );
        return false;
      },
      (_) {
        _clearUserData();
        Get.offAllNamed(ORoutes.login);
        return true;
      },
     );

    } catch (e) {
      TLoader.errorSnackBar(
        title: 'Logout Error',
        message: 'Failed to logout. Please try again.',
      );
      if (kDebugMode) {
        print('❌ Logout error: $e');
      }
        return false;
    }finally{
      _isLoading.value = false;
    }
  }

}
