
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';

// import '../../utils/constants/colors.dart';
// import '../../utils/constants/image_strings.dart';
// import '../../utils/constants/sizes.dart';
// import '../../utils/helpers/helper_functions.dart';
// import 'custom_shapes/containers/rounded_container.dart';

// class TLoginSocialButtons extends StatelessWidget {
//   const TLoginSocialButtons({
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(LoginController());
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         _buildSocialButton(TImages.google, "Continue with Google", () {
//           controller.googleSignIn();
//         }),
     
//       ],
//     );
//   }

//   Widget _buildSocialButton(String imagePath, String text, VoidCallback onPressed) {
//     final dark = THelperFunctions.isDarkMode(Get.context!);
//     return TRoundedContainer(
//       onTap: onPressed,
//       borderColor: dark ? TColors.darkGrey : TColors.grey,
//       backgroundColor: dark ? TColors.dark : TColors.light,
//       width: double.infinity,
//       padding: const EdgeInsets.all(TSizes.md),
//       child: Row(
//         children: [
//           Image(
//             image: AssetImage(imagePath),
//             width: TSizes.iconLg,
//             height: TSizes.iconLg,
//           ),
//           const SizedBox(width: TSizes.spaceBtwItems),
//           Text(text, style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
//             color: dark ? TColors.white : TColors.black,
//           )),
//         ],
//       ),
//     );
//   }
// }
