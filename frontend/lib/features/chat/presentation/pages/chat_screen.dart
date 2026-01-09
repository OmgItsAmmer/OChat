import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/core/utils/constants/colors.dart';
import 'package:frontend/core/utils/helpers/helper_functions.dart';

import '../controllers/chat_controller.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/develpor_action_bar.dart';
import 'widgets/message_bubble.dart';
import 'widgets/date_separator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // GetX controller for chat logic
  final ChatController controller = Get.put(ChatController());
  late final String conversationId;
  late final String userName;

  @override
  void initState() {
    super.initState();
    // Get arguments from navigation (should contain conversationId and userName)
    final args = Get.arguments as Map<String, dynamic>?;
    conversationId = args?['conversationId'] ?? '';
    userName = args?['userName'] ?? 'Chat';
    // Load messages for this conversation from server
    controller.loadMessages(conversationId);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : TColors.background,
      appBar: AppBar(
        backgroundColor: isDarkMode ? TColors.primaryDark : TColors.primary,
        title: Text(userName, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.videocam_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.call_outlined)),
          PopupMenuButton<String>(
            onSelected: (val) {},
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'View Profile', child: Text("View Profile")),
              const PopupMenuItem(value: 'Mute', child: Text("Mute")),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          const DeveloperActionBar(),
          // Message list from controller.currentMessages (reactive)
          Expanded(
            child: Obx(() {
              final messages = controller.currentMessages.reversed.toList();
              final List<Widget> widgets = [];

              // Add date separators and messages in correct order
              DateTime? lastDate;
              for (int i = 0; i < messages.length; i++) {
                final msg = messages[i];
                final messageDate = DateTime(
                  msg.timestamp.year,
                  msg.timestamp.month,
                  msg.timestamp.day,
                );

                // Add date separator if date changed (before the message)
                if (lastDate == null || messageDate != lastDate) {
                  widgets.add(DateSeparator(date: messageDate));
                  lastDate = messageDate;
                }

                // Add message bubble
                final currentUserId = controller.getCurrentUserId();
                widgets.add(MessageBubble(
                  message: msg,
                  isSender: msg.senderId == currentUserId,
                ));
              }

              return ListView.builder(
                reverse: false,
                padding: const EdgeInsets.only(top: 10),
                itemCount: widgets.length,
                itemBuilder: (context, index) => widgets[index],
              );
            }),
          ),
          // Chat input bar: sends message to controller, which calls server
          ChatInputBar(
            controller: controller.messageController,
            onSend: (text) async {
              await controller.sendMessage(
                conversationId: conversationId,
                text: text,
              );
              controller.messageController.clear();
            },
          ),
        ],
      ),
    );
  }
}
