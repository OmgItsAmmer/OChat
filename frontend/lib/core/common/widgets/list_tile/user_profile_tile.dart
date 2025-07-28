  // import 'package:flutter/material.dart';
  // import 'package:get/get.dart';
  // import 'package:iconsax/iconsax.dart';

  // import '../../../utils/constants/colors.dart';
  // import '../../../utils/constants/image_strings.dart';
  // import '../images/t_circular_image.dart';
  // import '../../../utils/constants/enums.dart';
  // import '../../../utils/effects/shimmer effect.dart';

  // class TUserProfileTile extends StatelessWidget {
  //   const TUserProfileTile({super.key, required this.onPressed});
  //   final VoidCallback onPressed;

  //   @override
  //   Widget build(BuildContext context) {
  //     final controller = Get.put(CustomerController());
  //     return ListTile(
  //       leading: FutureBuilder<String?>(
  //         future: controller.getUserProfilePicture(),
  //         builder: (context, snapshot) {
  //           // Show shimmer while loading
  //           if (snapshot.connectionState == ConnectionState.waiting) {
  //             return TShimmerEffect(width: 50, height: 50, radius: 50);
  //           }

  //           // Show default image if no data or error
  //           if (snapshot.hasError || snapshot.data == null) {
  //             return TCircularImage(
  //               image: TImages.user,
  //               width: 50,
  //               height: 50,
  //               padding: 0,
  //               isNetworkImage: false,
  //             );
  //           }

  //           // Show profile image if available
  //           final String profileImageUrl = snapshot.data!;
  //           final bool hasProfileImage = profileImageUrl.isNotEmpty;

  //           return TCircularImage(
  //             image: hasProfileImage ? profileImageUrl : TImages.user,
  //             width: 50,
  //             height: 50,
  //             padding: 0,
  //             isNetworkImage: hasProfileImage,
  //             entityId: controller.currentCustomer.value.customerId,
  //             mediaCategory: MediaCategory.customers,
  //           );
  //         },
  //       ),
  //       title: Text(
  //         "${controller.currentCustomer?.value.firstName} ${controller.currentCustomer?.value.lastName}",
  //         style: Theme.of(context)
  //             .textTheme
  //             .headlineSmall!
  //             .apply(color: TColors.white),
  //       ),
  //       subtitle: Text(
  //         controller.currentCustomer?.value.email ?? "no email found!",
  //         style:
  //             Theme.of(context).textTheme.bodyMedium!.apply(color: TColors.white),
  //       ),
  //       trailing: IconButton(
  //           onPressed: onPressed,
  //           icon: Icon(
  //             Iconsax.edit,
  //             color: TColors.white,
  //           )),
  //     );
  //   }
  // }
