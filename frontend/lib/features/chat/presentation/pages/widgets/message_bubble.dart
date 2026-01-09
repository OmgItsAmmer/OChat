import 'package:flutter/material.dart';
import 'package:frontend/core/utils/constants/colors.dart';
import 'package:frontend/core/utils/helpers/helper_functions.dart';
import 'package:frontend/features/chat/data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isSender;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSender,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    final backgroundColor = isSender
        ? (isDarkMode ? TColors.primaryDark : TColors.primary)
        : (isDarkMode ? Colors.grey[800] : Colors.grey[200]);

    final textColor = isSender
        ? Colors.white
        : (isDarkMode ? Colors.white70 : Colors.black87);

    final timestampColor = isSender
        ? Colors.white.withOpacity(0.7)
        : (isDarkMode ? Colors.white54 : Colors.black54);

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isSender ? 16 : 0),
            bottomRight: Radius.circular(isSender ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              _getFormattedTimestamp(message.timestamp),
              style: TextStyle(
                color: timestampColor,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get formatted timestamp for display
  String _getFormattedTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    String datePrefix;
    if (messageDate == today) {
      datePrefix = 'Today';
    } else if (messageDate == yesterday) {
      datePrefix = 'Yesterday';
    } else {
      datePrefix =
          '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
    }

    final timeString =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    return '$datePrefix $timeString';
  }
}
