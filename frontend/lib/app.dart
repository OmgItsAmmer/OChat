import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ignore: unused_import
import 'core/bindings/general_bindings.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/o_routes.dart';
import 'core/utils/theme/theme.dart';

/// Root widget of the OChat application
/// This is a StatelessWidget because all state is managed by GetX controllers
class OChatApp extends StatelessWidget {
  const OChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'OChat - OMGx Messenger',
      debugShowCheckedModeBanner: true,

      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
     
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      initialRoute: ORoutes.home,

   //   initialBinding: GeneralBindings(),

      getPages: AppRoutes.pages,
   //   unknownRoute: Get.toNamed(ORoutes.login),     
      

        // Global loading overlay configuration
        // This shows when controllers are performing operations
      // builder: (context, child) {
      //   return MediaQuery(
      //     // Ensure text scaling respects user preferences but stays readable
      //     data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      //     child: child!,
      //   );
      // },

      navigatorObservers: [GetObserver()],

    );
  }


  //unkown screen to locate when unkown route
  

}
