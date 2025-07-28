// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'network_status_widget.dart';

// class NetworkAwareWidget extends StatelessWidget {
//   final Widget child;
//   final bool showNetworkStatus;
//   final VoidCallback? onNetworkRestored;

//   const NetworkAwareWidget({
//     super.key,
//     required this.child,
//     this.showNetworkStatus = true,
//     this.onNetworkRestored,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       final networkManager = NetworkManager.instance;

//       return Column(
//         children: [
//           // Show network status bar if enabled and no internet
//           if (showNetworkStatus && !networkManager.isInternetAvailable)
//             const NetworkStatusWidget(),

//           // Main content
//           Expanded(
//             child: networkManager.isInternetAvailable
//                 ? child
//                 : _buildNoInternetWidget(),
//           ),
//         ],
//       );
//     });
//   }

//   Widget _buildNoInternetWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(
//             Icons.wifi_off,
//             size: 64,
//             color: Colors.grey,
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'No Internet Connection',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Please check your connection and try again',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey,
//             ),
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton(
//             onPressed: () {
//               NetworkManager.instance.checkAndRedirectIfNeeded();
//             },
//             child: const Text('Retry'),
//           ),
//         ],
//       ),
//     );
//   }
// }
