import 'package:flutter/material.dart';
import 'package:frontend/core/routes/o_routes.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/constants/colors.dart';
import '../../../../../core/utils/helpers/helper_functions.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final chats = [
      {
        "name": "Ali",
        "message": "Bro kal ka kya scene?",
        "time": "10:24 AM",
        "unread": 2,
      },
      {
        "name": "Zara",
        "message": "Thanks for your help!",
        "time": "9:45 AM",
        "unread": 0,
      },
      {
        "name": "NUST Class Group",
        "message": "Assignment ki deadline extend ho gayi!",
        "time": "Yesterday",
        "unread": 10,
      },
      {
        "name": "Mom",
        "message": "Beta khana khaya?",
        "time": "Yesterday",
        "unread": 0,
      },
    ];
    final isDarkMode = THelperFunctions.isDarkMode(context);
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ListTile(
          onTap: () {
            Get.toNamed(ORoutes.chatScreen, arguments: {
              "conversationId": chat["id"],
              "userName": chat["name"],
            });
          },
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: TColors.primary,
            child: Icon(Icons.person, color: isDarkMode ? TColors.white.withValues(alpha: 0.7) : TColors.primary),
          ),
          title: Text(
            chat["name"] as String,
            style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? TColors.white.withValues(alpha: 0.7) : TColors.primary),
          ),
          subtitle: Text(chat["message"] as String, style: TextStyle(color: isDarkMode ? TColors.white.withValues(alpha: 0.7) : TColors.primary),),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                chat["time"] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: (chat["unread"] as int) > 0
                      ? isDarkMode
                          ? TColors.white.withValues(alpha: 0.7)
                          : TColors.primary
                      : TColors.primary,
                ),
              ),
              if ((chat["unread"] as int) > 0)
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: TColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    (chat["unread"] as int).toString(),
                    style: TextStyle(
                        color:
                            isDarkMode ? TColors.white : TColors.primaryLight,
                        fontSize: 12),
                  ),
                ),
            ],
          ),
          
        );
      },
    );
  }
}
