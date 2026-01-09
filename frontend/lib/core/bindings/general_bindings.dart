import 'package:get/get.dart';
import '../../features/authentication/presentation/controllers/auth_controller.dart';

import '../../features/home/presentation/controllers/home_controller.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    // 🔐 Authentication Controller (Global)
    // This is used throughout the app for user authentication state
    Get.put(AuthController(), permanent: true);

    // 🏠 Home Controller (Global)
    // This manages user list and home screen functionality
    Get.put(HomeController(), permanent: true);
  }
}
