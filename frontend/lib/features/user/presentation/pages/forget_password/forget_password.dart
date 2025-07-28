

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../../core/utils/constants/sizes.dart';
import '../../../../../../core/utils/constants/text_strings.dart';
import '../../../../../../core/utils/validators/validation.dart';
import '../../controllers/auth_controller.dart';

class ForgetPassword extends StatelessWidget {
  const ForgetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(children: [
          //Headings
          Text(TTexts.forgetPasswordTitle,style: Theme.of(context).textTheme.labelMedium,),
          const SizedBox(height: TSizes.spaceBtwItems,),
          Text(TTexts.forgetPasswordSubTitle,style: Theme.of(context).textTheme.labelMedium,),
          const SizedBox(height: TSizes.spaceBtwSections*2,),


          //TextFields
          TextFormField(
            key: controller.forgotPasswordFormKey,
            controller: controller.email,
            validator: TValidator.validateEmail,
            decoration: const InputDecoration(labelText: TTexts.email,prefixIcon:  Icon(Iconsax.direct_right)),),
          const SizedBox(height: TSizes.spaceBtwSections,),
          SizedBox(
              width: double.infinity
              ,
              child: ElevatedButton(onPressed: ()=> controller.forgotPassword(email: controller.email.text), child: const Text(TTexts.submit))),





          //Submit Butoon
        ],),
      ),
    );
  }
}
