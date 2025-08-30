import 'package:flutter/material.dart';
import 'config/app_routes.dart';
import 'utils/app_permissions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保插件初始化

  // 先检查权限
  bool granted = await AppPermissions.requestCameraAndStorage();

  runApp(FlashShootApp(hasPermission: granted));
}

class FlashShootApp extends StatelessWidget {
  final bool hasPermission;
  const FlashShootApp({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '魔拍',
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      home: hasPermission 
          ? const PermissionGrantedScreen()
          : const PermissionDeniedScreen(),
      // initialRoute: null, // 因为我们在上面用 home 判断了
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}

/// 权限通过后跳转到正常登录页（或者你原来 initialRoute 的页面）
class PermissionGrantedScreen extends StatefulWidget {
  const PermissionGrantedScreen({super.key});

  @override
  State<PermissionGrantedScreen> createState() => _PermissionGrantedScreenState();
}
class _PermissionGrantedScreenState extends State<PermissionGrantedScreen> {
  @override
  void initState() {
    super.initState();
    // 在 initState 里跳转一次，不会死循环
    Future.microtask(() {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}



/// 权限没通过的页面
class PermissionDeniedScreen extends StatefulWidget {
  const PermissionDeniedScreen({super.key});

  @override
  State<PermissionDeniedScreen> createState() => _PermissionDeniedScreenState();
}

class _PermissionDeniedScreenState extends State<PermissionDeniedScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // 当 App 从后台切回前台时
    if (state == AppLifecycleState.resumed) {
      bool granted = await AppPermissions.requestCameraAndStorage();
      if (granted && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text("需要相机和相册权限，点击前往设置"),
          onPressed: () async {
            await AppPermissions.openAppSettingsPage();
          },
        ),
      ),
    );
  }
}

