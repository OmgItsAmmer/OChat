import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/device/device_utility.dart';
import '../../../../utils/helpers/helper_functions.dart';

class TSearchContainer extends StatelessWidget {
  const TSearchContainer({
    super.key,
    required this.text,
    this.icon = Iconsax.search_normal,
    this.showBackground = true,
    this.showBorder = true,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
    this.navigateToSearch = true, // New parameter to control navigation
  });

  final String text;
  final IconData? icon;
  final bool showBackground, showBorder;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool navigateToSearch; // Controls whether to navigate to search screen

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return GestureDetector(
      onTap: onTap , //?? (navigateToSearch ? () => Get.toNamed(TRoutes.search) : null)
      child: Padding(
        padding: padding,
        child: Container(
          width: TDeviceUtils.getScreenWidth(context),
          padding: const EdgeInsets.all(TSizes.md),
          decoration: BoxDecoration(
            color: (showBackground)
                ? (dark)
                    ? TColors.dark
                    : TColors.light
                : Colors.transparent,
            borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
            border: showBorder ? Border.all(color: TColors.textPurple) : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: dark ? TColors.white : Colors.black,
              ),
              const SizedBox(
                width: TSizes.spaceBtwItems,
              ),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall!.apply(
                        color: dark
                            ? TColors.white.withOpacity(0.7)
                            : TColors.darker,
                      ),
                ),
              ),
              if (navigateToSearch)
                Icon(
                  Iconsax.arrow_right_3,
                  size: 16,
                  color: TColors.gradientEnd,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
