import 'package:frontend/core/routes/o_routes.dart';
import 'package:frontend/features/authentication/presentation/pages/forget_password/forget_password.dart';
import 'package:get/get.dart';

import '../../features/authentication/presentation/pages/login/login.dart';
import '../../features/authentication/presentation/pages/signup/signup.dart';
import '../../features/authentication/presentation/pages/signup/widgets/verify_email.dart';
import '../../features/chat/presentation/pages/chat_screen.dart';
import '../../features/home/presentation/pages/home_screen.dart';

class AppRoutes {
  static final pages = [

    GetPage(name: ORoutes.login, page: () => const LoginScreen()),
    GetPage(name: ORoutes.signup, page: () => const SignUpScreen()),
    GetPage(name: ORoutes.forgotPassword, page: () => const ForgetPassword()),
    GetPage(name: ORoutes.verifyEmail, page: () => const VerifyEmailScreen()),
    // GetPage(name: ORoutes.resetPassword, page: () => const ResetPasswordScreen()),
    
    
    GetPage(name: ORoutes.home, page: () => const HomeScreen()),

    //Chat Screen
    GetPage(name: ORoutes.chatScreen, page: () =>   ChatScreen()),

    
    
    

  ];
}
