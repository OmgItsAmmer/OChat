// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class NetworkStatusWidget extends StatelessWidget {
//   const NetworkStatusWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       final networkManager = NetworkManager.instance;

//       return Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         decoration: BoxDecoration(
//           color: networkManager.isInternetAvailable
//               ? Colors.green.withOpacity(0.1)
//               : Colors.red.withOpacity(0.1),
//           border: Border(
//             bottom: BorderSide(
//               color: networkManager.isInternetAvailable
//                   ? Colors.green
//                   : Colors.red,
//               width: 2,
//             ),
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               networkManager.isInternetAvailable ? Icons.wifi : Icons.wifi_off,
//               color: networkManager.isInternetAvailable
//                   ? Colors.green
//                   : Colors.red,
//               size: 20,
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 networkManager.isInternetAvailable
//                     ? 'Connected to Internet'
//                     : 'No Internet Connection',
//                 style: TextStyle(
//                   color: networkManager.isInternetAvailable
//                       ? Colors.green
//                       : Colors.red,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             if (!networkManager.isInternetAvailable)
//               TextButton(
//                 onPressed: () {
//                   networkManager.checkAndRedirectIfNeeded();
//                 },
//                 child: const Text(
//                   'Retry',
//                   style: TextStyle(color: Colors.red),
//                 ),
//               ),
//           ],
//         ),
//       );
//     });
//   }
// }
