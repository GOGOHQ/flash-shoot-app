import 'package:flutter/material.dart';
import '../config/app_routes.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});
  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _onLogin() {
    // TODO: 接入真实鉴权服务
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("登录")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 1),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "手机号 / 邮箱",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "密码",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _onLogin,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.white),
                foregroundColor: MaterialStateProperty.all(Colors.black),
                padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
              child: const Text("登录"),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text("第三方登录"),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.wechat, color: Colors.green, size: 40),
                  onPressed: () {
                    // TODO: 微信登录
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.apple, color: Colors.black, size: 40),
                  onPressed: () {
                    // TODO: Apple ID 登录
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 40),
                  onPressed: () {
                    // TODO: Google 登录
                  },
                ),
              ],
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
