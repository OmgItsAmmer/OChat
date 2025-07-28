// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// import '../../../utils/constants/colors.dart';
// import '../../../utils/constants/sizes.dart';
// import '../../../utils/effects/shimmer effect.dart';
// import '../../../utils/helpers/helper_functions.dart';
// import '../../../utils/constants/enums.dart';

// class TCircularImage extends StatefulWidget {
//   const TCircularImage({
//     super.key,
//     this.fit = BoxFit.cover,
//     required this.image,
//     this.isNetworkImage = false,
//     this.overlayColor,
//     this.backgroundColor,
//     this.width = 56,
//     this.height = 56,
//     this.padding = TSizes.sm,
//     this.entityId,
//     this.mediaCategory = MediaCategory.products,
//   });

//   final BoxFit? fit;
//   final String image;
//   final bool isNetworkImage;
//   final Color? overlayColor;
//   final Color? backgroundColor;
//   final double width, height, padding;
//   final int? entityId;
//   final MediaCategory mediaCategory;

//   @override
//   State<TCircularImage> createState() => _TCircularImageState();
// }

// class _TCircularImageState extends State<TCircularImage> {
//   final MediaController mediaController = Get.put(MediaController());
//   late Future<String?> _imageFuture;

//   @override
//   void initState() {
//     super.initState();
//     _imageFuture = _loadImage();
//   }

//   @override
//   void didUpdateWidget(covariant TCircularImage oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.entityId != oldWidget.entityId ||
//         widget.mediaCategory != oldWidget.mediaCategory ||
//         widget.image != oldWidget.image) {
//       _imageFuture = _loadImage();
//     }
//   }

//   Future<String?> _loadImage() async {
//     if (widget.isNetworkImage && widget.entityId != null) {
//       // Preload image (this caches it, so subsequent fetch will be fast)
//       await mediaController
//           .preloadImages([widget.entityId!], widget.mediaCategory.name);
//       // Fetch the actual image URL for display
//       return mediaController.fetchMainImage(
//           widget.entityId!, widget.mediaCategory.name);
//     } else if (widget.isNetworkImage) {
//       return Future.value(widget.image); // Use the provided network image URL
//     }
//     return Future.value(null); // Not a network image or no entityId
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: widget.width,
//       height: widget.height,
//       padding: EdgeInsets.all(widget.padding),
//       decoration: BoxDecoration(
//         color: widget.backgroundColor ??
//             (THelperFunctions.isDarkMode(context)
//                 ? TColors.black
//                 : TColors.white),
//         borderRadius: BorderRadius.circular(100),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(100),
//         child: Center(
//           child: widget.isNetworkImage
//               ? FutureBuilder<String?>(
//                   future: _imageFuture,
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return TShimmerEffect(
//                         width: widget.width,
//                         height: widget.height,
//                         radius: widget.width / 2,
//                       );
//                     } else if (snapshot.hasError) {
//                       return const Icon(Icons.error);
//                     } else {
//                       final imageUrl = snapshot.data;
//                       if (imageUrl != null && imageUrl.isNotEmpty) {
//                         return CachedNetworkImage(
//                           fit: widget.fit,
//                           color: widget.overlayColor,
//                           imageUrl: imageUrl,
//                           progressIndicatorBuilder:
//                               (context, url, downloadProgress) =>
//                                   TShimmerEffect(
//                             width: widget.width,
//                             height: widget.height,
//                             radius: widget.width / 2,
//                           ),
//                           errorWidget: (context, url, error)
//                               // ignore: prefer_const_constructors
//                               =>
//                               Icon(Icons.error),
//                         );
//                       } else {
//                         // Fallback to placeholder or error icon if image URL is null or empty
//                         return const Icon(
//                             Icons.error); // Or a local placeholder image
//                       }
//                     }
//                   },
//                 )
//               : Image(
//                   // Local asset image
//                   fit: widget.fit,
//                   image: AssetImage(widget.image),
//                   color: widget.overlayColor,
//                 ),
//         ),
//       ),
//     );
//   }
// }
