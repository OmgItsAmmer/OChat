
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/common/widgets/form_divider.dart';
import '../../../../../core/utils/constants/sizes.dart';
import '../../../../../core/utils/constants/text_strings.dart';
import '../../../../../core/utils/helpers/helper_functions.dart';
import 'widgets/sign_up_form.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Title
              Text(
                TTexts.signupTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(
                height: TSizes.spaceBtwSections,
              ),

              //Form
              const SignUpForm(),
              const SizedBox(
                height: TSizes.spaceBtwSections,
              ),
              //Divider
              TFormDivider(dark: dark, divierText: TTexts.orSignUpWith.capitalize!),
            //   const SizedBox(
            //     height: TSizes.spaceBtwSections,
            //   ),
            //   //Social butoons
            //  const  TLoginSocialButtons()

            ],
          ),
        ),
      ),
    );
  }
}


