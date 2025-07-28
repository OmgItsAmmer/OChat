import 'package:flutter/material.dart';
import 'package:frontend/core/utils/constants/colors.dart';

import '../../../../core/utils/helpers/helper_functions.dart';
import 'widgets/chat_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    return DefaultTabController(
      length: 3, // Chats, Status, Calls
      initialIndex: 0,
      child: Scaffold(  
        backgroundColor: isDarkMode ? TColors.black : TColors.background,
        appBar: AppBar(
          backgroundColor: isDarkMode ? TColors.black : TColors.primaryLight,
          title: Text(
            "OChat",
            style:
                TextStyle(color: isDarkMode ? TColors.primary : TColors.white),
          ),
          actions: [
            IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.camera_alt_outlined,
                  color: isDarkMode ? TColors.primary : TColors.white,
                )),
            IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.search,
                  color: isDarkMode ? TColors.primary : TColors.white,
                )),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: isDarkMode ? TColors.primary : TColors.white,
              ),
              color: isDarkMode ? TColors.black : TColors.primaryLight,
              itemBuilder: (BuildContext context) {
                return ['New group', 'Settings', 'Logout'].map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(
                      choice,
                      style: TextStyle(
                          color: isDarkMode ? TColors.primary : TColors.white),
                    ),
                  );
                }).toList();
              },
            ),
          ],
          bottom: TabBar(
            unselectedLabelColor: isDarkMode ? TColors.white : TColors.black,
            labelColor: isDarkMode ? TColors.primary : TColors.white,
            indicatorColor: isDarkMode ? TColors.primary : TColors.white,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "Chats"),
              Tab(text: "Status"),
              Tab(text: "Calls"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ChatsTab(), // ✅ Full Detail
            // DummyTab(tabName: "Status"),
            // DummyTab(tabName: "Calls"),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Could be: navigate to new chat screen
          },
          backgroundColor: isDarkMode ? TColors.primary : TColors.primaryLight,
          child: Icon(
            Icons.message,
            color: isDarkMode ? TColors.white : TColors.white,
          ),
        ),
      ),
    );
  }
}
