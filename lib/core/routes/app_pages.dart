import 'package:get/get.dart';

import '../../features/auth/view/screen/login_screen.dart';
import '../../features/home/view/screen/home_screen.dart';
import '../../features/home/view/screen/trip_screen.dart';
import '../../features/home/view/widgets/drawer_widget.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: AppRoutes.trip,
      page: () => const TripScreen(),
    ),
    GetPage(
      name: AppRoutes.drawer,
      page: () => const DrawerWidget(),
      transition: Transition.leftToRightWithFade,
    ),
  ];
}
