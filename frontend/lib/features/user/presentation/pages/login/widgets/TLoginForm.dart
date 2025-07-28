
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../../core/routes/o_routes.dart';
import '../../../../../../core/utils/constants/sizes.dart';
import '../../../../../../core/utils/constants/text_strings.dart';
import '../../../../../../core/utils/validators/validation.dart';
import '../../../controllers/auth_controller.dart';
import '../../forget_password/forget_password.dart';



class TLoginForm extends StatelessWidget {
  const TLoginForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    return Form(
      key: controller.loginFormKey,
        child: Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.spaceBtwSections),
      child: Column(
        children: [
          TextFormField(
            validator: (value) => TValidator.validateEmail(value),
            controller: controller.email,
            decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.direct_right),
                labelText: TTexts.email),
          ),
          const SizedBox(
            height: TSizes.spaceBtwInputFields,
          ),
          Obx(
                () => TextFormField(
              validator: (value)=> TValidator.validatePassword(value),
              obscureText: controller.hidePassword.value,
              controller: controller.password,
              expands: false,
              decoration: InputDecoration(
                  labelText: TTexts.password,
                  prefixIcon: const Icon(Iconsax.password_check ),
                  suffixIcon: IconButton(onPressed: ()=> controller.hidePassword.value = !controller.hidePassword.value,icon:  Icon(controller.hidePassword.value ?Iconsax.eye_slash:Iconsax.eye),)),
            ),
          ),
          const SizedBox(
            height: TSizes.spaceBtwInputFields / 2,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //Remeber me
              Row(
                children: [
                  Obx(()=> Checkbox(value: controller.rememberMe, onChanged: (value) => controller.rememberMe = !controller.rememberMe)),
                  const Text(TTexts.rememberMe),
                ],
              ),
              TextButton(onPressed: () => Get.to(()=>ForgetPassword()), child: const Text(TTexts.forgetPassword)),
            ],
          ),
          const SizedBox(
            height: TSizes.spaceBtwSections,
          ),
          SizedBox(
              width: double.infinity,
              child:
                  ElevatedButton(onPressed: () => controller.login(), child: const Text(TTexts.signIn))),
          const SizedBox(height: TSizes.spaceBtwSections),
          SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.symmetric(
                          vertical:
                              16.0), // Same vertical padding as ElevatedButton
                    ),
                    side: WidgetStateProperty.all<BorderSide>(
                      const BorderSide(
                          color:
                              Colors.white), // Border color to match the theme
                    ),
                  ),
                  onPressed: () => Get.toNamed(ORoutes.signup),
                  child: const Text(TTexts.createAccount))),
        ],
      ),
    ));
  }
}
