import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("消息页")),
      body: const Center(
        child: Text("这里是消息页面（TODO）"),
      ),
    );
  }
}
