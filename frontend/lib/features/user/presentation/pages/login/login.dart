
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

import '../../../../../core/common/styles/spacingstyles.dart';
import '../../../../../core/utils/constants/sizes.dart';
import '../../../../../core/utils/helpers/helper_functions.dart';
import 'widgets/TLoginForm.dart';
import 'widgets/login_header.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            children: [
              TLoginHeader(dark: dark),
               const TLoginForm(),
              // TFormDivider(divierText: TTexts.orSignInWith.capitalize!,dark: dark),
              const SizedBox(
                height: TSizes.spaceBtwItems,
              ),
            //  TLoginSocialButtons()
            ],
          ),
        ),
      ),
    );
  }
}
