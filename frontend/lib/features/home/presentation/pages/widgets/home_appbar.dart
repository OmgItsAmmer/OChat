import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  HomeAppBar({Key? key})
      : preferredSize = const Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("WhatsApp"),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.camera_alt_outlined)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        PopupMenuButton<String>(
          itemBuilder: (BuildContext context) {
            return ['New group', 'Settings', 'Logout'].map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
        ),
      ],
    );
  }
}
