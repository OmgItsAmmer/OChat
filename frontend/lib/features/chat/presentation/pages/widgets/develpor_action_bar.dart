import 'package:flutter/material.dart';
import 'package:frontend/core/utils/constants/colors.dart';
import 'package:frontend/core/utils/helpers/helper_functions.dart';

class DeveloperActionBar extends StatelessWidget {
  const DeveloperActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isDarkMode ? Colors.black12 : Colors.grey.shade100,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.code, color: TColors.secondary),
            onPressed: () {
              // TODO: open code snippet input dialog
            },
            tooltip: "Send Code Snippet",
          ),
          IconButton(
            icon: const Icon(Icons.bug_report, color: TColors.accent),
            onPressed: () {
              // TODO: attach bug report / logs
            },
            tooltip: "Report Bug or Log",
          ),
          IconButton(
            icon: const Icon(Icons.meeting_room, color: TColors.neonAccent),
            onPressed: () {
              // TODO: Start pair programming or video call
            },
            tooltip: "Join Pair Session",
          ),
        ],
      ),
    );
  }
}
