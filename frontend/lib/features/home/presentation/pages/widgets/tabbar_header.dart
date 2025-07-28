import 'package:flutter/material.dart';

class TabBarHeader extends StatelessWidget {
  const TabBarHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabBar(
      tabs: [
        Tab(icon: Icon(Icons.groups)),
        Tab(text: "Chats"),
        Tab(text: "Status"),
        Tab(text: "Calls"),
      ],
      indicatorColor: Colors.white,
      indicatorWeight: 3.0,
    );
  }
}
