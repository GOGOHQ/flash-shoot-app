import 'package:flutter/material.dart';

class UserInfoScreen extends StatelessWidget {
  const UserInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("用户主页")),
      body: const Center(
        child: Text("这里是用户主页页面（TODO）"),
      ),
    );
  }
}
