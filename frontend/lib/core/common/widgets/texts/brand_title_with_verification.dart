
// import 'package:flutter/material.dart';
// import 'package:iconsax/iconsax.dart';


// import '../../../utils/effects/shimmer effect.dart';

// class TBrandTitleWithVerification extends StatelessWidget {
//   const TBrandTitleWithVerification({
//     super.key,
//     required this.brandId,
//     this.maxLines = 1,
//     this.iconColor,
//     this.textColor,
//     this.textAlign,
//     this.brandTextSize = TextSizes.small,
//   });

//   final int brandId;
//   final int maxLines;
//   final Color? iconColor, textColor;
//   final TextAlign? textAlign;
//   final TextSizes brandTextSize;

//   @override
//   Widget build(BuildContext context) {
//     final brandController = BrandController.instance;

//     // First check if brand is already cached
//     final cachedBrand = brandController.getCachedBrandById(brandId);

//     if (cachedBrand != null) {
//       // Brand is cached, display immediately without shimmer
//       return _buildBrandWidget(cachedBrand);
//     }

//     // Brand not cached, fetch from database with shimmer
//     return FutureBuilder<BrandModel?>(
//         future: brandController.getBrandByIdAndVerification(brandId),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const TShimmerEffect(
//               width: 40,
//               height: 10,
//             );
//           } else if (snapshot.hasError) {
//             return Text('Error: ${snapshot.error}');
//           } else if (snapshot.hasData && snapshot.data != null) {
//             final BrandModel brand = snapshot.data!;
//             return _buildBrandWidget(brand);
//           } else {
//             return const Text("--");
//           }
//         });
//   }

//   Widget _buildBrandWidget(BrandModel brand) {
//     return IntrinsicWidth(
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Flexible(
//             child: Padding(
//               padding: const EdgeInsets.only(right: 2),
//               child: TBrandTitleText(
//                 title: brand.brandname,
//                 color: textColor,
//                 maxLines: maxLines,
//                 textAlign: textAlign,
//                 brandTextSizes: brandTextSize,
//               ),
//             ),
//           ),
//           (brand.isVerified ?? false)
//               ? Icon(
//                   Iconsax.verify5,
//                   color: iconColor,
//                   size: TSizes.iconXs,
//                 )
//               : const SizedBox()
//         ],
//       ),
//     );
//   }
// }
