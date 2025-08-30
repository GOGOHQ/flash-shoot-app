import 'package:flutter/material.dart';
import '../screens/user_login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/map_screen.dart';
import '../screens/camera_screen.dart';
import '../screens/gallery_screen.dart';
import '../screens/community_screen.dart';
import '../screens/user_info_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/search_screen.dart';
import '../screens/search_result_screen.dart';
import '../screens/pose_library_screen.dart';



class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String map = '/map';
  static const String camera = '/camera';
  static const String gallery = '/gallery';
  static const String community = '/community';
  static const String info = '/info';
  static const String message = '/message';
  static const String search = '/search';
  static const String result = '/result';
  static const String poseLibrary = '/poseLibrary';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const UserLoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case map:
        return MaterialPageRoute(builder: (_) => const MapScreen());
      case camera:
        return MaterialPageRoute(builder: (_) => const CameraScreen());
      case gallery:
        return MaterialPageRoute(builder: (_) => const GalleryScreen());
      case community:
        return MaterialPageRoute(builder: (_) => const CommunityScreen());
      case info:
        return MaterialPageRoute(builder: (_) => const UserInfoScreen());
      case message:
        return MaterialPageRoute(builder: (_) => const MessagesScreen());
      case search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case result:
        return MaterialPageRoute(builder: (_) => const SearchResultScreen());
      case poseLibrary:
        return MaterialPageRoute(builder: (_) => const PoseLibraryScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
