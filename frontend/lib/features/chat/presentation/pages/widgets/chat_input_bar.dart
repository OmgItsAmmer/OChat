import 'package:flutter/material.dart';
import 'package:frontend/core/utils/constants/colors.dart';
import 'package:frontend/core/utils/helpers/helper_functions.dart';

class ChatInputBar extends StatelessWidget {
  /// Controller for the text input field
  final TextEditingController controller;

  /// Callback when the user presses send. Receives the message text.
  final Future<void> Function(String text) onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: isDarkMode ? Colors.black : TColors.background,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: TextStyle(
                    color: isDarkMode ? Colors.white54 : Colors.grey[600]),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[900] : Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (text) async {
                if (text.trim().isNotEmpty) {
                  await onSend(text.trim());
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor:
                isDarkMode ? TColors.primaryLight : TColors.primary,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  await onSend(text);
                }
              },
            ),
          )
        ],
      ),
    );
  }
}
