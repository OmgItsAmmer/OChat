import 'package:flutter/material.dart';

class CallTile extends StatelessWidget {
  final String name;
  final bool isMissed;
  final bool isIncoming;

  const CallTile({super.key, required this.name, required this.isMissed, required this.isIncoming});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.teal,
        child: Icon(Icons.phone),
      ),
      title: Text(name),
      subtitle: Row(
        children: [
          Icon(
            isIncoming ? Icons.call_received : Icons.call_made,
            color: isMissed ? Colors.red : Colors.green,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(isMissed ? "Missed" : "Answered"),
        ],
      ),
      trailing: const Icon(Icons.call, color: Colors.teal),
    );
  }
}
